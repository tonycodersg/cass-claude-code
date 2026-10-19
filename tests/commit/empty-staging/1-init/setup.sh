#!/usr/bin/env bash
# Sets up a clean git repo with no changes for the cass:commit empty-staging test.

set -euo pipefail

git init
git config user.name "Test User"
git config user.email "test@example.com"

mkdir -p .cass
echo "# Commit Template" > .cass/commit-template.md

# Commit everything so working tree is completely clean
echo "# README" > README.md
git add README.md .cass/commit-template.md
git commit -m "chore: initial commit"

# No additional changes — working tree should be clean

echo "Setup complete."
