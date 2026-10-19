#!/usr/bin/env bash
# tools/verify-output.sh
# LLM-as-judge verifier for cass test cases.
# Reads results.json + expected.json, calls claude -p, returns one of:
#   ✓ good | ⚠ comment | ✗ fail
#
# Usage:
#   bash tools/verify-output.sh \
#     --results  /tmp/cass-test-xxx/all-pass/results.json \
#     --expected tests/doctor/all-pass/3-answers-and-expected/expected.json \
#     --test-name "doctor — all-pass"
#
# Exit 0 = good or comment, exit 1 = fail, exit 2 = error.

set -euo pipefail

PLUGIN_JSON="$(git rev-parse --show-toplevel)/.claude-plugin/plugin.json"
if ! grep -q '"name": "cass"' "$PLUGIN_JSON" 2>/dev/null; then
  echo "cass test suite only runs inside the cass plugin repo" && exit 2
fi
PLUGIN_ROOT="$(git rev-parse --show-toplevel)"

RESULTS_FILE=""
EXPECTED_FILE=""
TEST_NAME=""

while [[ $# -gt 0 ]]; do
  case "$1" in
    --results)  RESULTS_FILE="$2";  shift 2 ;;
    --expected) EXPECTED_FILE="$2"; shift 2 ;;
    --test-name) TEST_NAME="$2";    shift 2 ;;
    *) echo "Unknown arg: $1" >&2; exit 2 ;;
  esac
done

if [ -z "$RESULTS_FILE" ] || [ -z "$EXPECTED_FILE" ]; then
  echo "Usage: $0 --results <file> --expected <file> [--test-name <name>]" >&2
  exit 2
fi

# Extract fields with python for robustness
VERIFIER_PROMPT=$(python3 -c "
import json, sys
e = json.load(open('$EXPECTED_FILE'))
print(e.get('verifier_prompt', ''))
" 2>/dev/null)

if [ -z "$VERIFIER_PROMPT" ]; then
  echo "(no verifier_prompt in expected.json — skipping LLM verification)"
  exit 0
fi

COMMAND=$(python3 -c "
import json, sys
r = json.load(open('$RESULTS_FILE'))
# runner stores the test name; derive command from context
print(r.get('test', ''))
" 2>/dev/null)

TEXT_RESPONSE=$(python3 -c "
import json, sys
r = json.load(open('$RESULTS_FILE'))
print(r.get('text_response', ''))
" 2>/dev/null)

JUDGE_PROMPT="You are a test verifier for the cass Claude Code plugin test suite.

Test name: ${TEST_NAME:-$COMMAND}

Verifier expectation (from expected.json):
${VERIFIER_PROMPT}

Captured command output:
---
${TEXT_RESPONSE}
---

Based on the verifier expectation and the captured output, return exactly one of these verdicts — nothing else:

✓ good — outcome fully matches the expectation, nothing unexpected
⚠ comment: <one sentence> — technically passed but something is worth noting
✗ fail: <one sentence> — expectation clearly not met

Respond with only the verdict line. No preamble, no explanation beyond the inline note after ⚠ or ✗."

VERDICT=$(claude -p "$JUDGE_PROMPT" \
  --model claude-haiku-4-5-20251001 \
  --output-format text \
  2>/dev/null | head -3 | tr -d '\r')

echo "$VERDICT"

# Exit based on verdict
if echo "$VERDICT" | grep -q '^✗'; then
  exit 1
fi
exit 0
