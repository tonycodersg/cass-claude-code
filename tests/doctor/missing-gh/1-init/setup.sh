#!/usr/bin/env bash
# Sets up a mock repo where the `gh` CLI is not available.
# Shadows gh with a stub that exits non-zero so doctor reports a failure.

set -euo pipefail

# Init git repo with identity
git init
git config user.name "Test User"
git config user.email "test@example.com"

# Create a local bin directory and prepend it to PATH so our stub wins
mkdir -p ./bin

# Stub that makes `gh` appear absent
cat > ./bin/gh <<'EOF'
#!/usr/bin/env bash
exit 127
EOF
chmod +x ./bin/gh

# Write env overrides to .cass-test-env so the runner can export them
# before spawning Claude (PATH export from this subshell doesn't carry over)
echo "PATH=$(pwd)/bin:$PATH" > .cass-test-env

# Create .cass files so only the gh check fails
mkdir -p .cass
echo "# PR Template" > .cass/pr-template.md
echo "# Commit Template" > .cass/commit-template.md

mkdir -p .claude
cat > .claude/settings.local.json <<'EOF'
{
  "cass": {}
}
EOF

echo "Setup complete. gh is stubbed to exit 127 (not found)."
