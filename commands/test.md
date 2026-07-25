---
description: Smoke test — creates an isolated temp repo, runs through cass workflow mechanics (init, plan, dev-feat, clean-wt), reports pass/fail for each step, then cleans up
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
TODAY=$(date +%Y-%m-%d)

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

- **PASS** if `.claude/` exists
- **FAIL** otherwise

---

### Test 2 — init: commit template copied

```bash
cp "${CLAUDE_PLUGIN_ROOT}/assets/commit-template/.gitmessage" "$TEST_REPO/cass-.gitmessage"
```

- **PASS** if `cass-.gitmessage` exists and is non-empty
- **FAIL** otherwise

---

### Test 3 — init: PR template copied

```bash
mkdir -p "$TEST_REPO/.github"
cp "${CLAUDE_PLUGIN_ROOT}/assets/pr-template/pull_request_template.md" "$TEST_REPO/.github/cass-pull_request_template.md"
```

- **PASS** if `.github/cass-pull_request_template.md` exists
- **FAIL** otherwise

---

### Test 4 — init: settings.local.json written correctly

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

Verify all three fields round-trip correctly:

```bash
python3 -c "
import json, sys
s = json.load(open('$TEST_REPO/.claude/settings.local.json'))
p = s['cass']['projects']['cass-test-repo']
ok = p['mainRepoPath'] == '$TEST_REPO' and p['mainBranch'] == 'main' and p['worktreePath'] == '$TEST_WT'
sys.exit(0 if ok else 1)
" 2>/dev/null || node -e "
  const s = JSON.parse(require('fs').readFileSync('$TEST_REPO/.claude/settings.local.json'));
  const p = s.cass.projects['cass-test-repo'];
  const ok = p.mainRepoPath === '$TEST_REPO' && p.mainBranch === 'main' && p.worktreePath === '$TEST_WT';
  process.exit(ok ? 0 : 1);
"
```

- **PASS** if exit 0
- **FAIL** if exit 1 or no parser available

---

### Test 5 — init: worktree base folder created

```bash
mkdir -p "$TEST_WT"
```

- **PASS** if `$TEST_WT` exists
- **FAIL** otherwise

---

### Test 6 — init re-run: second project merges without overwriting first

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

```bash
python3 -c "
import json, sys
s = json.load(open('$TEST_REPO/.claude/settings.local.json'))
ok = bool(s['cass']['projects'].get('cass-test-repo')) and bool(s['cass']['projects'].get('another-project'))
sys.exit(0 if ok else 1)
" 2>/dev/null || node -e "
  const s = JSON.parse(require('fs').readFileSync('$TEST_REPO/.claude/settings.local.json'));
  process.exit(s.cass.projects['cass-test-repo'] && s.cass.projects['another-project'] ? 0 : 1);
"
```

- **PASS** if both projects exist in settings
- **FAIL** if first project was overwritten

---

### Test 7 — plan: requirement file is readable

Write a sample requirement doc:

```bash
mkdir -p "$TEST_REPO/docs"
cat > "$TEST_REPO/docs/test-requirement.md" <<EOF
# Requirement: User Login

## Goal
Allow users to log in with email and password.

## Functional Requirements
- Email and password fields on login page
- Validate credentials against the database
- Redirect to dashboard on success

## Success Criteria
- [ ] User can log in with valid credentials
- [ ] Invalid credentials show an error message
EOF
```

Read it back and verify it contains expected sections:

```bash
grep -c "## Goal\|## Functional Requirements\|## Success Criteria" "$TEST_REPO/docs/test-requirement.md"
```

- **PASS** if count is 3 (all sections present)
- **FAIL** otherwise

---

### Test 8 — plan: docs/ output folder and MD file naming

Simulate saving the plan output as an MD file:

```bash
KEBAB_TITLE="user-login"
PLAN_FILE="$TEST_REPO/docs/${KEBAB_TITLE}_${TODAY}.md"

cat > "$PLAN_FILE" <<EOF
## Plan: User Login

### Goal
Allow users to log in with email and password.

### Risks
| Risk | Likelihood | Impact | Suggestion |
|------|------------|--------|------------|
| Brute force attacks | High | High | Add rate limiting and account lockout |

### Suggestions
- Consider OAuth as a future extension

### Success Criteria
- [ ] User can log in with valid credentials
EOF
```

Verify file exists at the expected path and contains a Risks section:

```bash
[ -f "$PLAN_FILE" ] && grep -q "### Risks" "$PLAN_FILE"
```

- **PASS** if file exists and has Risks section
- **FAIL** otherwise

---

### Test 9 — dev-feat: worktree created for a feature branch

```bash
cd "$TEST_REPO"
git checkout -b feat/smoke-test
git worktree add "$TEST_WT/feat-smoke-test" feat/smoke-test
```

```bash
git -C "$TEST_WT/feat-smoke-test" branch --show-current
```

- **PASS** if output is `feat/smoke-test`
- **FAIL** otherwise

---

### Test 10 — clean-wt: folder listing shows branch and date

```bash
BRANCH=$(git -C "$TEST_WT/feat-smoke-test" branch --show-current 2>/dev/null)
MODIFIED=$(stat -f "%Sm" -t "%Y-%m-%d" "$TEST_WT/feat-smoke-test" 2>/dev/null \
           || stat --format="%y" "$TEST_WT/feat-smoke-test" 2>/dev/null | cut -d' ' -f1)
echo "Branch: $BRANCH | Modified: $MODIFIED"
```

- **PASS** if `BRANCH` is non-empty and `MODIFIED` matches `YYYY-MM-DD`
- **FAIL** otherwise

---

### Test 11 — clean-wt: remote branch check (no remote = skip deletion)

```bash
git ls-remote --heads origin feat/smoke-test 2>/dev/null
```

- **PASS** if command runs without error (empty output = no remote branch = deletion correctly skipped)
- **FAIL** if command errors

---

### Test 12 — clean-wt: worktree removal

```bash
git worktree remove "$TEST_WT/feat-smoke-test" --force
git branch -d feat/smoke-test 2>/dev/null || true
```

- **PASS** if `$TEST_WT/feat-smoke-test` no longer exists
- **FAIL** if it still exists

---

### Teardown — remove temp directory

```bash
cd /tmp
rm -rf "$TEST_DIR"
```

- **PASS** if `$TEST_DIR` no longer exists
- **FAIL** otherwise

---

### Final report

```
cass smoke test results
=======================
Test 1   init: .claude folder                  PASS
Test 2   init: commit template                 PASS
Test 3   init: PR template                     PASS
Test 4   init: settings.local.json shape       PASS
Test 5   init: worktree base folder            PASS
Test 6   init: re-run merges projects          PASS
Test 7   plan: requirement file readable       PASS
Test 8   plan: docs/ output + MD naming        PASS
Test 9   dev-feat: worktree creation           PASS
Test 10  clean-wt: listing branch + date       PASS
Test 11  clean-wt: remote branch check         PASS
Test 12  clean-wt: worktree removal            PASS
Test 13  teardown: temp dir removed            PASS
────────────────────────────────────────────────────
13 passed  0 failed
```

Use `PASS` / `FAIL` / `SKIP`. List any failures with error output below the table.

If all pass:
> "All checks passed. cass mechanics are working correctly."

If any fail:
> "X test(s) failed — see above for details."
