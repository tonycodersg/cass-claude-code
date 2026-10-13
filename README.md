# cass

> A Claude Code **global plugin** that brings a structured **plan → build → review** pipeline to any project.
> Role-split commands for POs and developers. Parallel agents work in isolated worktrees — your main branch never changes.
> Hooks run automatically to guard against destructive commands and keep Claude context-aware.
> Each repo gets its own `.cass/` customization layer — override commands, agents, hooks, and templates, committed alongside your code.

**Latest stable: [v0.7.0](https://github.com/tonycodersg/cass-claude-code/releases/tag/v0.7.0)**

---

## Install

### Clone (recommended)

```bash
# Latest stable (v0.7.0)
git clone --branch v0.7.0 https://github.com/tonycodersg/cass-claude-code ~/.claude/plugins/cass

# Or track latest
git clone https://github.com/tonycodersg/cass-claude-code ~/.claude/plugins/cass
```

Loads automatically in every Claude Code session. No restart needed.

### Marketplace

```bash
/plugin marketplace add tonycodersg/cass-claude-code
/plugin install cass@cass-marketplace --global
/reload-plugins
```

> Requires an SSH key added to GitHub. See the [GitHub SSH guide](https://docs.github.com/en/authentication/connecting-to-github-with-ssh).

### Per session

```bash
claude --plugin-dir /path/to/cass-claude-code
```

---

## Quick start

```bash
# 1. Set up cass in your project
/cass:init my-app

# 2. Verify your environment
/cass:doctor
```

---

## How it works

```
                    ┌─────────────────────────────────────────┐
                    │               your project               │
                    │                                          │
     PO             │  /cass:plan    requirement → plan → ticket
                    │
     Dev            │  /cass:dev-feat  plan → branch + worktree → agents
                    │  /cass:pr        worktree → PR (auto-targets base)
                    │  /cass:review    pr-reviewer agent → P1/P2/P3 findings
                    │  /cass:clean-wt  remove merged worktrees
                    └─────────────────────────────────────────┘
```

**Worktree model** — agents work in isolation, your main folder never changes:

```
my-repo/                      ← stays on main (merge & test only)
my-repo-agent-works/
  ├── feat-user-auth/         ← created automatically by /cass:dev-feat
  ├── feat-user-auth-api/     ← parallel agent 1  →  PR to feat-user-auth
  └── feat-user-auth-ui/      ← parallel agent 2  →  PR to feat-user-auth
```

**Hooks** — active automatically, no setup:

```
PreToolUse   blocks destructive git commands (push --force, reset --hard, rm -rf …)
             → run  ! <cmd>  in terminal to override
Stop         nudges /cass:commit when working tree is dirty after Claude stops
Prompt       injects repo / branch / worktree context into every message
```

---

## Commands

| Command | Role | What it does |
|---|---|---|
| `/cass:init [project]` | Setup | Register project paths, copy templates, create worktree folder |
| `/cass:doctor` | Setup | Health check — tools, MCP servers, git config, project settings |
| `/cass:customize` | Setup | Scaffold `.cass/` override package for this repo |
| `/cass:plan [text or doc]` | PO | Requirement → risk-assessed plan → Jira / GitHub issue / MD file |
| `/cass:dev-feat [plan/ticket]` | Dev | Plan → feature branch + worktree → parallel SWE agents |
| `/cass:commit` | Dev | Stage changes, generate semantic message, commit with co-author |
| `/cass:pr` | Dev | Create PR from current worktree — auto-detects base branch |
| `/cass:review [PR or branch]` | Dev | Code review via pr-reviewer agent — P1 / P2 / P3 findings |
| `/cass:clean-wt` | Dev | List worktrees by project, pick to remove |
| `/cass:test` | Dev | 13-step smoke test of cass mechanics in an isolated temp repo |

---

## Customising cass

cass is a **global plugin** — it lives in `~/.claude/plugins/cass` and is shared across all your projects. Each repo can override any part of it without touching the plugin itself.

Run `/cass:customize` to scaffold the override package:

```
.claude/commands/             ← command overrides (Claude Code loads here natively)
  cass:pr.md                  ← this repo's version of /cass:pr
.cass/                        ← committed to your repo
  agents/                     ← agent overrides
    swe.md
  hooks/                      ← repo-specific hooks
    hooks.json
    scripts/
  pr-template.md              ← PR body template
  commit-template.md          ← commit message template
```

**Override a command:**
```bash
cp ~/.claude/plugins/cass/commands/pr.md .claude/commands/cass:pr.md
# edit .claude/commands/cass:pr.md — Claude Code uses this version for this project
```

**Override an agent:**
```bash
cp ~/.claude/plugins/cass/agents/swe.md .cass/agents/swe.md
```

**Add a repo-specific hook:**
Edit `.cass/hooks/hooks.json` — these run alongside the global plugin hooks.

Commit `.cass/` to version-control so your whole team gets the same overrides.

---

## Agents

| Agent | Model | Role |
|---|---|---|
| `planner` | haiku | Clarifies requirements, writes structured plan files |
| `sa` | sonnet | Architecture review — SOLID, CAP, clean code — pre or post implementation |
| `swe` | sonnet | Implements from plan, commits, creates PR |
| `pr-reviewer` | sonnet | Reviews diffs for logic, performance, and plan compliance |
| `devops` | sonnet | Dockerfiles, CI/CD pipelines, VPS deployment scripts |

---

## Prerequisites

| Tool | Required | Purpose |
|---|---|---|
| [Claude Code](https://claude.ai/code) | Yes | Runs the plugin |
| [GitHub CLI (`gh`)](https://cli.github.com) | Yes | PRs, issues, branch management |
| [uv / uvx](https://astral.sh/uv) | Yes | Launches Serena MCP for code intelligence |
| Atlassian MCP | Optional | Read and create Jira tickets from `/cass:plan` |

See [docs/TECHNICAL.md](docs/TECHNICAL.md) for full setup instructions.

---

## Update

**Clone:**
```bash
cd ~/.claude/plugins/cass && git pull
```

**Marketplace:**
```
/plugin update cass@cass-marketplace
/reload-plugins
```

---

## Docs

- [Technical reference](docs/TECHNICAL.md) — agents, command details, prerequisites, plugin structure
- [Changelog](CHANGELOG.md)
