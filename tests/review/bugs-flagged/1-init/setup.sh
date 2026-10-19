#!/usr/bin/env bash
# Plants an array out-of-bounds bug for the pr-reviewer to catch.

set -euo pipefail

git init
git config user.name "Test User"
git config user.email "test@example.com"

# Initial commit — clean baseline
mkdir -p src
cat > src/utils.ts <<'EOF'
export function sum(numbers: number[]): number {
  return numbers.reduce((acc, n) => acc + n, 0);
}
EOF

git add .
git commit -m "initial: add utils module"

# Feature branch adds a function with an unchecked array access bug
git checkout -b feat/array-helpers

cat > src/utils.ts <<'EOF'
export function sum(numbers: number[]): number {
  return numbers.reduce((acc, n) => acc + n, 0);
}

export function getFirstItem(arr: string[]): string {
  // BUG: no empty-array guard — arr[0] is undefined when arr is empty,
  // but return type is string (not string | undefined), so callers won't
  // expect undefined and will crash on .length, .toUpperCase(), etc.
  return arr[0];
}
EOF

git add .
git commit -m "feat: add getFirstItem helper"

echo "Setup complete. Branch: feat/array-helpers with unchecked array access on line 12."
