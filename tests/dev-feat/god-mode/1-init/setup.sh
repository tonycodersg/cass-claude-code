#!/usr/bin/env bash
set -euo pipefail

git init
git config user.name "Test User"
git config user.email "test@example.com"

# Create a minimal plan doc for dev-feat to implement
mkdir -p docs
cat > docs/add-greeting_2026-10-19.md <<'PLANEOF'
# Add greeting module

## Goal
Add a src/greeting.ts file that exports a hello(name: string): string function returning "Hello, {name}!".

## Scope
In scope:
- Create src/greeting.ts with a hello() function

Out of scope:
- Tests
- Other files

## Functional Requirements
- src/greeting.ts must exist
- hello(name) must return "Hello, {name}!"

## Success Criteria
- [ ] src/greeting.ts exists
- [ ] hello() exported and working
PLANEOF

# Initial commit
git add . && git commit -m "initial: add plan doc"

# Create a remote-like setup (bare repo) so git push works in worktree
git checkout -b master 2>/dev/null || true

# Configure cass project settings pointing to this temp repo
ACTUAL_PATH="$(pwd)"
WORKTREE_PATH="${ACTUAL_PATH}/../test-app-agent-works"
mkdir -p "$WORKTREE_PATH"

mkdir -p .claude
cat > .claude/settings.local.json <<SETTEOF
{
  "cass": {
    "projects": {
      "test-app": {
        "mainRepoPath": "${ACTUAL_PATH}",
        "mainBranch": "master",
        "worktreePath": "${WORKTREE_PATH}"
      }
    }
  }
}
SETTEOF

git add .claude/settings.local.json
git commit -m "add cass settings"
