#!/usr/bin/env bash
# Sets up a repo with a plan file but NO implementation yet.
# The qa agent in --tdd mode must write failing test stubs from the plan's success criteria.

set -euo pipefail

git init
git config user.name "Test User"
git config user.email "test@example.com"

cat > package.json <<'EOF'
{
  "name": "tdd-fixture",
  "version": "1.0.0",
  "scripts": {
    "test": "jest",
    "test:coverage": "jest --coverage"
  },
  "devDependencies": {
    "@types/jest": "^29.0.0",
    "jest": "^29.0.0",
    "ts-jest": "^29.0.0",
    "typescript": "^5.0.0"
  },
  "jest": {
    "preset": "ts-jest",
    "testEnvironment": "node",
    "testMatch": ["**/*.test.ts"]
  }
}
EOF

cat > tsconfig.json <<'EOF'
{
  "compilerOptions": {
    "target": "ES2020",
    "module": "commonjs",
    "strict": true,
    "esModuleInterop": true
  }
}
EOF

# Plan file — describes divide() with two success criteria, no source file yet
mkdir -p .claude/plans
cat > .claude/plans/divide.md <<'EOF'
# Plan: add divide function

## Goal

Add a `divide(a, b)` function to `src/math.ts` that returns the quotient of two numbers.

## Approach

Export a single function `divide(a: number, b: number): number` from `src/math.ts`.

## Success Criteria

- [ ] `divide(6, 2)` returns `3`
- [ ] `divide(6, 0)` throws an error with the message "Division by zero"
- [ ] `divide(-6, 2)` returns `-3`
EOF

git add .
git commit -m "initial: plan file only, no implementation"

echo "Setup complete. Plan at .claude/plans/divide.md — no src/math.ts exists."
