#!/usr/bin/env bash
# Sets up a mock repo with all cass prerequisites present.
# Run from an empty temp directory before executing the test.

set -euo pipefail

# Init git repo with identity
git init
git config user.name "Test User"
git config user.email "test@example.com"

# Create .cass directory with required files
mkdir -p .cass
echo "# PR Template" > .cass/pr-template.md
echo "# Commit Template" > .cass/commit-template.md

# Create minimal settings.local.json (no projects configured — info, not fail)
mkdir -p .claude
cat > .claude/settings.local.json <<'EOF'
{
  "cass": {}
}
EOF

# Verify prerequisites are available on PATH
for cmd in gh uvx python3; do
  if ! command -v "$cmd" &>/dev/null; then
    echo "WARNING: $cmd not found on PATH — all-pass scenario requires it" >&2
  fi
done

echo "Setup complete."
