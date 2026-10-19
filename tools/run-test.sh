#!/usr/bin/env bash
# tools/run-test.sh <test-folder>
# Drives a single cass test case end to end.
# Usage: bash tools/run-test.sh tests/doctor/all-pass

set -euo pipefail

# --- plugin-repo-only guard ---
PLUGIN_JSON="$(git rev-parse --show-toplevel)/.claude-plugin/plugin.json"
if ! grep -q '"name": "cass"' "$PLUGIN_JSON" 2>/dev/null; then
  echo "cass test suite only runs inside the cass plugin repo" && exit 1
fi

PLUGIN_ROOT="$(git rev-parse --show-toplevel)"

# --- args ---
TEST_FOLDER="${1:-}"
if [ -z "$TEST_FOLDER" ]; then
  echo "Usage: $0 <test-folder>" >&2
  exit 1
fi

if [ ! -d "$TEST_FOLDER" ]; then
  echo "Error: test folder not found: $TEST_FOLDER" >&2
  exit 1
fi

# resolve to absolute path so subshells work regardless of cwd
TEST_FOLDER="$(cd "$TEST_FOLDER" && pwd)"
TEST_NAME="$(basename "$TEST_FOLDER")"

# --- locate required files ---
INIT_SCRIPT="$TEST_FOLDER/1-init/setup.sh"
RUN_FILE="$TEST_FOLDER/2-test/run.md"
EXPECTED_FILE="$TEST_FOLDER/3-answers-and-expected/expected.json"

for f in "$INIT_SCRIPT" "$RUN_FILE"; do
  if [ ! -f "$f" ]; then
    echo "Error: required file not found: $f" >&2
    exit 1
  fi
done

# --- read command from run.md (first non-empty line) ---
COMMAND=$(grep -m1 -v '^\s*$' "$RUN_FILE")
if [ -z "$COMMAND" ]; then
  echo "Error: run.md is empty or has no command" >&2
  exit 1
fi

# --- create isolated temp dir ---
UUID=$(python3 -c "import uuid; print(uuid.uuid4().hex[:8])")
WORK_DIR="/tmp/cass-test-${UUID}/${TEST_NAME}"
mkdir -p "$WORK_DIR"

echo "Running test: $TEST_NAME"
echo "  work dir:  $WORK_DIR"
echo "  command:   $COMMAND"

# --- run setup ---
echo "  [1/3] setup..."
(cd "$WORK_DIR" && bash "$INIT_SCRIPT") 2>&1 | sed 's/^/    /'

# --- run claude ---
echo "  [2/3] executing command..."
CLAUDE_OUTPUT_FILE="$WORK_DIR/.cass-test-output.json"
EXIT_CODE=0

(
  cd "$WORK_DIR"
  claude -p "$COMMAND" \
    --plugin-dir "$PLUGIN_ROOT" \
    --output-format json \
    2>&1
) > "$CLAUDE_OUTPUT_FILE" || EXIT_CODE=$?

# --- write results.json ---
echo "  [3/3] writing results..."
RESULTS_FILE="$WORK_DIR/results.json"

python3 - <<PYEOF
import json, sys

output_raw = open("$CLAUDE_OUTPUT_FILE").read().strip()

# claude --output-format json may emit a single JSON object or NDJSON lines
try:
    data = json.loads(output_raw)
    text_response = data.get("result", data.get("content", ""))
    tool_calls = data.get("tool_uses", [])
except json.JSONDecodeError:
    # try NDJSON
    lines = [l for l in output_raw.splitlines() if l.strip()]
    parsed = []
    text_parts = []
    tool_calls = []
    for line in lines:
        try:
            obj = json.loads(line)
            parsed.append(obj)
            if obj.get("type") == "assistant":
                for block in obj.get("message", {}).get("content", []):
                    if block.get("type") == "text":
                        text_parts.append(block["text"])
                    elif block.get("type") == "tool_use":
                        tool_calls.append(block)
        except Exception:
            text_parts.append(line)
    text_response = "\n".join(text_parts)
    data = {"raw_lines": parsed}

results = {
    "test": "$TEST_NAME",
    "exit_code": $EXIT_CODE,
    "text_response": text_response,
    "tool_calls": tool_calls,
    "raw_output_file": "$CLAUDE_OUTPUT_FILE",
}

json.dump(results, open("$RESULTS_FILE", "w"), indent=2)
print(json.dumps({"results_file": "$RESULTS_FILE"}))
PYEOF

echo ""

# --- mechanical assertions ---
ASSERT_EXIT=0
if [ -f "$EXPECTED_FILE" ]; then
  python3 "$PLUGIN_ROOT/tools/assert-results.py" \
    --results  "$RESULTS_FILE" \
    --expected "$EXPECTED_FILE" \
    --work-dir "$WORK_DIR" \
    --test-name "$TEST_NAME" \
    || ASSERT_EXIT=$?
else
  echo "  (no expected.json — skipping assertions)"
fi

# --- final pass/fail ---
if [ $EXIT_CODE -ne 0 ] || [ $ASSERT_EXIT -ne 0 ]; then
  [ $EXIT_CODE -ne 0 ] && echo "FAIL  $TEST_NAME  (claude exited $EXIT_CODE)"
  echo "  Debug folder kept: $WORK_DIR"
  exit 1
else
  rm -rf "/tmp/cass-test-${UUID}"
fi
