---
description: QA the current branch — spawns the qa agent to discover the test runner, run the suite, identify untested paths, write missing tests, and report coverage before and after
argument-hint: "[path to plan file — omit to use branch diff]"
allowed-tools: [Agent, Bash, AskUserQuestion, Read, Glob, Grep]
model: sonnet
---

## Context

- Working directory: !`pwd`
- Current branch: !`git branch --show-current 2>/dev/null`
- User input: $ARGUMENTS

## Your Role

Trigger a QA coverage pass using the `qa` agent. Works standalone or after the `swe` agent has finished implementing.

## Process

### Step 1 — Locate the plan file

**If `$ARGUMENTS` is a file path:**
Use it directly as the plan file.

**If `$ARGUMENTS` is empty:**
Search for a matching plan file:
1. Check `.claude/plans/` for an MD file whose name matches the current branch
2. Check `docs/plans/` and `instructions/` similarly

Pass the plan file path to the qa agent if found; otherwise pass `"branch diff"` as context.

### Step 2 — Invoke the qa agent

Spawn the `qa` agent with this context:

> "Run a QA coverage pass on the current branch.
> Plan file: [path if found, otherwise 'branch diff — use git diff against base'].
> Discover the test runner and coverage tooling from the project.
> Identify untested paths in the diff, write missing tests following project conventions, re-run the suite, and output a QA report."

### Step 3 — Present the report

Present the qa agent's QA report to the user. If tests were written and all pass, say so clearly so the user knows the branch is ready for review or PR creation.
