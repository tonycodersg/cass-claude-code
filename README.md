# cass

A Claude Code plugin that brings a structured **plan → build → review** workflow to any project, with role-split commands for POs and developers.

## Install

### Option 1 — Plugin marketplace (recommended)

First, ensure your SSH key is added to GitHub:
```bash
ssh -T git@github.com
# Hi <username>! You've successfully authenticated
```

> No SSH key? See the [GitHub SSH setup guide](https://docs.github.com/en/authentication/connecting-to-github-with-ssh).

Then in any Claude Code session:
```
/plugin marketplace add tonycodersg/cass-claude-code
/plugin install cass@cass-marketplace --global
/reload-plugins
```

### Option 2 — Clone

```bash
git clone https://github.com/tonycodersg/cass-claude-code ~/.claude/plugins/cass
```

### Option 3 — Per session

```bash
claude --plugin-dir /path/to/cass-claude-code
```

---

## Update

**Marketplace:**
```
/plugin update cass@cass-marketplace
/reload-plugins
```

**Clone:**
```bash
cd ~/.claude/plugins/cass && git pull
```

---

## Quick start

```bash
# 1. Set up cass in your project
/cass:init <project-name>

# 2. Verify everything is working
/cass:doctor
```

---

## Workflow

```
PO
  /cass:plan [text or doc]     investigate requirement → risks + plan → save as ticket or MD

Dev
  /cass:dev-feat [plan/ticket] read plan → dev questions → implementation → worktrees + agents
  /cass:pr                     from inside worktree → PR to staging (confirm target)
  /cass:review [PR or branch]  code review via pr-reviewer agent
  /cass:clean-wt               list worktrees by project → pick to remove
```

**Folder model:**
```
my-repo/                        ← main folder (stays on main/staging — merge & test only)
my-repo-agent-works/
  ├── feat-user-auth/           ← main feature worktree
  ├── feat-user-auth-api/       ← agent 1 → PR to feat-user-auth
  └── feat-user-auth-ui/        ← agent 2 → PR to feat-user-auth
```

---

## Commands

| Command | Role | Description |
|---|---|---|
| `/cass:init [project]` | Setup | Register project paths and main branch |
| `/cass:doctor` | Setup | Health check — tools, MCP, project config |
| `/cass:plan [text or doc]` | PO | Requirement → risk-assessed plan → ticket or MD |
| `/cass:dev-feat [plan/ticket]` | Dev | Plan → worktrees → parallel SWE agents |
| `/cass:pr` | Dev | Create PR from current worktree |
| `/cass:review [PR or branch]` | Dev | Code review via pr-reviewer agent |
| `/cass:clean-wt` | Dev | Remove merged worktrees |
| `/cass:test` | Dev | Smoke test cass mechanics |
| `/cass:plan-task` | Dev | Single-command plan + implement (legacy) |

---

## Prerequisites

| Tool | Required | Purpose |
|---|---|---|
| [Claude Code](https://claude.ai/code) | Yes | Runs the plugin |
| [GitHub CLI (`gh`)](https://cli.github.com) | Yes | Creates PRs, issues, checks branches |
| [uv / uvx](https://astral.sh/uv) | Yes | Launches Serena MCP |
| Atlassian MCP | Optional | Reads and creates Jira tickets |

See [docs/TECHNICAL.md](docs/TECHNICAL.md) for full setup instructions.

---

## Documentation

- [Technical reference](docs/TECHNICAL.md) — agents, command details, prerequisites setup, plugin structure
- [Changelog](CHANGELOG.md)
