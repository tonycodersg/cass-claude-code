#!/usr/bin/env bash
# tools/run-suite.sh [test-glob]
# Discovers all test cases under tests/ and runs them in parallel.
# Prints a final aggregated report.
#
# Usage:
#   bash tools/run-suite.sh                 # run everything
#   bash tools/run-suite.sh tests/doctor/   # run only doctor tests

set -euo pipefail

PLUGIN_JSON="$(git rev-parse --show-toplevel)/.claude-plugin/plugin.json"
if ! grep -q '"name": "cass"' "$PLUGIN_JSON" 2>/dev/null; then
  echo "cass test suite only runs inside the cass plugin repo" && exit 1
fi

PLUGIN_ROOT="$(git rev-parse --show-toplevel)"
SEARCH_ROOT="${1:-$PLUGIN_ROOT/tests}"
SEARCH_ROOT="$(cd "$SEARCH_ROOT" && pwd)"

C_RESET="\033[0m"
C_GREEN="\033[32m"
C_YELLOW="\033[33m"
C_RED="\033[31m"
C_BOLD="\033[1m"
C_DIM="\033[2m"
C_CYAN="\033[1;36m"

SEP="═══════════════════════════════════════════════════"

# --- discover test cases (folders that have a 2-test/run.md) ---
TEST_CASES=()
while IFS= read -r run_md; do
  TEST_CASES+=("$(dirname "$(dirname "$run_md")")")
done < <(find "$SEARCH_ROOT" -path "*/2-test/run.md" | sort)

if [ ${#TEST_CASES[@]} -eq 0 ]; then
  echo "No test cases found under: $SEARCH_ROOT" >&2
  exit 1
fi

printf "\n${C_CYAN}${C_BOLD}cass test suite${C_RESET}  ${C_DIM}%d test(s) discovered${C_RESET}\n" "${#TEST_CASES[@]}"
printf "${C_DIM}%s${C_RESET}\n\n" "$SEP"

# --- run each test case in parallel ---
# Each job writes its work-dir path to a temp file so we can collect results
SUITE_TMPDIR=$(mktemp -d)
PIDS=()
JOB_FILES=()

for tc in "${TEST_CASES[@]}"; do
  JOB_FILE=$(mktemp "$SUITE_TMPDIR/job.XXXXXXXX")
  JOB_FILES+=("$JOB_FILE")

  (
    LABEL=$(python3 -c "
import os
tc = '$tc'
root = '$SEARCH_ROOT'
label = os.path.relpath(tc, root).replace('/', ' / ')
print(label)
")

    OUT_FILE=$(mktemp "$SUITE_TMPDIR/out.XXXXXXXX")
    EXIT=0
    bash "$PLUGIN_ROOT/tools/run-test.sh" "$tc" > "$OUT_FILE" 2>&1 || EXIT=$?

    # find the work dir from the output
    WORK_DIR=$(grep "work dir:" "$OUT_FILE" | awk '{print $NF}' | head -1)

    # determine verdict
    STATE="unknown"
    VERDICT_NOTE=""
    if [ -n "$WORK_DIR" ] && [ -f "$WORK_DIR/verdict.json" ]; then
      STATE=$(python3 -c "import json; d=json.load(open('$WORK_DIR/verdict.json')); print(d.get('state','unknown'))")
      VERDICT_NOTE=$(python3 -c "import json; d=json.load(open('$WORK_DIR/verdict.json')); v=d.get('verdict',''); print(v[v.find(':')+1:].strip() if ':' in v else '')" 2>/dev/null || true)
    elif [ $EXIT -eq 0 ]; then
      STATE="good"
    else
      STATE="fail"
    fi

    printf '{"label":"%s","state":"%s","note":"%s","work_dir":"%s","exit":%d}\n' \
      "$LABEL" "$STATE" "$VERDICT_NOTE" "${WORK_DIR:-}" "$EXIT" > "$JOB_FILE"
  ) &
  PIDS+=($!)
done

# wait for all jobs
for pid in "${PIDS[@]}"; do
  wait "$pid" || true
done

# --- aggregate results ---
TOTAL=0
GOOD=0
COMMENT=0
FAIL=0
FAIL_DIRS=()

printf "${C_DIM}%s${C_RESET}\n" "$SEP"
for jf in "${JOB_FILES[@]}"; do
  if [ ! -s "$jf" ]; then continue; fi
  LABEL=$(python3 -c "import json; d=json.load(open('$jf')); print(d['label'])")
  STATE=$(python3 -c "import json; d=json.load(open('$jf')); print(d['state'])")
  NOTE=$(python3  -c "import json; d=json.load(open('$jf')); print(d.get('note',''))")
  WORK_DIR=$(python3 -c "import json; d=json.load(open('$jf')); print(d.get('work_dir',''))")

  TOTAL=$((TOTAL+1))
  case "$STATE" in
    good)
      GOOD=$((GOOD+1))
      printf "  ${C_GREEN}✓ good${C_RESET}    %-40s\n" "$LABEL"
      ;;
    comment)
      COMMENT=$((COMMENT+1))
      printf "  ${C_YELLOW}⚠ comment${C_RESET} %-40s  ${C_DIM}%s${C_RESET}\n" "$LABEL" "$NOTE"
      ;;
    fail|*)
      FAIL=$((FAIL+1))
      [ -n "$WORK_DIR" ] && FAIL_DIRS+=("$WORK_DIR")
      printf "  ${C_RED}✗ fail${C_RESET}    %-40s  ${C_DIM}%s${C_RESET}\n" "$LABEL" "$NOTE"
      ;;
  esac
done

printf "${C_DIM}%s${C_RESET}\n\n" "$SEP"
printf "  ${C_GREEN}%d passed${C_RESET}  ·  ${C_YELLOW}%d comment${C_RESET}  ·  ${C_RED}%d failed${C_RESET}\n\n" \
  "$GOOD" "$COMMENT" "$FAIL"

if [ ${#FAIL_DIRS[@]} -gt 0 ]; then
  printf "${C_DIM}Failed test folders kept for debugging:${C_RESET}\n"
  for d in "${FAIL_DIRS[@]}"; do
    printf "  %s\n" "$d"
  done
  printf "\n"
fi

rm -rf "$SUITE_TMPDIR"

[ $FAIL -gt 0 ] && exit 1 || exit 0
