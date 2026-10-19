#!/usr/bin/env bash
# Sets up a git repo with unstaged changes for the cass:commit happy-path test.

set -euo pipefail

git init
git config user.name "Test User"
git config user.email "test@example.com"

# Commit-template so the command can find it
mkdir -p .cass
cat > .cass/commit-template.md <<'EOF'
# Commit message format
<type>(<scope>): <short summary>

<body — optional>

Co-authored-by: Claude <noreply@anthropic.com>
EOF

# Create a base commit so git is not empty
echo "# README" > README.md
git add README.md
git commit -m "chore: initial commit"

# Add a new file with unstaged changes so the command has something to stage and commit
cat > src/hello.js <<'EOF'
function hello(name) {
  return `Hello, ${name}!`;
}
module.exports = hello;
EOF

echo "Setup complete."
