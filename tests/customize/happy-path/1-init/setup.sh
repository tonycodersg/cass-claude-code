#!/usr/bin/env bash
# Minimal git repo — customize will scaffold .cass/ from scratch.

set -euo pipefail

git init
git config user.name "Test User"
git config user.email "test@example.com"

# One commit so git is valid
echo "# my-app" > README.md
git add .
git commit -m "initial commit"

echo "Setup complete. Empty repo ready for /cass:customize all."
