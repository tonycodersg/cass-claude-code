#!/usr/bin/env bash
# Sets up a TypeScript repo with jest, one tested function, and one untested function.
# The qa agent must write a test for the untested function.

set -euo pipefail

git init
git config user.name "Test User"
git config user.email "test@example.com"

# package.json with jest
cat > package.json <<'EOF'
{
  "name": "qa-test-fixture",
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

# tsconfig
cat > tsconfig.json <<'EOF'
{
  "compilerOptions": {
    "target": "ES2020",
    "module": "commonjs",
    "strict": true,
    "esModuleInterop": true,
    "outDir": "dist"
  }
}
EOF

# Source file — two functions: one tested, one untested
mkdir -p src
cat > src/math.ts <<'EOF'
export function add(a: number, b: number): number {
  return a + b;
}

export function divide(a: number, b: number): number {
  if (b === 0) {
    throw new Error("Division by zero");
  }
  return a / b;
}
EOF

# Existing test — only covers add
cat > src/math.test.ts <<'EOF'
import { add } from "./math";

describe("add", () => {
  it("returns the sum of two numbers", () => {
    expect(add(2, 3)).toBe(5);
  });

  it("handles negative numbers", () => {
    expect(add(-1, 1)).toBe(0);
  });
});
EOF

# Note: no npm install here — the test harness evaluates agent output via a
# verifier LLM, not by actually running jest in CI. node_modules are not needed.

git add .
git commit -m "initial: add math module with one untested function"

echo "Setup complete. src/math.ts has divide() with no tests."
