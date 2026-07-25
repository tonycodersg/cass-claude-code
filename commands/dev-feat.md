---
description: SWE/SA workflow — read a requirement MD or ticket, write an implementation plan with test coverage, identify parallel workstreams, set up worktrees, and spawn SWE agents to implement
argument-hint: "[path to requirement MD or ticket ref e.g. PROJ-123]"
allowed-tools: [EnterPlanMode, ExitPlanMode, AskUserQuestion, Write, Read, Glob, Grep, Bash, Agent, mcp__atlassian__*, mcp__github__*]
model: sonnet
---

## Context

- Working directory: !`pwd`
- Today's date: !`date +%Y-%m-%d`
- Repo name: !`basename $(git rev-parse --show-toplevel 2>/dev/null) 2>/dev/null || basename $(pwd)`
- Repo root: !`git rev-parse --show-toplevel 2>/dev/null || pwd`
- User input: $ARGUMENTS
- cass settings: !`cat .claude/settings.local.json 2>/dev/null || echo "NOT FOUND"`

## Your Role

You are a senior SWE/SA. Your job is to read a requirement document, write a concrete implementation plan with test coverage, identify parallel workstreams, set up the right git/worktree structure, and spawn SWE agents to implement — with the user's explicit approval at each decision point.

## Process

### Step 1 — Load requirement

**If `$ARGUMENTS` is provided**, load it directly:
- File path → read with the Read tool
- Jira ticket (e.g. `PROJ-123`) → fetch via Atlassian MCP
- GitHub issue (e.g. `#42`) → fetch via GitHub MCP

**If `$ARGUMENTS` is empty**, ask:
> "Do you have a requirement from the PO?
> 1. MD file — provide the path (e.g. `docs/user-login_2026-07-25.md`)
> 2. Jira ticket — provide the ticket key (e.g. `PROJ-123`)
> 3. GitHub issue — provide the issue number (e.g. `#42`)
> 4. None — describe the requirement now"

Load from whichever source they choose. If they chose option 4, take their description as the requirement and proceed.

Extract: goal, scope, functional requirements, non-functional requirements, success criteria, technical notes.

### Step 2 — Discover project conventions

**Check if the plan already has `### Dev Questions` and `### Technical Context` sections** (written by the SA agent during `/cass:plan`):

- **If both sections exist** → use them directly. Skip SA investigation entirely — the PO's plan already contains the technical context and dev questions. Print:
  > "Using technical context from PO plan — skipping re-investigation."

- **If either section is missing** → read project context in this order:
  1. `CLAUDE.md`
  2. `instructions/`, `docs/`, `.claude/`
  3. `README.md`

### Step 3 — Enter plan mode

Enter plan mode immediately. Do not modify any files until the user approves the plan.

### Step 3b — Resolve dev questions

If the plan has a `### Dev Questions` section with unanswered questions, present them to the dev now before writing the implementation plan:

> "The PO plan flagged these questions for the dev team to answer before we start:
> 1. <question>
> 2. <question>"

Wait for answers, then incorporate them into the implementation plan. If all questions are already answered or the section is empty, proceed directly.

---

### Step 4 — Write implementation plan

Produce a structured implementation plan:

```markdown
## Implementation Plan: <feature title>

### Goal
<one sentence from requirement>

### Approach
<how you'll implement this — phases, key decisions>

### Task Breakdown

#### Sequential tasks (must run in order)
1. Task A: <description> | Tests: <what to test>
2. Task B: <description> | Tests: <what to test>

#### Parallel workstreams (can run simultaneously)
- Stream 1 — <label>: <description> | Tests: <what to test>
- Stream 2 — <label>: <description> | Tests: <what to test>

### Test Coverage
- Unit tests: <what>
- Integration tests: <what>
- E2E tests: <what, if applicable>

### Risk areas
- <risk and mitigation>

### Out of scope
- <item>
```

Present this plan to the user. Ask:
> "Does this plan look right? Any changes before we proceed?"

Iterate until the user approves.

### Step 5 — Workspace setup

Read `cass.projects` from `.claude/settings.local.json` (already injected in context above).

**If there is exactly one project in `cass.projects`:** use it automatically. Tell the user:
> "Using project `<name>`:
>   Main repo:     `<mainRepoPath>` (branch: `<mainBranch>`)
>   Worktree base: `<worktreePath>`"

**If there are multiple projects:** ask the user which project to work on:
> "Which project?
> 1. `<project-name-1>` — `<mainRepoPath>`
> 2. `<project-name-2>` — `<mainRepoPath>`"

Use the selected project's `mainRepoPath`, `mainBranch`, and `worktreePath` for all subsequent steps.

**If no projects are configured (init has not been run):** tell the user:
> "No projects configured. Run `/cass:init <project-name>` first, then come back."

Stop and do not proceed until init has been run.

### Step 6 — Git and worktree setup

**Determine base branch:**

Use `cass.mainBranch` from settings as the base branch. Fetch and pull it:

```bash
git fetch origin
git checkout <mainBranch>
git pull origin <mainBranch>
```

If the branch doesn't exist on the remote, stop and ask the user to verify their init configuration.

**Create the main feature branch:**

```bash
git checkout <base-branch>
git pull origin <base-branch>
git checkout -b feat/<kebab-feature-title>
git push -u origin feat/<kebab-feature-title>
```

Derive `<kebab-feature-title>` from the requirement title (lowercase, hyphens).

If the plan has parallel workstreams AND the user approved worktree mode:

**Ask before creating parallel structure:**
> "The plan has [N] parallel workstreams. Shall I create a separate worktree + sub-branch for each so agents can work simultaneously? Each sub-branch will target `feat/<kebab-feature-title>` and get its own PR into that branch."

**If approved — create main feature worktree:**

```bash
mkdir -p <worktree-base>
git worktree add <worktree-base>/feat-<kebab-feature-title> feat/<kebab-feature-title>
```

**For each parallel workstream:**

Derive a short label: `<ticket-number>-<stream-label>` (e.g. `PROJ-123-api-layer`, `PROJ-123-ui`).
If no ticket number exists, use `<feature-kebab>-<stream-label>`.

```bash
git checkout feat/<kebab-feature-title>
git checkout -b feat/<stream-label>
git push -u origin feat/<stream-label>
git worktree add <worktree-base>/<stream-label> feat/<stream-label>
```

**If no parallel workstreams OR user declined parallel split:**

Create single worktree (if worktree mode):
```bash
mkdir -p <worktree-base>
git worktree add <worktree-base>/feat-<kebab-feature-title> feat/<kebab-feature-title>
```

### Step 7 — Spawn SWE agents

**If parallel workstreams with worktrees:**

Spawn one SWE agent per workstream simultaneously. For each agent, pass:
- The worktree path to work in
- The sub-branch name
- The main feature branch as the PR target
- The specific tasks for that stream (extracted from the plan)
- The requirement file path
- Instruction: "Create a PR targeting `feat/<kebab-feature-title>` when done — not staging"

**If single workstream with worktree:**

Spawn one SWE agent with:
- The worktree path
- The feature branch name
- PR target: `<base-branch>` (staging or equivalent)
- The requirement file path

**If main folder:**

Spawn one SWE agent working in the current directory with the feature branch already checked out.

### Step 8 — Report

Once agents are spawned, report to the user:

```
## Started

Feature branch: feat/<kebab-feature-title>
Worktrees:
  <worktree-base>/feat-<kebab-feature-title>  →  main feature
  <worktree-base>/<stream-1>  →  stream 1 (PR → feat/<kebab-feature-title>)
  <worktree-base>/<stream-2>  →  stream 2 (PR → feat/<kebab-feature-title>)

Agents running. Run /cass:pr when ready to create a PR from any branch.
Run /cass:clean-wt to remove worktrees after PRs are merged.
```

## Constraints

- Never create worktrees without user approval
- Never start implementing without the user approving the plan
- Always save worktree preference to `.claude/settings.local.json`
- Sub-branch PRs always target the main feature branch, not staging/master
- The main feature branch PR targets staging/master
