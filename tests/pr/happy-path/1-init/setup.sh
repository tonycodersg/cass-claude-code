#!/usr/bin/env bash
# Sets up a feature branch repo with a stubbed gh for the cass:pr happy-path test.

set -euo pipefail

# Stub gh to simulate a successful PR creation
mkdir -p ./bin
cat > ./bin/gh <<'GHEOF'
#!/usr/bin/env bash
# Stub: print a fake PR URL for any `gh pr create` call
if [[ "$1" == "pr" && "$2" == "create" ]]; then
  echo "https://github.com/test-org/test-repo/pull/42"
  exit 0
fi
# Pass through other gh subcommands with a stub empty response
echo ""
exit 0
GHEOF
chmod +x ./bin/gh

# Export stub path via .cass-test-env
echo "PATH=$(pwd)/bin:$PATH" > .cass-test-env

# Init a git repo on a feature branch
git init
git config user.name "Test User"
git config user.email "test@example.com"

# Set up a fake remote so git push doesn't fail
git remote add origin https://github.com/test-org/test-repo.git

# Commit on main first
echo "# README" > README.md
git add README.md
git commit -m "chore: initial commit"

# Create and checkout feature branch
git checkout -b feat/user-auth

# Add a change on the feature branch
cat > src/auth.ts <<'EOF'
export function login(user: string) {
  return { token: "stub", user };
}
EOF
git add src/auth.ts
git commit -m "feat(auth): add login stub"

# cass templates
mkdir -p .cass
echo "# PR Template" > .cass/pr-template.md

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

echo "Setup complete."
