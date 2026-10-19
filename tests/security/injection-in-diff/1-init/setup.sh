#!/usr/bin/env bash
# Plants an SQL injection vulnerability in a feature branch for the security agent to catch.

set -euo pipefail

git init
git config user.name "Test User"
git config user.email "test@example.com"

# Initial clean baseline
mkdir -p src
cat > src/db.ts <<'EOF'
import { Pool } from "pg";

export const pool = new Pool({
  connectionString: process.env.DATABASE_URL,
});
EOF

git add .
git commit -m "initial: add db connection"

# Feature branch with a planted SQL injection
git checkout -b feat/user-search

cat > src/users.ts <<'EOF'
import { pool } from "./db";

// BUG: userId is interpolated directly into the SQL string without parameterisation.
// An attacker can pass "1 OR 1=1" to dump all users, or "1; DROP TABLE users;--" to destroy data.
export async function getUserById(userId: string) {
  const result = await pool.query(
    "SELECT id, email, role FROM users WHERE id = " + userId
  );
  return result.rows[0] ?? null;
}

export async function getUserByEmail(email: string) {
  const result = await pool.query(
    `SELECT id, email, role FROM users WHERE email = '${email}'`
  );
  return result.rows[0] ?? null;
}
EOF

git add .
git commit -m "feat: add user lookup by id and email"

echo "Setup complete. Branch: feat/user-search with SQL injection on both functions."
