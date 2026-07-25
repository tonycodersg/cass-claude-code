# cass

A Claude Code plugin that brings a structured plan → architect → build → review workflow to any project.

## Workflow

```
/cass:init [project]     set up the project — registers paths, safe to re-run for multiple projects
/cass:doctor             verify all tools and MCP servers are working
      ↓
/cass:plan               PO role — parallel SA+planner investigation, write requirement MD or Jira ticket  [haiku]
      ↓
/cass:dev-feat           SWE/SA role — implementation plan, worktree setup, spawn parallel agents  [sonnet]
      ↓
      ├── sub-agent 1    work in own worktree, PR → main feature branch
      └── sub-agent 2    work in own worktree, PR → main feature branch
      ↓
/cass:review             trigger pr-reviewer agent on any PR or current diff
      ↓
/cass:pr                 create final PR from main feature branch → staging
      ↓
/cass:clean-wt           clean up merged worktrees and branches
```

**Worktree model:**
```
my-repo/                          ← main folder (stays on main/staging — merge & test here)
  └── branch: main or staging

my-repo-agent-works/              ← worktree folder (agents work here, never touch main folder)
  ├── feat/<feature>/             ← main feature worktree
  ├── feat/<ticket>-api/          ← agent 1 sub-worktree → PR to feat/<feature>
  └── feat/<ticket>-ui/           ← agent 2 sub-worktree → PR to feat/<feature>
```

> `/cass:plan-task` is still available as a single-command alternative that combines planning and implementation in one step.

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

### `/cass:init [project name]`

Initialises a project for use with cass. Safe to run multiple times — re-running updates config without overwriting existing template files. Run once per project; multiple projects can be registered in the same repo.

Asks two setup questions:
- **Worktree folder path** — where feature branch worktrees are created. Default: `../<repo-name>-agent-works` (sibling folder next to the repo)
- **Main branch** — the branch this main repo folder stays on (for merging and testing only). Options: `main` (default), `staging`, or a custom name

Saves project config to `.claude/settings.local.json` under `cass.projects.<name>`:
```json
{
  "cass": {
    "projects": {
      "my-app": {
        "mainRepoPath": "/path/to/repo",
        "mainBranch": "main",
        "worktreePath": "/path/to/repo-agent-works"
      }
    }
  }
}
```

Then runs the original setup steps:
1. Generates `.claude/` and `CLAUDE.md` if not already present
2. Copies `assets/commit-template/.gitmessage` → `cass-.gitmessage` and configures `git config commit.template`
3. Copies `assets/pr-template/pull_request_template.md` → `.github/cass-pull_request_template.md`
4. Creates the worktree base folder if it doesn't exist

### `/cass:doctor`

Health check — verifies all tools, MCP servers, and project config are set up correctly. Run after install or when something isn't working.

Checks: git identity · commit template · PR template · `gh` install + auth · Serena MCP (`uvx` + package) · Atlassian MCP reachability · other MCP servers in `.mcp.json` · `cass.projects` config (main repo path, main branch, worktree path exists on disk).

Outputs a pass/warn/fail report with fix commands for anything missing.

### `/cass:plan [description or ticket]`

**PO role.** Spawns SA + planner agents in parallel to rapidly investigate a requirement, then iterates with you until everything is clear. Writes a structured requirement MD file or creates a Jira ticket.

- Default model: Haiku (fast). Type "use sonnet" to switch.
- SA agent investigates technical constraints; planner agent identifies scope gaps and open questions — both run simultaneously
- On approval: saves to `docs/<feature>_<date>.md` and/or creates Jira ticket via Atlassian MCP

### `/cass:dev-feat [path or ticket]`

**SWE/SA role.** Reads a requirement MD or ticket, enters plan mode, writes an implementation plan with test coverage, and sets up the git/worktree structure.

- Reads `cass.projects` from `.claude/settings.local.json` (set by `/cass:init`) — no worktree questions asked at runtime
- If one project is configured, uses it automatically; if multiple, asks which one
- If init has not been run, stops and prompts you to run `/cass:init <project-name>` first
- Identifies parallel workstreams and asks whether to split into sub-agents
- Creates feature branches from `mainBranch` and worktrees under `worktreePath`
- Sub-task branches target the main feature branch (not the main branch); each agent creates its own PR

### `/cass:pr`

Creates a PR from the current branch. Auto-detects the correct target:
- Sub-task branch → PR targets the main feature branch
- Main feature branch → PR targets `staging`

Optionally triggers SA review before creating. Includes What / Why / How / SA Review / Implementation Steps / Checklist.

### `/cass:review [PR number or URL]`

Triggers the `pr-reviewer` agent on a PR or the current branch diff. Reports findings grouped as P1 (must fix) / P2 (should fix) / P3 (consider) / Plan Compliance. Never applies fixes without your direction.

### `/cass:clean-wt`

Scans all cass-managed worktrees, checks PR merge status via `gh`, and removes worktrees + branches for merged PRs. Asks before removing anything with no PR or uncertain state.

Reads `worktreePath` from `cass.projects` in `.claude/settings.local.json`. If multiple projects are configured, asks which one to clean. Pass a path as argument to override: `/cass:clean-wt /path/to/worktrees`.

### `/cass:plan-task [description or ticket]`

Legacy single-command alternative that combines planning and implementation in one step. Still available — useful when you want the full pipeline without the role split.

## Skills

### `plan-task`

Auto-invoked when you type `/plan-task`, "plan this feature", "help me plan", or reference a ticket and want a plan written first. Runs the same workflow as `/cass:plan-task`.

## Assets

| File | Copied to | Purpose |
|------|-----------|---------|
| `assets/commit-template/.gitmessage` | `cass-.gitmessage` | Semantic commit format with Claude co-author |
| `assets/pr-template/pull_request_template.md` | `.github/cass-pull_request_template.md` | What / Why / How / Checklist PR body |

## Prerequisites

Install these once before using cass. Run `/cass:doctor` after setup to verify everything is wired up.

---

### 1. Claude Code

The CLI that runs this plugin.

**macOS / Linux:**
```bash
npm install -g @anthropic-ai/claude-code
```

**Verify:**
```bash
claude --version
```

> Requires Node.js 18+. See [nodejs.org](https://nodejs.org) if `node` is not installed.

---

### 2. GitHub CLI (`gh`)

Used by cass to create issues, branches, PRs, and check merge status.

**macOS:**
```bash
brew install gh
```

**Linux:**
```bash
sudo apt install gh        # Debian/Ubuntu
sudo dnf install gh        # Fedora
```

**Windows:**
```bash
winget install GitHub.cli
```

**Authenticate after install:**
```bash
gh auth login
```

**Verify:**
```bash
gh auth status
```

---

### 3. uv + uvx (for Serena)

Serena (semantic code navigation MCP) is launched via `uvx`, which ships with `uv`.

**macOS / Linux:**
```bash
curl -LsSf https://astral.sh/uv/install.sh | sh
```

**Windows:**
```powershell
powershell -ExecutionPolicy ByPass -c "irm https://astral.sh/uv/install.ps1 | iex"
```

Restart your shell, or run `source $HOME/.local/bin/env` to activate it immediately.

**Verify:**
```bash
uv --version
uvx --version
```

> `uv` manages its own Python — no separate Python install needed.

---

### 4. Serena MCP

Verify Serena launches correctly before your first session:

```bash
uvx --from git+https://github.com/oraios/serena serena start-mcp-server \
  --context claude-code \
  --project-from-cwd \
  --open-web-dashboard False
```

If it starts without errors, Claude Code will launch it automatically via `.mcp.json` on every session. Press `Ctrl+C` to stop it — you don't need to keep it running manually.

---

### 5. Atlassian MCP (optional — for Jira integration)

Required only if you want `/cass:plan` and the planner agent to read and create Jira tickets.

1. Generate an Atlassian API token at [id.atlassian.com/manage-profile/security/api-tokens](https://id.atlassian.com/manage-profile/security/api-tokens)
2. Add it to your shell profile:

```bash
export ATLASSIAN_API_TOKEN=your_token_here
export ATLASSIAN_EMAIL=you@example.com
export ATLASSIAN_DOMAIN=yourcompany.atlassian.net
```

---

### Quick health check

After installing everything, run `/cass:doctor` inside any Claude Code session with cass loaded to verify all tools are configured correctly:

```
/cass:doctor
```

It checks git identity, `gh` auth, Serena connectivity, Atlassian MCP, and project-level setup, then reports pass/warn/fail with fix commands for anything missing.

## Installation

### Option 1 — Plugin marketplace (recommended)

In any Claude Code session, run:

```
/plugin marketplace add tonycodersg/cass-claude-code
/plugin install cass@cass-marketplace
```

Then initialise the plugin in your project:

```
/cass:init
```

> **How to find this plugin:** search for `cass-claude-code` on [github.com/tonycodersg](https://github.com/tonycodersg/cass-claude-code) or copy the install commands above directly into Claude Code.

### Option 2 — Official Anthropic marketplace

> Coming soon — pending submission at [claude.ai/settings/plugins/submit](https://claude.ai/settings/plugins/submit)

Once listed, install with:

```
/plugin install cass@claude-plugins-official
```

### Option 3 — Local development

Load for a single session without installing:

```bash
claude --plugin-dir /path/to/cass-claude-code
```

Or symlink globally so it loads in every session:

```bash
ln -s /path/to/cass-claude-code ~/.claude/plugins/cass
```
