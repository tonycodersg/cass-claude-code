#!/usr/bin/env bash
# After Claude stops, check for uncommitted changes and nudge the user to commit.

# Only run inside a git repo
git rev-parse --git-dir > /dev/null 2>&1 || exit 0

dirty=$(git status --short 2>/dev/null)
[ -z "$dirty" ] && exit 0

staged=$(git diff --cached --name-only 2>/dev/null | wc -l | tr -d ' ')
unstaged=$(git diff --name-only 2>/dev/null | wc -l | tr -d ' ')
untracked=$(git ls-files --others --exclude-standard 2>/dev/null | wc -l | tr -d ' ')

msg="You have uncommitted changes ($staged staged, $unstaged unstaged, $untracked untracked). Run /cass:commit to stage and commit."

echo "{\"type\": \"text\", \"text\": \"$msg\"}"
exit 0
