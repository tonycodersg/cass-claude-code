---
description: Create a PR from the current branch — runs in the worktree where the feature branch is checked out. Sub-task branches PR into the main feature branch; main feature branches PR into staging (default) with option to change target.
argument-hint: "[optional: base branch override]"
allowed-tools: [Bash, Read, Write, AskUserQuestion, Agent, mcp__github__*]
model: sonnet
---

## Context

- Working directory: !`pwd`
- Current branch: !`git branch --show-current 2>/dev/null`
- Repo root: !`git rev-parse --show-toplevel 2>/dev/null || pwd`
- Repo name: !`basename $(git rev-parse --show-toplevel 2>/dev/null) 2>/dev/null || basename $(pwd)`
- Today's date: !`date +%Y-%m-%d`
- All worktrees: !`git worktree list --porcelain 2>/dev/null`
- cass settings: !`cat .claude/settings.local.json 2>/dev/null || echo "NOT FOUND"`
- Claude session ID: !`echo "${CLAUDE_SESSION_ID:-unknown}"`
- User override: $ARGUMENTS

## Your Role

Create a pull request from the feature branch in the current worktree. This command is designed to run inside a worktree folder — the branch is already checked out here by `/cass:dev-feat`.

## Process

### Step 1 — Confirm working context

From context, identify:
- **Current branch** — from `git branch --show-current`
- **Current directory** — this is the worktree folder the branch lives in
- **Worktree list** — used to confirm this is a worktree (not the main repo folder)

If `git worktree list` shows only one entry matching this directory (i.e. this IS the main repo, not a worktree), warn the user:
> "You're in the main repo folder, not a worktree. `/cass:pr` is intended to run inside a feature worktree. Are you sure you want to create a PR from here? (y/n)"

Proceed only if they confirm.

---

### Step 2 — Determine PR target

**If `$ARGUMENTS` is provided**, use it as the base branch — skip the logic below.

**Otherwise**, classify the current branch:

**Sub-task branch** (branch has a stream label, e.g. `feat/user-auth-api-layer`, `feat/PROJ-123-ui`):
- Target = the parent main feature branch (e.g. `feat/user-auth`, `feat/PROJ-123`)
- Derive the parent by stripping the last `-<label>` segment from the branch name
- Confirm: `git ls-remote --heads origin <parent-branch>` — if it exists, use it

**Main feature branch** (single segment after `feat/`, e.g. `feat/user-authentication`):
- Target defaults to `staging`
- Ask the user to confirm or change:
  > "PR target: `staging`
  > Press Enter to confirm, or type a different branch name:"
- If they press Enter → use `staging`
- If they type a name → use that instead

**If ambiguous**, ask:
> "What branch should this PR target?
> 1. `staging` (default — main integration branch)
> 2. `feat/<detected-parent>` (main feature branch — for sub-task PRs)
> 3. Other — type the branch name"

---

### Step 3 — Find plan file

Search for a matching plan or requirement file to use as PR context:
1. Check `docs/` for any MD file matching the feature name or created recently
2. Check `.claude/plans/` for a matching plan
3. If found, read it for Goal, Approach, and Success Criteria

---

### Step 4 — Optional SA review

Ask the user:
> "Would you like the SA agent to do a quick code review before creating the PR? (Recommended)"

**If yes:** invoke the `sa` agent with the current branch diff and plan file (if found). Wait for findings. Apply must-fix items. Ask about should-fix items.

**If no:** proceed directly.

---

### Step 5 — Push

```bash
git push -u origin <current-branch>
```

---

### Step 6 — Create PR

```bash
gh pr create \
  --base <target-branch> \
  --title "<type>(<scope>): <summary>" \
  --body "<body>"
```

PR body structure:

```markdown
## What
<goal from plan/requirement, or brief description of changes>

## Why
<ticket reference or motivation>

## How
<approach summary>

## Architecture Review
<SA findings if review was run; otherwise "SA review not run">

## Implementation Steps
<numbered list of what was done>

## Risks
<risks carried over from the plan's Risks table, or "No significant risks" if none were flagged>

## Test Coverage
<what was tested — unit tests added, integration tests, manual verification steps>

## Checklist
- [ ] <success criterion from plan>
- [ ] Build and lint pass
- [ ] Tests pass
- [ ] Risks documented
- [ ] No out-of-scope changes

---

**Claude session:** <Claude session ID from context>
```

If `.github/cass-pull_request_template.md` exists, use it as the base template and replace the `<!-- $CLAUDE_SESSION_ID -->` placeholder with the session ID from context.

If `gh` is not available, output the filled PR body for the user to paste manually and provide the GitHub PR creation URL.

---

### Step 7 — Report

Output the PR URL and remind the user what comes next:

**If this was a sub-task PR:**
> "Sub-task PR created → `<main-feature-branch>`. Once all sub-task PRs are merged there, run `/cass:pr` from the `<main-feature-branch>` worktree to create the final PR to `staging`."

**If this was a main feature PR to staging:**
> "PR created → `staging`. Run `/cass:clean-wt` once the PR is merged to remove the worktree."
