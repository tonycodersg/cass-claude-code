#!/usr/bin/env bash
# Sets up a feature branch with a passing test suite and a stubbed gh.
# After /cass:pr, the qa agent must spawn in --verify-pr mode and report.

set -euo pipefail

# Stub gh to simulate a successful PR creation
mkdir -p ./bin
cat > ./bin/gh <<'GHEOF'
#!/usr/bin/env bash
if [[ "$1" == "pr" && "$2" == "create" ]]; then
  echo "https://github.com/test-org/test-repo/pull/99"
  exit 0
fi
if [[ "$1" == "pr" && "$2" == "view" ]]; then
  echo '{"number":99,"headRefName":"feat/add-divide","baseRefName":"staging","body":"Adds divide function","title":"feat: add divide"}'
  exit 0
fi
echo ""
exit 0
GHEOF
chmod +x ./bin/gh
echo "PATH=$(pwd)/bin:$PATH" > .cass-test-env

git init
git config user.name "Test User"
git config user.email "test@example.com"
git remote add origin https://github.com/test-org/test-repo.git

echo "# README" > README.md
git add README.md
git commit -m "chore: initial commit"

git checkout -b feat/add-divide

mkdir -p src
# Note: no npm install — the verifier uses LLM evaluation of agent output,
# not real jest execution. The qa agent will attempt to run the suite and
# report whatever outcome it gets (even jest-not-found is reportable output).
cat > package.json <<'EOF'
{
  "name": "qa-pr-fixture",
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
{ "compilerOptions": { "target": "ES2020", "module": "commonjs", "strict": true, "esModuleInterop": true } }
EOF

cat > src/math.ts <<'EOF'
export function divide(a: number, b: number): number {
  if (b === 0) throw new Error("Division by zero");
  return a / b;
}
EOF

cat > src/math.test.ts <<'EOF'
import { divide } from "./math";
describe("divide", () => {
  it("returns the quotient", () => {
    expect(divide(6, 2)).toBe(3);
  });
});
EOF

mkdir -p .cass .claude
echo "# PR Template" > .cass/pr-template.md
cat > .claude/settings.local.json <<'EOF'
{
  "cass": {
    "projects": {
      "qa-pr-fixture": {
        "mainBranch": "main",
        "mainRepoPath": "/tmp/qa-pr-fixture"
      }
    }
  }
}
EOF

git add .
git commit -m "feat: add divide with happy-path test"

echo "Setup complete. Branch: feat/add-divide with a passing test suite."
