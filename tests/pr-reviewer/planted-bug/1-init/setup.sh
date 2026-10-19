#!/usr/bin/env bash
# Plants a null-dereference bug in src/auth.ts for the pr-reviewer to catch.

set -euo pipefail

git init
git config user.name "Test User"
git config user.email "test@example.com"

# Initial commit — clean baseline
mkdir -p src
cat > src/auth.ts <<'EOF'
export interface User {
  id: string;
  email: string;
  role: string;
}

export async function getUser(userId: string): Promise<User | null> {
  const response = await fetch(`/api/users/${userId}`);
  if (!response.ok) return null;
  return response.json();
}
EOF

git add .
git commit -m "initial: add auth module"

# Feature branch with the planted null-dereference bug
git checkout -b feat/user-permissions

cat > src/auth.ts <<'EOF'
export interface User {
  id: string;
  email: string;
  role: string;
}

export async function getUser(userId: string): Promise<User | null> {
  const response = await fetch(`/api/users/${userId}`);
  if (!response.ok) return null;
  return response.json();
}

export function getUserDisplayName(userId: string): string {
  // BUG: getUser is async and returns a Promise — calling .email directly
  // on the unresolved Promise will always be undefined, not a null check.
  const user = getUser(userId);
  return user.email.toUpperCase();  // line 18: null dereference — user is a Promise, not User
}
EOF

git add .
git commit -m "feat: add getUserDisplayName helper"

echo "Setup complete. Branch: feat/user-permissions with planted null-deref bug on line 18."
