#!/usr/bin/env bash
# Sets up a fully cass-initialized repo for the eject happy-path test.

set -euo pipefail

git init
git config user.name "Test User"
git config user.email "test@example.com"

# Simulate a cass:init-ed repo
mkdir -p .cass
echo "# PR Template" > .cass/pr-template.md
echo "# Commit Template" > .cass/commit-template.md

# Commit template wired up
echo "commit template content" > cass-.gitmessage
git config commit.template cass-.gitmessage

# Settings with cass key
mkdir -p .claude
cat > .claude/settings.local.json <<'EOF'
{
  "cass": {
    "projects": {
      "test-repo": {
        "mainBranch": "main",
        "mainRepoPath": "/tmp/test-repo",
        "worktreePath": "/tmp/test-repo-agent-works"
      }
    }
  }
}
EOF

# .gitignore with cass entries
cat > .gitignore <<'EOF'
node_modules/
# cass — personal config, do not commit
.cass/settings.local.json
EOF

echo "Setup complete."
