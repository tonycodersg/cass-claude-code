---
description: QA the current branch — spawns the qa agent to discover the test runner, run the suite, identify untested paths, write missing tests, and report coverage. Pass --tdd <plan-file> to write failing test stubs from a plan before implementation. Pass --verify-pr <PR number or branch> to run suite verification and post results as a PR comment after a PR is created.
argument-hint: "[--tdd <plan-file>] [--verify-pr <PR number or branch>] [--ticket <ref>] [plan-file]"
allowed-tools: [Agent, Bash, AskUserQuestion, Read, Glob, Grep]
model: sonnet
---

## Context

- Working directory: !`pwd`
- Current branch: !`git branch --show-current 2>/dev/null`
- User input: $ARGUMENTS

## Flags

Parse from `$ARGUMENTS`:
- `--tdd <plan-file>` — TDD mode: read plan, write failing stubs, post ticket comment
- `--verify-pr <PR number or branch>` — Verify-PR mode: run suite, post PR comment
- `--ticket <ref>` — ticket reference to post comments to (optional)

## Your Role

Invoke the `qa` agent with the appropriate mode based on the flags in `$ARGUMENTS`.

## Process

### Step 1 — Determine mode

**If `--tdd` is present:**
Pass `--tdd <plan-file>` (and `--ticket <ref>` if provided) to the qa agent.

**If `--verify-pr` is present:**
Pass `--verify-pr <PR number or branch>` (and `--ticket <ref>` if provided) to the qa agent.

**If neither flag is present:**
Locate the plan file if `$ARGUMENTS` is a path, or search for one matching the current branch in `.claude/plans/` and `docs/plans/`. Pass it (or `"branch diff"`) to the qa agent in default mode.

### Step 2 — Invoke the qa agent

Spawn the `qa` agent with the resolved flags and context as a single prompt string.

### Step 3 — Present results

Present the qa agent's report to the user. If tests were written or a comment was posted, confirm this clearly.
