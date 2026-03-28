# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

## [0.4.0] - 2026-03-28

### Added

- `agents/sa`: new Solution Architect agent (Sonnet) — reviews feature plans and implementations against SOLID, CAP, DRY, YAGNI, Separation of Concerns, Law of Demeter, and clean code principles; appends `## Architecture Notes` to plan files pre-implementation and produces a prioritised findings report post-implementation
- `commands/plan-task`: new `/cass:plan-task` command — full end-to-end pipeline: requirement clarification (Haiku) → SA plan review → SWE implementation → SA code review → PR to `staging`
- `skills/plan-task`: auto-invoked skill that triggers the same pipeline when the user says "plan this feature", "help me plan", or invokes `/plan-task`

### Changed

- `swe`: after implementation verification, now asks the user if they want an SA review before creating a PR; fixes SA must-fix items and embeds the full SA findings in the PR description
- `swe`: PR target branch changed to `staging`; PR body now includes an **Architecture Review** section and **Implementation Steps** section alongside the existing What / Why / How / Checklist structure
- `commands/plan-task`: after plan approval, SA agent is automatically spawned to review and enrich the plan before SWE starts — no manual step required
- `README`: updated workflow diagram, agent descriptions, commands, and skills sections to reflect the new pipeline

## [0.3.0] - 2026-03-07

### Added

- `README`: Prerequisites section covering `uv`/`uvx` installation and how to verify Serena starts
- `.mcp.json`: Atlassian HTTP MCP server and Serena stdio MCP server configurations with descriptions
- `agents/devops`: new agent for writing Dockerfiles, Docker Compose, VPS deployment scripts, and CI/CD pipelines (.NET, Node.js, Python, Go)

## [0.2.0] - 2026-03-06

### Added

- `planner`: after plan is confirmed, splits complex work into parallel/sequential task groups and adds a **Task Breakdown** section to the plan file
- `planner`: offers to create tickets in Jira, GitHub Issues, or GitLab Issues via MCP after the plan is written; falls back to formatted text if the MCP tool is unavailable
- `swe`: accepts Jira, GitHub, GitLab, and Linear ticket references as input; fetches ticket details via MCP before starting implementation

### Changed

- `commands/cass-init.md` renamed to `commands/init.md` — command is now `/cass:init`

## [0.1.0] - 2026-03-06

### Added

**Agents**
- `planner` (haiku) — plan mode workflow: fetches Jira tickets via MCP, discovers project conventions, iterates with the user until the plan is confirmed, writes a structured md file, then offers to hand off to the `swe` agent
- `swe` (sonnet) — implements from a plan md file: sets up a git branch and worktree (with staging option), builds a task list, commits using the cass semantic template, verifies with build/lint/test, then pushes and creates a PR using the cass PR template
- `pr-reviewer` (sonnet) — reviews the diff against the plan, surfaces issues grouped by P1/P2/P3 priority, and applies fixes on user direction

**Commands**
- `init (`/cass:init`)` — initialises a project: generates `.claude/` via `/init`, copies `cass-.gitmessage` commit template and `.github/cass-pull_request_template.md` PR template (idempotent, skips existing files)

**Assets**
- `assets/commit-template/.gitmessage` — semantic commit format (`<type>(<scope>): <summary>`) with `Co-authored-by: Claude` pre-filled
- `assets/pr-template/pull_request_template.md` — What / Why / How / Checklist PR structure

**Plugin scaffold**
- `.claude-plugin/plugin.json` manifest
- Example command and skill stubs

[Unreleased]: https://github.com/tonycodersg/cass-claude-code/compare/v0.4.0...HEAD
[0.4.0]: https://github.com/tonycodersg/cass-claude-code/compare/v0.3.0...v0.4.0
[0.3.0]: https://github.com/tonycodersg/cass-claude-code/compare/v0.2.0...v0.3.0
[0.2.0]: https://github.com/tonycodersg/cass-claude-code/compare/v0.1.0...v0.2.0
[0.1.0]: https://github.com/tonycodersg/cass-claude-code/releases/tag/v0.1.0
