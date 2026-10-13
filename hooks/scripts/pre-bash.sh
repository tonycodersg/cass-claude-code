#!/usr/bin/env bash
# Block destructive git commands before they run.
# Input: JSON from Claude Code on stdin with .tool_input.command

command=$(python3 -c "import json,sys; print(json.load(sys.stdin).get('tool_input',{}).get('command',''))" 2>/dev/null)

# Patterns that are destructive and should require explicit user intent
DESTRUCTIVE_PATTERNS=(
  "git push --force"
  "git push -f "
  "git push -f$"
  "git reset --hard"
  "git checkout -- \."
  "git checkout -- "
  "git restore \."
  "git restore "
  "git clean -f"
  "git branch -D"
  "rm -rf"
)

for pattern in "${DESTRUCTIVE_PATTERNS[@]}"; do
  if echo "$command" | grep -qE "$pattern"; then
    echo "{\"decision\": \"block\", \"reason\": \"Destructive command blocked by cass hook: '$command'. If intentional, run it directly in your terminal with '! $command'.\"}"
    exit 0
  fi
done

exit 0
