# cass

A Claude Code plugin that brings a structured plan → build → review workflow to any project.

## Workflow

```
/cass:init          set up the project (once)
      ↓
planner agent            clarify requirements, write a plan md file
      ↓
swe agent                implement from the plan, branch + worktree, commit, push, PR
      ↓
pr-reviewer agent        review diff against plan, surface issues by priority
```

## Agents

### planner — `haiku`

Triggered when you ask to plan a feature or task.

- Enters plan mode immediately — no code is written
- Fetches Jira tickets via MCP if a ticket reference is provided
- Discovers project conventions (`CLAUDE.md`, `instructions/`, `docs/`, `README.md`) before asking questions
- Iterates with clarifying questions until the plan is unambiguous
- Writes a structured plan file (Goal / Background / Scope / Approach / Open Questions / Success Criteria)
- Saves to `instructions/`, `docs/plans/`, or `.claude/plans/` based on what exists in the project
- Offers to hand off to the `swe` agent when done

### swe — `sonnet`

Triggered when you want to implement from a plan file.

- Reads the plan and resolves any blocking open questions before starting
- Reads project conventions first
- Asks whether to start from `staging`, current branch, or no worktree — creates branch + worktree accordingly
- Builds a task list via TodoWrite and works through it
- Commits each logical unit using `cass-.gitmessage` (semantic format + `Co-authored-by: Claude`)
- Verifies with build / lint / test commands from `CLAUDE.md` or `README.md`
- Pushes and creates a PR using `.github/cass-pull_request_template.md` once you confirm

### pr-reviewer — `sonnet`

Triggered when you want to review implementation changes before merging.

- Reads the plan file as the source of truth
- Gets the full diff against the base branch
- Reviews for logic, performance, syntax/quality, and plan compliance
- Reports findings grouped by priority:
  - **P1** — must fix (correctness, security, data loss)
  - **P2** — should fix (performance, logic gaps, missing error handling)
  - **P3** — consider (style, naming, minor improvements)
  - **Plan compliance** — checklist of success criteria met / not met
- Applies fixes only when you explicitly direct it

## Commands

### `/cass:init`

Initialises a project for use with this plugin. Run once per project.

1. Checks for an existing `.claude/` — stops if found (nothing is overwritten)
2. Runs `/init` to generate `.claude/` and `CLAUDE.md`
3. Copies `assets/commit-template/.gitmessage` → `cass-.gitmessage` and configures `git config commit.template`
4. Copies `assets/pr-template/pull_request_template.md` → `.github/cass-pull_request_template.md`

Each copy step is idempotent — skipped if the file already exists.

## Assets

| File | Copied to | Purpose |
|------|-----------|---------|
| `assets/commit-template/.gitmessage` | `cass-.gitmessage` | Semantic commit format with Claude co-author |
| `assets/pr-template/pull_request_template.md` | `.github/cass-pull_request_template.md` | What / Why / How / Checklist PR body |

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
