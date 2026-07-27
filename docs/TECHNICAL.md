# cass — Technical Reference

Full documentation for agents, commands, prerequisites, and plugin structure.

---

## Prerequisites

### 1. Claude Code

```bash
npm install -g @anthropic-ai/claude-code
claude --version
```

> Requires Node.js 18+. See [nodejs.org](https://nodejs.org).

### 2. GitHub CLI (`gh`)

Used to create issues, branches, PRs, and check merge status.

```bash
# macOS
brew install gh

# Debian/Ubuntu
sudo apt install gh

# Fedora
sudo dnf install gh

# Windows
winget install GitHub.cli
```

Authenticate:
```bash
gh auth login
gh auth status
```

### 3. uv + uvx (for Serena MCP)

```bash
# macOS / Linux
curl -LsSf https://astral.sh/uv/install.sh | sh

# Windows
powershell -ExecutionPolicy ByPass -c "irm https://astral.sh/uv/install.ps1 | iex"
```

Restart your shell, then verify:
```bash
uv --version
uvx --version
```

Verify Serena starts:
```bash
uvx --from git+https://github.com/oraios/serena serena start-mcp-server \
  --context claude-code \
  --project-from-cwd \
  --open-web-dashboard False
```

Press `Ctrl+C` to stop — Claude Code launches it automatically via `.mcp.json` each session.

### 4. Atlassian MCP (optional — Jira integration)

Required for `/cass:plan` to read and create Jira tickets.

1. Generate an API token at [id.atlassian.com/manage-profile/security/api-tokens](https://id.atlassian.com/manage-profile/security/api-tokens)
2. Add to your shell profile:

```bash
export ATLASSIAN_API_TOKEN=your_token_here
export ATLASSIAN_EMAIL=you@example.com
export ATLASSIAN_DOMAIN=yourcompany.atlassian.net
```

### SSH key (for marketplace install)

```bash
# Generate if needed
ssh-keygen -t ed25519 -C "you@example.com"

# Copy public key and add to github.com → Settings → SSH keys
cat ~/.ssh/id_ed25519.pub

# Test
ssh -T git@github.com
```

---

## Agents

### planner — `haiku`

Triggered when you ask to plan a feature or task.

- Enters plan mode immediately — no code written
- Fetches Jira/GitHub tickets via MCP if a ref is provided
- Reads project conventions (`CLAUDE.md`, `instructions/`, `docs/`) before asking questions
- Iterates with clarifying questions until the plan is unambiguous
- Writes a structured plan file (Goal / Background / Scope / Approach / Success Criteria)
- Splits complex plans into parallel/sequential Task Breakdown groups
- Offers to create tickets in Jira, GitHub Issues, or GitLab Issues

### sa — `sonnet`

Solution Architect agent. Triggered by `/cass:plan` (pre-implementation) and optionally by `/cass:pr` (post-implementation).

**Pre-implementation**
- Reads the plan and project conventions
- Evaluates design against SOLID, CAP, DRY, YAGNI, Separation of Concerns, Law of Demeter, clean code
- Writes `### Technical Context` into the saved plan so dev-feat can skip re-investigation

**Post-implementation**
- Diffs branch against its base
- Reports findings as: Must address / Should address / Consider
- Applies fixes only when explicitly directed

### swe — `sonnet`

Implements from a plan file. Spawned by `/cass:dev-feat`.

- Reads plan (including Technical Context) — skips codebase re-investigation if present
- Raises dev questions before writing the implementation plan
- Builds a TodoWrite task list and works through it
- Commits using `cass-.gitmessage` (semantic format + `Co-authored-by: Claude`)
- Spawns sub-agents for parallel workstreams
- Verifies with build / lint / test commands from `CLAUDE.md` or `README.md`
- Creates PR with: What / Why / How / Risks / Test Coverage / SA Review / Implementation Steps / Checklist / Claude session ID

### pr-reviewer — `sonnet`

Triggered by `/cass:review`.

- Reads the plan as source of truth
- Diffs against base branch
- Reports findings as P1 (must fix) / P2 (should fix) / P3 (consider) / Plan Compliance
- Applies fixes only on explicit direction

### devops — `sonnet`

Triggered for infrastructure, containerisation, or CI/CD work.

- Detects stack (.NET / Node.js / Python / Go)
- Produces multi-stage Dockerfiles, Docker Compose, `.env.example`
- Creates VPS deployment scripts
- Sets up CI/CD pipelines (GitHub Actions, GitLab CI, Bitbucket, Jenkins)

---

## Commands

### `/cass:init [project name]`

Sets up a project. Safe to re-run — updates config, skips existing template files.

**Asks:**
1. Worktree folder path (default: `../<repo>-agent-works`)
2. Main branch (`main` default, `staging`, or custom)

**Saves to `.claude/settings.local.json`:**
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

**Also:**
- Generates `.claude/` and `CLAUDE.md` if missing
- Copies `cass-.gitmessage` commit template
- Copies `.github/cass-pull_request_template.md`
- Creates worktree base folder

### `/cass:doctor`

Health check. Verifies:
- Git identity (name + email)
- Commit template wired up
- PR template present
- `gh` installed and authenticated
- Serena MCP (`uvx` available, package reachable)
- Atlassian MCP reachability and API token
- `cass.projects` config (paths exist on disk)

### `/cass:plan [text or doc path]`

**PO role.** Takes a raw requirement as text or file path.

1. Reads doc if a file path is given
2. Spawns SA + planner agents in parallel to investigate
3. Presents plan with Risks table and Suggestions
4. On approval: saves as Jira ticket (optional epic), GitHub issue (optional milestone), or `docs/<title>_<date>.md`
5. Embeds `### Technical Context` (SA findings) in saved doc for dev-feat to consume

### `/cass:dev-feat [plan/ticket]`

**Dev role.** Reads requirement from MD file, Jira ticket, GitHub issue, or inline text.

1. Detects `### Technical Context` in plan → skips codebase re-investigation if present
2. Raises dev questions (implementation ambiguities) before writing the plan
3. Writes implementation plan with test coverage and parallel workstreams
4. Reads workspace from `cass.projects` (set by init) — no worktree questions at runtime
5. Creates feature branch from `mainBranch`, worktrees under `worktreePath`
6. Spawns SWE agents per workstream

### `/cass:pr [base branch]`

Run inside a worktree. Auto-detects PR target:
- Sub-task branch → parent feature branch
- Main feature branch → `staging` (confirms before creating, option to change)

PR body includes: What / Why / How / Risks / Test Coverage / Architecture Review / Implementation Steps / Checklist / Claude session ID.

### `/cass:review [PR number or URL]`

Triggers `pr-reviewer` agent. Reports P1 / P2 / P3 / Plan Compliance. Never applies fixes without direction.

### `/cass:clean-wt`

1. Lists projects from `cass.projects`; asks which to clean if multiple
2. Shows all worktree folders with branch name and last modified date
3. User picks which to remove by number
4. Removes worktrees and local branches; checks remote before prompting remote deletion

### `/cass:test`

13-step smoke test in an isolated temp repo. Covers init, plan doc structure (Risks + Technical Context), worktree creation, branch/date listing, remote branch check, and worktree removal. Cleans up after itself.

### `/cass:plan-task`

Legacy single-command pipeline — planning + SA review + SWE implementation in one step. Still available as an alternative to the PO/Dev role split.

---

## Assets

| File | Copied to | Purpose |
|---|---|---|
| `assets/commit-template/.gitmessage` | `cass-.gitmessage` | Semantic commit format with Claude co-author |
| `assets/pr-template/pull_request_template.md` | `.github/cass-pull_request_template.md` | PR body with Risks, Test Coverage, and Checklist |

---

## Plugin structure

```
.claude-plugin/plugin.json     manifest (name, version, author)
commands/                      slash commands — /cass:<name>
skills/<name>/SKILL.md         auto-invoked skills
agents/                        subagents Claude can spawn
assets/                        template files copied by /cass:init
docs/                          documentation
hooks/hooks.json               event hooks
.mcp.json                      MCP server config
```
