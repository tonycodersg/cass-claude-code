# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

## [0.1.0] - 2026-03-06

### Added

**Agents**
- `planner` (haiku) — plan mode workflow: fetches Jira tickets via MCP, discovers project conventions, iterates with the user until the plan is confirmed, writes a structured md file, then offers to hand off to the `swe` agent
- `swe` (sonnet) — implements from a plan md file: sets up a git branch and worktree (with staging option), builds a task list, commits using the cass semantic template, verifies with build/lint/test, then pushes and creates a PR using the cass PR template
- `pr-reviewer` (sonnet) — reviews the diff against the plan, surfaces issues grouped by P1/P2/P3 priority, and applies fixes on user direction

**Commands**
- `cass-init` — initialises a project: generates `.claude/` via `/init`, copies `cass-.gitmessage` commit template and `.github/cass-pull_request_template.md` PR template (idempotent, skips existing files)

**Assets**
- `assets/commit-template/.gitmessage` — semantic commit format (`<type>(<scope>): <summary>`) with `Co-authored-by: Claude` pre-filled
- `assets/pr-template/pull_request_template.md` — What / Why / How / Checklist PR structure

**Plugin scaffold**
- `.claude-plugin/plugin.json` manifest
- Example command and skill stubs

[Unreleased]: https://github.com/tonycodersg/cass-claude-code/compare/v0.1.0...HEAD
[0.1.0]: https://github.com/tonycodersg/cass-claude-code/releases/tag/v0.1.0
