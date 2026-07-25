---
description: Review a PR or the current branch — spawns the pr-reviewer agent to check logic, performance, code quality, and plan compliance
argument-hint: "[PR number or URL — omit to review current branch]"
allowed-tools: [Agent, Bash, AskUserQuestion, Read]
model: sonnet
---

## Context

- Working directory: !`pwd`
- Current branch: !`git branch --show-current 2>/dev/null`
- User input: $ARGUMENTS

## Your Role

Trigger a code review using the `pr-reviewer` agent. Works for both an open PR and local branch changes.

## Process

### Step 1 — Determine what to review

**If `$ARGUMENTS` is a PR number or URL:**

Fetch PR details:
```bash
gh pr view <PR number or URL> --json number,title,headRefName,baseRefName,body
```

Pass the PR number, head branch, base branch, and PR body to the pr-reviewer agent.

**If `$ARGUMENTS` is empty:**

Check if the current branch has an open PR:
```bash
gh pr view --json number,title,headRefName,baseRefName,body 2>/dev/null
```

If a PR exists, use it. If not, review the local diff against the base branch:
```bash
git merge-base HEAD origin/<default-branch>
git diff $(git merge-base HEAD origin/<default-branch>)
```

### Step 2 — Find plan file

Search for the matching requirement or plan file for context:
1. Check `docs/` for an MD file matching the branch/feature name
2. Check `.claude/plans/` for a matching plan

Pass the plan file path to the pr-reviewer agent if found.

### Step 3 — Invoke pr-reviewer agent

Spawn the `pr-reviewer` agent with this context:

> "Review [PR #N / the current branch diff]. 
> Plan file: [path if found, otherwise 'not available'].
> Head branch: [branch name]. Base branch: [target branch].
> Review for: logic correctness, performance, syntax/code quality, and plan compliance.
> Group findings as P1 (must fix), P2 (should fix), P3 (consider), and Plan Compliance checklist.
> Do not apply any fixes — report only."

### Step 4 — Report findings

Present the pr-reviewer agent's output to the user. Ask:

> "Would you like to fix any of the findings now? (P1 items are strongly recommended before merging)"

If the user wants to fix items, guide them or invoke the SWE agent for specific fixes. Do not apply fixes yourself unless the user explicitly asks.
