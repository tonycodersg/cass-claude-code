---
description: Health check — verifies that all cass dependencies are installed, MCP servers are reachable, git is configured, and Claude Code integrations are working
allowed-tools: [Bash, Read]
---

## Context

- Working directory: !`pwd`
- OS: !`uname -s`
- Git user name: !`git config user.name 2>/dev/null || echo "NOT SET"`
- Git user email: !`git config user.email 2>/dev/null || echo "NOT SET"`
- Git commit template: !`git config commit.template 2>/dev/null || echo "NOT SET"`
- gh installed: !`gh --version 2>/dev/null | head -1 || echo "NOT FOUND"`
- gh auth status: !`gh auth status 2>/dev/null | head -2 || echo "NOT AUTHENTICATED"`
- uvx installed: !`uvx --version 2>/dev/null || echo "NOT FOUND"`
- node installed: !`node --version 2>/dev/null || echo "NOT FOUND"`
- npx installed: !`npx --version 2>/dev/null || echo "NOT FOUND"`
- cass-.gitmessage exists: !`[ -f cass-.gitmessage ] && echo "yes" || echo "no"`
- PR template exists: !`[ -f .github/cass-pull_request_template.md ] && echo "yes" || echo "no"`
- .mcp.json exists: !`[ -f .mcp.json ] && echo "yes" || echo "no"`
- .mcp.json content: !`cat .mcp.json 2>/dev/null || echo "NOT FOUND"`
- Claude settings: !`cat .claude/settings.json 2>/dev/null || cat ~/.claude/settings.json 2>/dev/null || echo "NOT FOUND"`
- cass settings: !`cat .claude/settings.local.json 2>/dev/null || echo "NOT FOUND"`

## Instructions

Run a full health check and print a structured report. Do not stop on failures — check everything and report the full picture at the end.

Work through each check below, collect pass/fail/warn for each, then print the final report.

---

### Check 1 — Git identity

From context:
- **PASS** if `git user.name` and `git user.email` are both set
- **FAIL** if either is `NOT SET` → fix: `git config --global user.name "Your Name"` and `git config --global user.email "you@example.com"`

---

### Check 2 — Git commit template

From context:
- **PASS** if `git commit.template` points to `cass-.gitmessage` AND `cass-.gitmessage` exists in the working directory
- **WARN** if `cass-.gitmessage` exists but the git config is not set → fix: `git config commit.template cass-.gitmessage`
- **FAIL** if `cass-.gitmessage` does not exist → fix: run `/cass:init`

---

### Check 3 — PR template

From context:
- **PASS** if `.github/cass-pull_request_template.md` exists
- **FAIL** if not → fix: run `/cass:init`

---

### Check 4 — GitHub CLI (`gh`)

From context:
- **PASS** if `gh --version` returned a version AND `gh auth status` shows a logged-in account
- **WARN** if `gh` is installed but not authenticated → fix: `gh auth login`
- **FAIL** if `gh` is not installed → fix: https://cli.github.com

---

### Check 5 — Serena MCP (semantic code navigation)

From context, check if `uvx` is available (required to launch Serena):
- **PASS** if `uvx --version` returned a version
- **FAIL** if `NOT FOUND` → fix: install uv via `curl -LsSf https://astral.sh/uv/install.sh | sh`

Then attempt a connectivity check to the Serena package:
```bash
uvx --from git+https://github.com/oraios/serena serena --help 2>/dev/null | head -1
```
- **PASS** if the command returns any output
- **WARN** if it times out or fails → Serena may not start (network issue or package changed); the MCP server will fail to launch at session start
- **SKIP** if uvx itself is not found (already failed above)

---

### Check 6 — Atlassian MCP

From context, check `.mcp.json`:
- If `atlassian` key exists in `.mcp.json`, run:
  ```bash
  curl -s --max-time 5 -o /dev/null -w "%{http_code}" https://mcp.atlassian.com/v1/mcp 2>/dev/null
  ```
  - **PASS** if HTTP status is 200, 401, or 403 (server reachable, auth is separate)
  - **WARN** if 000 (no response / network unreachable) — Atlassian MCP won't work without internet
  - **WARN** if `.mcp.json` has the `atlassian` server but no `ATLASSIAN_API_TOKEN` or equivalent env var is set (check `env | grep -i atlassian`)
- If `atlassian` key is not in `.mcp.json` → **INFO** (not configured, skipped)

---

### Check 7 — Other MCP servers in `.mcp.json`

For each additional server found in `.mcp.json` (beyond `atlassian` and `serena`):
- `stdio` type: check that the `command` is available on PATH (e.g. `which npx`, `which node`)
  - **PASS** if command found
  - **WARN** if not found → MCP server won't launch
- `http` type: attempt a curl HEAD to the URL
  - **PASS** if reachable
  - **WARN** if not reachable

---

### Check 8 — cass init configuration

From `cass.projects` in `.claude/settings.local.json`:

- **FAIL** if `cass.projects` is empty or missing → fix: run `/cass:init <project-name>`
- **PASS** if at least one project is configured

For each project found, show:
```
  Project: <name>
    Main repo:      <mainRepoPath>   (branch: <mainBranch>)
    Worktree base:  <worktreePath>
```

For each project, also check that `worktreePath` exists on disk:
- **PASS** if folder exists
- **WARN** if it doesn't → fix: `mkdir -p <worktreePath>` or re-run `/cass:init <project-name>`

---

### Final report

Print a formatted summary:

```
cass doctor
===========

Git
  ✓  user.name / user.email           configured
  ✓  commit template                  cass-.gitmessage
  ✓  PR template                      .github/cass-pull_request_template.md

GitHub CLI
  ✓  gh installed                     gh version 2.x.x
  ✓  gh authenticated                 Logged in to github.com as <user>

Serena MCP
  ✓  uvx installed                    uv 0.x.x
  ✓  serena reachable                 package loads OK

Atlassian MCP
  ✓  server reachable                 https://mcp.atlassian.com (HTTP 200)
  ⚠  ATLASSIAN_API_TOKEN              not set in environment

Other MCP servers
  ✓  <server-name>                    command found

cass projects
  ✓  my-app         /path/to/repo  (branch: staging) | worktrees: /path/to/repo-agent-works ✓
  ✓  another-app    /path/to/other (branch: main)    | worktrees: /path/to/other-agent-works ✓

─────────────────────────────────────
  X passed   Y warnings   Z failed
```

Use:
- `✓` for PASS
- `⚠` for WARN
- `✗` for FAIL
- `ℹ` for INFO

After the report, list any FAIL or WARN items with their fix commands grouped under:

```
Action needed
─────────────
✗ cass-.gitmessage missing → run /cass:init
⚠ ATLASSIAN_API_TOKEN not set → add to your shell profile: export ATLASSIAN_API_TOKEN=...
```

If everything passes, print:
```
All checks passed. cass is ready to use.
```
