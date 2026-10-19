---
description: Review a PR or the current branch — spawns the pr-reviewer agent to check logic, performance, code quality, and plan compliance. Pass --security to also run the security agent for an OWASP/SAST scan.
argument-hint: "[PR number or URL — omit to review current branch] [--security]"
allowed-tools: [Agent, Bash, AskUserQuestion, Read, Edit, Write, Glob, Grep]
model: sonnet
---

## Context

- Working directory: !`pwd`
- Current branch: !`git branch --show-current 2>/dev/null`
- User input: $ARGUMENTS

## Your Role

Trigger a code review using the `pr-reviewer` agent. Works for both an open PR and local branch changes. When `--security` is passed, also spawn the `security` agent in parallel and present both reports together.

## Flags

Parse from `$ARGUMENTS`:
- `--security` — also run the `security` agent alongside `pr-reviewer`

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

### Step 3b — Invoke security agent (if --security flag is set)

If `--security` was passed, spawn the `security` agent in parallel with the pr-reviewer:

> "Run a security review on the current branch diff.
> Head branch: [branch name]. Base branch: [target branch].
> Run semgrep if available. Review against OWASP Top 10.
> Output findings in P1/P2/P3 format. Do not apply any fixes — report only."

### Step 4 — Report findings

Present the pr-reviewer agent's output to the user. If `--security` was passed, also present the security agent's findings as a separate **Security Review** section.

Ask:

> "Would you like to fix any of the findings now? (P1 items are strongly recommended before merging)"

If the user wants to fix items, guide them or invoke the SWE agent for specific fixes. Do not apply fixes yourself unless the user explicitly asks.

---

### Step 5 — List all PR comment threads and their status

If a PR number is known, fetch all review threads and list each one with its resolved status.

Use the GitHub GraphQL API to get threads with resolved state:

```bash
gh api graphql -f query='
{
  repository(owner: "<owner>", name: "<repo>") {
    pullRequest(number: <PR number>) {
      reviewThreads(first: 50) {
        nodes {
          isResolved
          isOutdated
          comments(first: 1) {
            nodes {
              path
              line
              body
              author { login }
            }
          }
        }
      }
    }
  }
}'
```

Get owner and repo from:
```bash
gh repo view --json owner,name
```

Present the results as a table:

```
## PR #N — Comment Threads

  #   File                  Line  Author        Status       Preview
  1   src/auth.ts           42    reviewer      ✗ unresolved  "Check null case here…"
  2   src/utils.ts          18    reviewer      ✓ resolved    "Rename this variable…"
  3   src/auth.ts           67    reviewer      ✗ unresolved  "Missing error handling…"
  4   (outdated)            —     reviewer      ✗ unresolved  "Old comment on deleted line…"

  2 unresolved · 1 resolved · 1 outdated
```

- `✓ resolved` — thread was marked resolved on GitHub
- `✗ unresolved` — still open, needs attention
- Mark outdated threads as `(outdated)` in the File column

After the table, if there are unresolved threads, ask:

> "There are N unresolved comment threads. Would you like to work through them one by one? (y/n)"

If yes — step through each unresolved thread:
1. Show the full comment body
2. Show the code context (`git show HEAD:<file> | sed -n '<line-5>,<line+5>p'`)
3. Ask: "How would you like to address this? (fix / dismiss / skip)"
   - fix → apply the change, note it as addressed
   - dismiss → note as acknowledged, move on
   - skip → leave for later
4. After working through all threads, summarise what was fixed vs dismissed vs skipped
