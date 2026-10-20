#!/usr/bin/env bash
# Minimal repo for testing the planner's interactive qa offer (Step 5d).
# The user says yes to the qa offer — no --qa flag used.

set -euo pipefail

git init
git config user.name "Test User"
git config user.email "test@example.com"

cat > CLAUDE.md <<'EOF'
# multiply-service

## Commands
- `npm test` — jest

## Conventions
- Feature branches from main
- Semantic commits
EOF

cat > package.json <<'EOF'
{
  "name": "multiply-service",
  "version": "1.0.0",
  "scripts": { "test": "jest" },
  "devDependencies": {
    "jest": "^29.0.0",
    "ts-jest": "^29.0.0",
    "typescript": "^5.0.0",
    "@types/jest": "^29.0.0"
  },
  "jest": { "preset": "ts-jest", "testEnvironment": "node", "testMatch": ["**/*.test.ts"] }
}
EOF

git add .
git commit -m "initial: minimal repo"

echo "Setup complete."
