#!/usr/bin/env bash
set -euo pipefail

git init
git config user.name "Test User"
git config user.email "test@example.com"

mkdir -p docs

# Initial commit so git commands work
touch .gitkeep
git add .gitkeep
git commit -m "initial"
