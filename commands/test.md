---
description: Smoke test — creates an isolated temp repo, runs through the cass workflow mechanics (init, worktree creation, clean-wt listing), reports pass/fail for each step, then cleans up
allowed-tools: [Bash, Read]
---

## Context

- Plugin root: !`echo "${CLAUDE_PLUGIN_ROOT}"`
- Today's date: !`date +%Y-%m-%d`
- OS: !`uname -s`

## Instructions

Run a scripted smoke test of cass command mechanics in an isolated temp directory. Do not touch the current project. Report pass/fail for every step. Clean up at the end regardless of failures.

---

### Setup — create isolated test environment

```bash
TEST_DIR=$(mktemp -d)
TEST_REPO="$TEST_DIR/cass-test-repo"
TEST_WT="$TEST_DIR/cass-test-repo-agent-works"

mkdir -p "$TEST_REPO"
cd "$TEST_REPO"
git init
git config user.name "cass-test"
git config user.email "cass-test@localhost"
git commit --allow-empty -m "init"
```

Print:
```
cass smoke test
===============
Test repo: $TEST_REPO
Worktrees: $TEST_WT
```

Track results as a list: `PASS`, `FAIL <reason>`, or `SKIP <reason>`.

---

### Test 1 — init: .claude folder created

```bash
mkdir -p "$TEST_REPO/.claude"
```

Check `.claude/` exists:
- **PASS** if directory exists
- **FAIL** otherwise

---

### Test 2 — init: commit template copied

```bash
cp "${CLAUDE_PLUGIN_ROOT}/assets/commit-template/.gitmessage" "$TEST_REPO/cass-.gitmessage"
```

Check `cass-.gitmessage` exists and is non-empty:
- **PASS** if file exists and has content
- **FAIL** otherwise

---

### Test 3 — init: PR template copied

```bash
mkdir -p "$TEST_REPO/.github"
cp "${CLAUDE_PLUGIN_ROOT}/assets/pr-template/pull_request_template.md" "$TEST_REPO/.github/cass-pull_request_template.md"
```

Check `.github/cass-pull_request_template.md` exists:
- **PASS** if file exists
- **FAIL** otherwise

---

### Test 4 — init: settings.local.json written correctly

Write a simulated settings file:

```bash
cat > "$TEST_REPO/.claude/settings.local.json" <<EOF
{
  "cass": {
    "projects": {
      "cass-test-repo": {
        "mainRepoPath": "$TEST_REPO",
        "mainBranch": "main",
        "worktreePath": "$TEST_WT"
      }
    }
  }
}
EOF
```

Read it back and verify:
- `cass.projects.cass-test-repo.mainRepoPath` == `$TEST_REPO`
- `cass.projects.cass-test-repo.mainBranch` == `"main"`
- `cass.projects.cass-test-repo.worktreePath` == `$TEST_WT`

```bash
node -e "
  const s = JSON.parse(require('fs').readFileSync('$TEST_REPO/.claude/settings.local.json'));
  const p = s.cass.projects['cass-test-repo'];
  const ok = p.mainRepoPath === '$TEST_REPO' && p.mainBranch === 'main' && p.worktreePath === '$TEST_WT';
  process.exit(ok ? 0 : 1);
" 2>/dev/null || python3 -c "
import json, sys
s = json.load(open('$TEST_REPO/.claude/settings.local.json'))
p = s['cass']['projects']['cass-test-repo']
ok = p['mainRepoPath'] == '$TEST_REPO' and p['mainBranch'] == 'main' and p['worktreePath'] == '$TEST_WT'
sys.exit(0 if ok else 1)
"
```

- **PASS** if exit 0
- **FAIL** if exit 1 or command not available

---

### Test 5 — init: worktree base folder created

```bash
mkdir -p "$TEST_WT"
```

Check folder exists:
- **PASS** if directory exists
- **FAIL** otherwise

---

### Test 6 — init re-run: second project merges without overwriting first

Simulate a second init for a different project:

```bash
python3 -c "
import json
path = '$TEST_REPO/.claude/settings.local.json'
s = json.load(open(path))
s['cass']['projects']['another-project'] = {
    'mainRepoPath': '/tmp/another',
    'mainBranch': 'staging',
    'worktreePath': '/tmp/another-agent-works'
}
json.dump(s, open(path, 'w'), indent=2)
" 2>/dev/null || node -e "
  const fs = require('fs');
  const path = '$TEST_REPO/.claude/settings.local.json';
  const s = JSON.parse(fs.readFileSync(path));
  s.cass.projects['another-project'] = { mainRepoPath: '/tmp/another', mainBranch: 'staging', worktreePath: '/tmp/another-agent-works' };
  fs.writeFileSync(path, JSON.stringify(s, null, 2));
"
```

Verify original project is still intact:
```bash
python3 -c "
import json, sys
s = json.load(open('$TEST_REPO/.claude/settings.local.json'))
orig = s['cass']['projects'].get('cass-test-repo')
new = s['cass']['projects'].get('another-project')
sys.exit(0 if orig and new else 1)
" 2>/dev/null || node -e "
  const s = JSON.parse(require('fs').readFileSync('$TEST_REPO/.claude/settings.local.json'));
  const ok = s.cass.projects['cass-test-repo'] && s.cass.projects['another-project'];
  process.exit(ok ? 0 : 1);
"
```

- **PASS** if both projects exist
- **FAIL** if first project was overwritten

---

### Test 7 — dev-feat: worktree created for a feature branch

```bash
cd "$TEST_REPO"
git checkout -b feat/smoke-test
git worktree add "$TEST_WT/feat-smoke-test" feat/smoke-test
```

Check worktree folder exists and is on correct branch:
```bash
git -C "$TEST_WT/feat-smoke-test" branch --show-current
```

- **PASS** if output is `feat/smoke-test`
- **FAIL** otherwise

---

### Test 8 — clean-wt: folder listing shows branch and date

```bash
BRANCH=$(git -C "$TEST_WT/feat-smoke-test" branch --show-current 2>/dev/null)
MODIFIED=$(stat -f "%Sm" -t "%Y-%m-%d" "$TEST_WT/feat-smoke-test" 2>/dev/null \
           || stat --format="%y" "$TEST_WT/feat-smoke-test" 2>/dev/null | cut -d' ' -f1)
echo "Branch: $BRANCH | Modified: $MODIFIED"
```

- **PASS** if `BRANCH` is non-empty and `MODIFIED` matches `YYYY-MM-DD` pattern
- **FAIL** otherwise

---

### Test 9 — clean-wt: worktree removal

```bash
git worktree remove "$TEST_WT/feat-smoke-test" --force
git branch -d feat/smoke-test 2>/dev/null || true
```

Check worktree folder is gone:
- **PASS** if `$TEST_WT/feat-smoke-test` no longer exists
- **FAIL** if it still exists

---

### Teardown — remove temp directory

```bash
cd /tmp
rm -rf "$TEST_DIR"
```

Confirm `$TEST_DIR` is gone:
- **PASS** if removed
- **FAIL** if still exists

---

### Final report

Print results for every test:

```
cass smoke test results
=======================
Test 1  init: .claude folder              PASS
Test 2  init: commit template             PASS
Test 3  init: PR template                 PASS
Test 4  init: settings.local.json shape   PASS
Test 5  init: worktree base folder        PASS
Test 6  init: re-run merges projects      PASS
Test 7  dev-feat: worktree creation       PASS
Test 8  clean-wt: listing branch + date   PASS
Test 9  clean-wt: worktree removal        PASS
Test 10 teardown: temp dir removed        PASS
───────────────────────────────────────────────
10 passed  0 failed
```

Use `PASS` / `FAIL` / `SKIP`. If any test failed, list the failures with the error output under the table.

If all pass:
> "All checks passed. cass mechanics are working correctly."

If any fail:
> "X test(s) failed — see above for details."
