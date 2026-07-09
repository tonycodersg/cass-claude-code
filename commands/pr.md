---
description: Create a PR from the current branch — auto-detects whether this is a sub-task branch (PR → main feature branch) or main feature branch (PR → staging)
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
- User override: $ARGUMENTS

## Your Role

Create a pull request from the current branch. Automatically infer the correct PR target based on the branch naming convention established by `/cass:dev-feat`.

## Process

### Step 1 — Determine PR target

Get the current branch name. Apply this logic to determine the base branch:

**If `$ARGUMENTS` is provided**, use it as the base branch (user override).

**Otherwise:**

1. Check if this is a worktree sub-task branch by looking at the branch name pattern:
   - If the branch name matches `feat/<ticket-or-feature>-<stream-label>` (has more than one segment after `feat/`), it's likely a sub-task branch
   - Confirm by checking if a parent branch exists: `git log --oneline HEAD..origin/feat/<parent>` or check `.claude/settings.local.json` for the feature context

2. Heuristic:
   - Branch like `feat/PROJ-123-api-layer` → look for `feat/<base-feature>` (e.g. `feat/user-auth`) as the parent → PR targets `feat/<base-feature>`
   - Branch like `feat/user-authentication` (single segment) → PR targets `staging` (or `main` if staging doesn't exist)

3. If ambiguous, ask:
   > "What branch should this PR target?
   > 1. `staging` (main integration branch)
   > 2. `feat/<feature>` (main feature branch — for sub-task PRs)
   > 3. Other (specify)"

### Step 2 — Find plan file

Search for a matching plan or requirement file to use as PR context:
1. Check `docs/` for any MD file matching the feature name or created recently
2. Check `.claude/plans/` for a matching plan
3. If found, read it for Goal, Approach, and Success Criteria

### Step 3 — Optional SA review

Ask the user:
> "Would you like the SA agent to do a quick code review before creating the PR? (Recommended)"

**If yes:** invoke the `sa` agent with the current branch diff and plan file (if found). Wait for findings. Apply must-fix items. Ask about should-fix items.

**If no:** proceed directly.

### Step 4 — Push

```bash
git push -u origin <current-branch>
```

### Step 5 — Create PR

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

## Checklist
- [ ] <success criterion from plan>
- [ ] Build and lint pass
- [ ] Tests pass
- [ ] No out-of-scope changes
```

If `.github/cass-pull_request_template.md` exists, use it as the base template.

If `gh` is not available, output the filled PR body for the user to paste manually and provide the GitHub PR creation URL.

### Step 6 — Report

Output the PR URL. If this is a sub-task PR, remind the user:
> "Sub-task PR created → `feat/<main-feature>`. Once all sub-task PRs are merged there, run `/cass:pr` from `feat/<main-feature>` to create the final PR to staging."
