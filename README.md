# cass

A Claude Code plugin that brings a structured plan → architect → build → review workflow to any project.

## Workflow

```
/cass:init               set up the project (once)
      ↓
/cass:plan-task          clarify requirements, write a plan md file  [haiku]
      ↓
sa agent                 review plan for SOLID/CAP/clean code, update plan with Architecture Notes  [sonnet]
      ↓
swe agent                implement from the updated plan, branch + worktree, commit, push  [sonnet]
      ↓
sa agent                 review implementation diff, produce prioritised findings  [sonnet]
      ↓
swe agent                fix SA must-fix items, create PR → staging with SA review in description  [sonnet]
```

> The `planner` agent is also available for standalone planning sessions without the full `/cass:plan-task` pipeline.

## Agents

### planner — `haiku`

Triggered when you ask to plan a feature or task (standalone use).

- Enters plan mode immediately — no code is written
- Fetches Jira tickets via MCP if a ticket reference is provided
- Discovers project conventions (`CLAUDE.md`, `instructions/`, `docs/`, `README.md`) before asking questions
- Iterates with clarifying questions until the plan is unambiguous
- Writes a structured plan file (Goal / Background / Scope / Approach / Open Questions / Success Criteria)
- Splits complex plans into parallel/sequential Task Breakdown groups
- Offers to create tickets in Jira, GitHub Issues, or GitLab Issues after writing the plan
- Offers to hand off to the `swe` agent when done

### sa — `sonnet`

Triggered automatically by `/cass:plan-task` (pre-implementation) and by the `swe` agent after implementation, or directly when you ask for an architecture or SA review.

**Pre-implementation (plan review)**
- Reads the plan file and project conventions
- Evaluates proposed design against SOLID, CAP, DRY, YAGNI, Separation of Concerns, Law of Demeter, and clean code principles
- Flags violations with principle name, location, and a concrete fix
- Appends an `## Architecture Notes` section directly to the plan file so the SWE agent has the corrected spec before writing any code

**Post-implementation (code review)**
- Diffs the branch against its base
- Reviews for architecture violations, clean code issues, and distributed systems concerns
- Reports findings grouped by priority:
  - **Must address** — correctness, security, data-loss risk
  - **Should address** — performance, logic gaps, missing error handling
  - **Consider** — style, naming, minor improvements
- Outputs a PR-ready findings block that the SWE agent embeds in the PR description
- Applies fixes only when explicitly directed

### swe — `sonnet`

Triggered when you want to implement from a plan file (usually handed off from `/cass:plan-task`).

- Reads the plan (including SA Architecture Notes) and resolves any blocking open questions
- Reads project conventions first
- Asks whether to start from `staging`, current branch, or no worktree — creates branch + worktree accordingly
- Builds a task list via TodoWrite and works through it, spawning sub-agents for parallel tasks
- Commits each logical unit using `cass-.gitmessage` (semantic format + `Co-authored-by: Claude`)
- Verifies with build / lint / test commands from `CLAUDE.md` or `README.md`
- After verification, asks if you want an SA review before the PR
- Fixes SA must-fix items; asks about should-fix items
- Creates a PR targeting **`staging`** with: What / Why / How / SA review findings / Implementation steps / Checklist

### pr-reviewer — `sonnet`

Triggered when you want a dedicated code review pass after implementation.

- Reads the plan file as the source of truth
- Gets the full diff against the base branch
- Reviews for logic, performance, syntax/quality, and plan compliance
- Reports findings grouped by priority: P1 / P2 / P3 / Plan compliance
- Applies fixes only when you explicitly direct it

### devops — `sonnet`

Triggered when you need infrastructure, containerisation, or CI/CD work.

- Detects project stack (.NET / Node.js / Python / Go)
- Produces production-ready multi-stage Dockerfiles
- Writes Docker Compose configurations with health checks
- Creates Linux VPS deployment scripts
- Sets up CI/CD pipelines (GitHub Actions, GitLab CI, Bitbucket, Jenkins)
- Generates `.env.example` files and deployment documentation

## Commands

### `/cass:plan-task [description or ticket]`

Full end-to-end planning → architect → build pipeline. Run this instead of invoking the planner agent manually when you want the complete workflow.

1. **Requirement review** (Haiku) — clarifies requirements, asks questions, writes a plan md file
2. Asks for your approval before saving or doing anything
3. **SA review** (Sonnet) — reviews the plan, appends Architecture Notes
4. **SWE implementation** (Sonnet) — implements from the SA-enriched plan, verifies, runs SA post-review, creates PR → `staging`

### `/cass:init`

Initialises a project for use with this plugin. Run once per project.

1. Checks for an existing `.claude/` — stops if found (nothing is overwritten)
2. Runs `/init` to generate `.claude/` and `CLAUDE.md`
3. Copies `assets/commit-template/.gitmessage` → `cass-.gitmessage` and configures `git config commit.template`
4. Copies `assets/pr-template/pull_request_template.md` → `.github/cass-pull_request_template.md`

Each copy step is idempotent — skipped if the file already exists.

## Skills

### `plan-task`

Auto-invoked when you type `/plan-task`, "plan this feature", "help me plan", or reference a ticket and want a plan written first. Runs the same workflow as `/cass:plan-task`.

## Assets

| File | Copied to | Purpose |
|------|-----------|---------|
| `assets/commit-template/.gitmessage` | `cass-.gitmessage` | Semantic commit format with Claude co-author |
| `assets/pr-template/pull_request_template.md` | `.github/cass-pull_request_template.md` | What / Why / How / Checklist PR body |

## Prerequisites

### Python, uv, and uvx

Serena (the semantic code navigation MCP) runs via `uvx`, which ships with `uv`.

**Install `uv` (includes `uvx`):**

```bash
curl -LsSf https://astral.sh/uv/install.sh | sh
```

Restart your shell or run `source $HOME/.local/bin/env` to activate it.

Verify:

```bash
uv --version
uvx --version
```

`uv` manages its own Python — no separate Python install is required. If you need a specific version:

```bash
uv python install 3.12
```

### Verify Serena starts

Run this once to confirm Serena works before starting a session:

```bash
uvx --from git+https://github.com/oraios/serena serena start-mcp-server \
  --context claude-code \
  --project-from-cwd \
  --open-web-dashboard False
```

If it starts without errors, Claude Code will launch it automatically via `.mcp.json` on each session.

## Installation

```bash
# Clone the plugin
git clone git@github.com:tonycodersg/cass-claude-code.git ~/.claude/plugins/cass
```

Then in any project:

```bash
/cass:init
```

To load for a single session without installing globally:

```bash
claude --plugin-dir ~/.claude/plugins/cass
```
