#!/usr/bin/env bash
# Inject active worktree context into every user prompt so Claude is always workspace-aware.

git rev-parse --git-dir > /dev/null 2>&1 || exit 0

branch=$(git branch --show-current 2>/dev/null)
repo=$(basename "$(git rev-parse --show-toplevel 2>/dev/null)")
worktree_count=$(git worktree list 2>/dev/null | wc -l | tr -d ' ')
dirty=$(git status --short 2>/dev/null | wc -l | tr -d ' ')
cass_settings=$(cat .claude/settings.local.json 2>/dev/null | python3 -c "
import json, sys
try:
  s = json.load(sys.stdin)
  projects = s.get('cass', {}).get('projects', {})
  if projects:
    names = list(projects.keys())
    print('projects: ' + ', '.join(names))
except:
  pass
" 2>/dev/null)

context="[cass context] repo: $repo | branch: $branch | worktrees: $worktree_count | dirty files: $dirty"
[ -n "$cass_settings" ] && context="$context | $cass_settings"

echo "{\"type\": \"text\", \"text\": \"$context\"}"
exit 0
