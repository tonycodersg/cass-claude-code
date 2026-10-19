#!/usr/bin/env bash
# Sets up a clean git repo for the cass:init happy-path test.

set -euo pipefail

git init
git config user.name "Test User"
git config user.email "test@example.com"

# Verify prerequisites expected by cass:init
for cmd in gh uvx python3; do
  if ! command -v "$cmd" &>/dev/null; then
    echo "WARNING: $cmd not found — happy-path init requires all prerequisites" >&2
  fi
done

echo "Setup complete."
