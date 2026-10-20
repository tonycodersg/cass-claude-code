#!/usr/bin/env bash
# Minimal repo for testing the planner --qa flag.
# The planner must write a plan file and spawn the qa agent in TDD mode.

set -euo pipefail

git init
git config user.name "Test User"
git config user.email "test@example.com"

cat > CLAUDE.md <<'EOF'
# divide-service

## Commands
- `npm test` — jest

## Conventions
- Feature branches from main
- Semantic commits
EOF

cat > package.json <<'EOF'
{
  "name": "divide-service",
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

echo "Setup complete. Repo ready for planner --qa test."
