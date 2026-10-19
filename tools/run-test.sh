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

# --- build answer injection suffix ---
ANSWERS_FILE="$TEST_FOLDER/3-answers-and-expected/answers.json"
ANSWER_SUFFIX=""
if [ -f "$ANSWERS_FILE" ]; then
  ANSWERS_CONTENT=$(python3 -c "
import json, sys
d = json.load(open('$ANSWERS_FILE'))
if d:
    print(json.dumps(d))
" 2>/dev/null)
  if [ -n "$ANSWERS_CONTENT" ]; then
    ANSWER_SUFFIX=$(printf '\n\nWhen asked any question via AskUserQuestion, use these answers: %s\nMatch by the question header. Select the option whose label contains the answer value.' "$ANSWERS_CONTENT")
  fi
fi

# Build the plugin fallback instruction so Claude runs the command even
# when slash-command dispatch doesn't fire in -p / headless mode.
COMMAND_NAME="${COMMAND#/}"          # strip leading /  → e.g. "cass:doctor"
COMMAND_FILE="$PLUGIN_ROOT/commands/${COMMAND_NAME#*:}.md"   # commands/doctor.md
FALLBACK=""
if [ -f "$COMMAND_FILE" ]; then
  FALLBACK=$(printf '\n\nThe cass plugin is loaded from %s. The command is defined in %s. If the slash command does not dispatch automatically, read that file and execute it directly using the Bash tool.' \
    "$PLUGIN_ROOT" "$COMMAND_FILE")
fi

FULL_PROMPT="${COMMAND}${FALLBACK}${ANSWER_SUFFIX}"

# --- create isolated temp dir ---
UUID=$(python3 -c "import uuid; print(uuid.uuid4().hex[:8])")
WORK_DIR="/tmp/cass-test-${UUID}/${TEST_NAME}"
mkdir -p "$WORK_DIR"

STEPS_FILE="$WORK_DIR/steps.jsonl"
step() {
  local n="$1" action="$2" status="$3"
  printf '{"step":%d,"action":"%s","status":"%s"}\n' "$n" "$action" "$status" >> "$STEPS_FILE"
}

echo "Running test: $TEST_NAME"
echo "  work dir:  $WORK_DIR"
echo "  command:   $COMMAND"
[ -n "$ANSWER_SUFFIX" ] && echo "  answers:   injected from answers.json"

# --- run setup ---
echo "  [1/3] setup..."
(cd "$WORK_DIR" && bash "$INIT_SCRIPT") 2>&1 | sed 's/^/    /'
step 1 "setup complete" "pass"

# --- load env overrides written by setup.sh (.cass-test-env) ---
ENV_FILE="$WORK_DIR/.cass-test-env"
if [ -f "$ENV_FILE" ]; then
  while IFS='=' read -r key val; do
    [[ -z "$key" || "$key" == \#* ]] && continue
    export "$key=$val"
    echo "    env: $key set"
  done < "$ENV_FILE"
fi

# --- run claude ---
echo "  [2/3] executing command..."
CLAUDE_OUTPUT_FILE="$WORK_DIR/.cass-test-output.json"
EXIT_CODE=0

(
  cd "$WORK_DIR"
  claude -p "$FULL_PROMPT" \
    --plugin-dir "$PLUGIN_ROOT" \
    --output-format json \
    2>&1
) > "$CLAUDE_OUTPUT_FILE" || EXIT_CODE=$?
step 2 "command executed" "$([ $EXIT_CODE -eq 0 ] && echo pass || echo fail)"

# --- write results.json ---
echo "  [3/3] writing results..."
RESULTS_FILE="$WORK_DIR/results.json"

python3 - <<PYEOF
import json, sys

output_raw = open("$CLAUDE_OUTPUT_FILE").read().strip()

# Strip leading non-JSON lines (e.g. the ⚠ connector warning claude emits to stdout)
lines = output_raw.splitlines()
json_lines = []
skipped = []
for line in lines:
    stripped = line.strip()
    if stripped.startswith('{') or json_lines:
        json_lines.append(line)
    else:
        skipped.append(line)

json_raw = "\n".join(json_lines).strip()

text_response = ""
tool_calls = []
data = {}

if json_raw:
    # Try single JSON object first (claude --output-format json default)
    try:
        data = json.loads(json_raw)
        # "result" holds the final text in -p / print mode
        text_response = data.get("result", data.get("content", ""))
        tool_calls = data.get("tool_uses", [])
    except json.JSONDecodeError:
        # Fall back to NDJSON (streaming format)
        parsed = []
        text_parts = []
        for line in json_lines:
            if not line.strip():
                continue
            try:
                obj = json.loads(line)
                parsed.append(obj)
                t = obj.get("type", "")
                if t == "result":
                    # -p mode final result object
                    text_parts.append(obj.get("result", ""))
                elif t == "assistant":
                    for block in obj.get("message", {}).get("content", []):
                        if block.get("type") == "text":
                            text_parts.append(block["text"])
                        elif block.get("type") == "tool_use":
                            tool_calls.append(block)
            except Exception:
                pass
        text_response = "\n".join(p for p in text_parts if p)
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
  step 3 "mechanical assertions" "$([ $ASSERT_EXIT -eq 0 ] && echo pass || echo fail)"
else
  echo "  (no expected.json — skipping assertions)"
  step 3 "mechanical assertions" "skipped"
fi

# --- LLM verifier (qualitative judgment) ---
VERIFY_EXIT=0
if [ -f "$EXPECTED_FILE" ]; then
  echo ""
  VERDICT=$(bash "$PLUGIN_ROOT/tools/verify-output.sh" \
    --results  "$RESULTS_FILE" \
    --expected "$EXPECTED_FILE" \
    --test-name "$TEST_NAME" \
    2>/dev/null) || VERIFY_EXIT=$?
  if [ -n "$VERDICT" ]; then
    echo "  Verifier: $VERDICT"
  fi
  step 4 "llm verification" "$([ $VERIFY_EXIT -eq 0 ] && echo pass || echo fail)"
  # write verdict.json for suite aggregation
  python3 -c "
import json
verdict_line = '''${VERDICT}'''
if verdict_line.startswith('✗'):
    state = 'fail'
elif verdict_line.startswith('⚠'):
    state = 'comment'
else:
    state = 'good'
json.dump({'test': '${TEST_NAME}', 'state': state, 'verdict': verdict_line}, open('$WORK_DIR/verdict.json', 'w'))
" 2>/dev/null || true
fi

# --- final pass/fail ---
if [ $EXIT_CODE -ne 0 ] || [ $ASSERT_EXIT -ne 0 ] || [ $VERIFY_EXIT -ne 0 ]; then
  [ $EXIT_CODE -ne 0 ] && echo "FAIL  $TEST_NAME  (claude exited $EXIT_CODE)"
  echo "  Debug folder kept: $WORK_DIR"
  exit 1
else
  rm -rf "/tmp/cass-test-${UUID}"
fi
