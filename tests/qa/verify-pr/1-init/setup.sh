#!/usr/bin/env bash
# Sets up a feature branch with divide() implemented but zero-division path untested.
# The qa agent in --verify-pr mode must run the suite and flag the gap.

set -euo pipefail

git init
git config user.name "Test User"
git config user.email "test@example.com"

cat > package.json <<'EOF'
{
  "name": "verify-pr-fixture",
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
    "testMatch": ["**/*.test.ts"],
    "coverageProvider": "v8"
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

mkdir -p src
cat > src/math.ts <<'EOF'
export function divide(a: number, b: number): number {
  if (b === 0) throw new Error("Division by zero");
  return a / b;
}
EOF

git add .
git commit -m "initial: baseline"

# Feature branch — divide() implemented, only happy path tested
git checkout -b feat/add-divide

cat > src/math.test.ts <<'EOF'
import { divide } from "./math";

describe("divide", () => {
  it("returns the quotient of two numbers", () => {
    expect(divide(6, 2)).toBe(3);
  });
});
EOF

git add .
git commit -m "feat: add divide with happy-path test only"

echo "Setup complete. Branch: feat/add-divide — zero-division path is untested."
