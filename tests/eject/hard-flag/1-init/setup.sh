#!/usr/bin/env bash
# Sets up a repo with .claude/commands/ overrides for the eject --hard test.

set -euo pipefail

git init
git config user.name "Test User"
git config user.email "test@example.com"

# Simulate a cass:init-ed repo
mkdir -p .cass
echo "# PR Template" > .cass/pr-template.md
echo "# Commit Template" > .cass/commit-template.md

echo "commit template content" > cass-.gitmessage
git config commit.template cass-.gitmessage

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

# Add .claude/commands/ overrides — the --hard flag should remove these
mkdir -p .claude/commands
echo "# Custom PR command override" > .claude/commands/cass:pr.md

cat > .gitignore <<'EOF'
node_modules/
# cass — personal config, do not commit
.cass/settings.local.json
EOF

echo "Setup complete."
