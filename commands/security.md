---
description: Run a security review on the current branch — spawns the security agent to run semgrep (if available) and review the diff against the OWASP Top 10, then reports findings in P1/P2/P3 format
argument-hint: "[PR number or URL — omit to review current branch diff]"
allowed-tools: [Agent, Bash, AskUserQuestion, Read]
model: sonnet
---

## Context

- Working directory: !`pwd`
- Current branch: !`git branch --show-current 2>/dev/null`
- User input: $ARGUMENTS

## Your Role

Invoke the `security` agent to scan the current branch diff (or a specific PR) for vulnerabilities.

## Process

### Step 1 — Determine what to scan

**If `$ARGUMENTS` is a PR number or URL:**
Fetch the PR's head branch:
```bash
gh pr view <PR number or URL> --json headRefName,baseRefName
```
Pass the PR number to the security agent.

**If `$ARGUMENTS` is empty:**
Use the current branch diff against its base. Pass `"current branch"` as context.

### Step 2 — Invoke the security agent

Spawn the `security` agent with:

> "Run a security review on [PR #N / the current branch diff].
> Head branch: [branch]. Base branch: [base].
> Run semgrep if available. Review against OWASP Top 10.
> Report findings in P1/P2/P3 format. Do not apply any fixes."

### Step 3 — Present findings

Present the security agent's report. If there are P1 findings, advise fixing them before merging.
