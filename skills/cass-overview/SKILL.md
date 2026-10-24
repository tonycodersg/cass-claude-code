---
name: cass-overview
description: Overview of the cass plugin — what commands are available, what agents do what, and how the plan → build → review pipeline works. Load when the user asks what cass can do, how to use a cass command, which agent to invoke, or how the dev workflow fits together.
version: 1.0.0
---

# Cass Plugin Overview

Cass is a structured **plan → architect → build → review** pipeline for Claude Code. It ships slash commands, autonomous agents, and hooks that wire together a repeatable engineering workflow.

## Commands

| Command | What it does |
|---|---|
| `/cass:plan` | PO workflow — take a requirement, investigate risks, present a structured plan, save as Jira ticket or MD file. Pass `--qa` to auto-generate TDD stubs. |
| `/cass:dev-feat` | SWE/SA workflow — read a requirement or ticket, write an implementation plan, set up worktrees, spawn SWE agents to build in parallel. |
| `/cass:review` | Review a PR or current branch for logic, performance, code quality, and plan compliance. Add `--security` for an OWASP/SAST scan. |
| `/cass:pr` | Create a PR from the current branch. Auto-spawns QA verification and pr-reviewer in parallel after creation. |
| `/cass:qa` | Run test coverage audit, write missing tests, or generate TDD stubs from a plan file. |
| `/cass:security` | Standalone security scan — semgrep + OWASP Top 10 review of the current diff. |
| `/cass:commit` | Commit staged changes with a conventional commit message. |
| `/cass:onboard` | Generate a developer onboarding guide for the current repo as `.cass/ONBOARDING.md`. |
| `/cass:init` | Initialize cass config for the current project. |
| `/cass:doctor` | Check that required tools (gh, git, etc.) are present and configured. |
| `/cass:clean-wt` | Remove merged or stale git worktrees. |
| `/cass:eject` | Remove cass from the current project. |

## Agents

Agents are spawned automatically when context matches — you rarely invoke them directly.

| Agent | Role |
|---|---|
| `planner` | Enters plan mode, asks clarifying questions, writes a plan MD file. |
| `swe` | Reads a plan file, sets up a git branch/worktree, implements, raises a PR. |
| `sa` | Solution architect — reviews plan or implementation against SOLID/DRY/YAGNI/CAP, proposes design improvements. |
| `qa` | Writes tests (post-implementation), TDD stubs (pre-implementation), or verifies PR coverage. |
| `pr-reviewer` | Reads the diff and plan, surfaces issues by P1/P2/P3 priority. |
| `security` | SAST + OWASP Top 10 review of the diff, outputs findings in the same format as pr-reviewer. |
| `devops` | Writes Dockerfiles, Docker Compose, CI/CD pipelines for .NET, Node, Python, and other stacks. |
| `onboarder` | Reads repo context and writes `.cass/ONBOARDING.md`. |

## Typical Workflow

```
/cass:plan  →  /cass:dev-feat  →  /cass:review  →  /cass:pr
```

1. **Plan** — clarify requirements, assess risks, produce a plan MD or Jira ticket
2. **Dev-feat** — implement from the plan in a worktree, with SA and SWE agents collaborating
3. **Review** — pr-reviewer checks the diff against the plan; add `--security` for a security pass
4. **PR** — open the PR; QA verification and review run automatically in parallel
