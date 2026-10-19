#!/usr/bin/env bash
# Clean diff with no bugs — review should find no P1 issues.

set -euo pipefail

git init
git config user.name "Test User"
git config user.email "test@example.com"

# Initial commit — baseline math module
mkdir -p src
cat > src/math.ts <<'EOF'
export function add(a: number, b: number): number {
  return a + b;
}
EOF

git add .
git commit -m "initial: add math module"

# Feature branch adds a clean subtract function — no bugs
git checkout -b feat/add-subtract

cat > src/math.ts <<'EOF'
export function add(a: number, b: number): number {
  return a + b;
}

export function subtract(a: number, b: number): number {
  return a - b;
}
EOF

git add .
git commit -m "feat: add subtract function"

echo "Setup complete. Branch: feat/add-subtract with clean diff against master."
