#!/usr/bin/env bash
# Sets up a repo with main as the base branch and a feature branch with 2 new files.
# base-diff.sh must produce a diff containing only the feature branch changes.

set -euo pipefail

git init
git config user.name "Test User"
git config user.email "test@example.com"

# Simulate a remote origin/main
git remote add origin https://github.com/test-org/test-repo.git

mkdir -p src
echo "# README" > README.md
echo "export const a = 1;" > src/a.ts
git add .
git commit -m "initial: base commit"

# Fake origin/main pointing at the initial commit
git update-ref refs/remotes/origin/main HEAD

# Feature branch — two new files
git checkout -b feat/new-feature
echo "export const b = 2;" > src/b.ts
echo "export const c = 3;" > src/c.ts
git add .
git commit -m "feat: add b and c modules"

echo "Setup complete. feat/new-feature is 1 commit ahead of origin/main."
