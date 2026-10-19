#!/usr/bin/env bash
# Sets up a repo with one simulated worktree folder for the clean-wt remove-one test.

set -euo pipefail

git init
git config user.name "Test User"
git config user.email "test@example.com"

# Create a simulated worktree subfolder (not a real git worktree)
mkdir -p agent-works/feat-user-auth

# Settings pointing worktreePath to the local agent-works folder
mkdir -p .claude
cat > .claude/settings.local.json <<EOF
{
  "cass": {
    "projects": {
      "test-repo": {
        "mainBranch": "main",
        "mainRepoPath": "$(pwd)",
        "worktreePath": "$(pwd)/agent-works"
      }
    }
  }
}
EOF

echo "Setup complete."
