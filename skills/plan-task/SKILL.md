---
name: plan-task
description: Use this skill when the user invokes /plan-task, /cass:plan-task, asks to "plan a task", "plan this feature", "help me plan", or wants to think through requirements before implementing. Enters plan mode, reviews requirements using Haiku, asks clarifying questions, writes a detailed plan with SWE agent handoff notes, then (only on user approval) saves the plan to docs/ and hands off to the SWE agent (Sonnet) for implementation.
version: 1.0.0
---

# Plan Task Skill

This skill activates the structured planning workflow. It is the same workflow driven by the `/cass:plan-task` command — use whichever entry point was triggered.

## When This Skill Applies

- User types `/plan-task` or `/cass:plan-task`
- User says "plan this feature", "help me plan", "I want to plan before we start", "let's plan it out"
- User references a Jira ticket or GitHub issue and wants a plan written before implementation begins

## Workflow

Follow these steps in order. **Do not write code or modify any files until Step 9 (user approval).**

### 1 — Enter plan mode immediately

No implementation actions of any kind.

### 2 — Fetch ticket (if referenced)

If the request contains a Jira ticket ID (e.g. `PROJ-123`) or GitHub issue reference (`#123`), fetch it via the appropriate MCP tool first. Use its content as primary input.

### 3 — Read project context

Before asking the user anything, look for and read: `CLAUDE.md`, `README.md`, `instructions/`, `docs/`, `.claude/`, `.cursorrules`. Use this to understand conventions and constraints the plan must respect.

### 4 — Summarize the request

Restate in your own words:
- **Goal** — what we're trying to achieve
- **Scope** — what's in and out of scope
- **Success criteria** — how we know it's done

### 5 — Ask clarifying questions

Ask all ambiguous or missing information in a single numbered list. Skip if nothing is unclear.

### 6 — Iterate until unambiguous

Confirm answers, ask follow-up if needed. Repeat until the plan is clear.

### 7 — Write the plan

Structured markdown with: Goal / Background / Scope / Approach / Open Questions / Success Criteria.

Add a **Task Breakdown** section if work can be parallelized — label which tasks can run in parallel (sub-agents) and which have dependencies. Append a footer:

> *Implementation will be handled by the SWE agent (Sonnet model).*

### 8 — Ask for approval

Present the plan and ask the user to approve before saving or implementing anything.

### 9 — Save the plan (on approval only)

- Create `docs/` in the project root if it doesn't exist
- Save to `docs/<kebab-feature>_<YYYY-MM-DD>.md`

### 10 — Hand off to SWE agent (Sonnet)

Invoke the `swe` agent with the saved plan file path. The SWE agent implements all tasks, spawns sub-agents for parallel work, and opens a PR when done.

## Constraints

- Haiku model handles planning; SWE agent (Sonnet) handles implementation
- Nothing is written or executed before user approval
- The plan must be actionable by someone who wasn't in the conversation
