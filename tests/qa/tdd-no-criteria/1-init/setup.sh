#!/usr/bin/env bash
# Plan file has Goal and Approach but NO Success Criteria section.
# The qa agent in --tdd mode must fall back to deriving testable units
# from the Goal and Approach sections instead of failing silently.

set -euo pipefail

git init
git config user.name "Test User"
git config user.email "test@example.com"

cat > package.json <<'EOF'
{
  "name": "tdd-no-criteria-fixture",
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

# Plan file with Goal + Approach but deliberately NO Success Criteria section
mkdir -p .claude/plans
cat > .claude/plans/clamp.md <<'EOF'
# Plan: add clamp function

## Goal

Add a `clamp(value, min, max)` function to `src/math.ts` that constrains
a number to be within a given range. Returns min if value < min,
returns max if value > max, otherwise returns value unchanged.

## Background

Needed by the animation engine to keep keyframe values within legal bounds.

## Approach

Export a single function `clamp(value: number, min: number, max: number): number`
from `src/math.ts`. The function returns `value` when `min <= value <= max`,
returns `min` when `value < min`, and returns `max` when `value > max`.
EOF

# No src/math.ts yet — no implementation exists
git add .
git commit -m "initial: plan for clamp function, no implementation"

echo "Setup complete. Plan at .claude/plans/clamp.md — NO Success Criteria section."
