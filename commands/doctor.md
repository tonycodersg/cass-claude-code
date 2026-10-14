---
description: Health check — verifies that all cass dependencies are installed, MCP servers are reachable, git is configured, and Claude Code integrations are working
allowed-tools: [Bash, Read]
---

## Context

- Working directory: !`pwd`
- OS: !`uname -s`
- cass version: !`cat "${CLAUDE_PLUGIN_ROOT}/.claude-plugin/plugin.json" 2>/dev/null | python3 -c "import json,sys; print(json.load(sys.stdin).get('version','unknown'))" 2>/dev/null || echo "unknown"`
- Git user name: !`git config user.name 2>/dev/null || echo "NOT SET"`
- Git user email: !`git config user.email 2>/dev/null || echo "NOT SET"`
- Git commit template: !`git config commit.template 2>/dev/null || echo "NOT SET"`
- gh installed: !`gh --version 2>/dev/null | head -1 || echo "NOT FOUND"`
- gh auth status: !`gh auth status 2>/dev/null | head -2 || echo "NOT AUTHENTICATED"`
- uvx installed: !`uvx --version 2>/dev/null || echo "NOT FOUND"`
- node installed: !`node --version 2>/dev/null || echo "NOT FOUND"`
- npx installed: !`npx --version 2>/dev/null || echo "NOT FOUND"`
- .cass folder exists: !`[ -d .cass ] && echo "yes" || echo "no"`
- .cass/commit-template.md exists: !`[ -f .cass/commit-template.md ] && echo "yes" || echo "no"`
- .cass/pr-template.md exists: !`[ -f .cass/pr-template.md ] && echo "yes" || echo "no"`
- cass-.gitmessage exists: !`[ -f cass-.gitmessage ] && echo "yes" || echo "no"`
- legacy PR template exists: !`[ -f .github/cass-pull_request_template.md ] && echo "yes" || echo "no"`
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
- **PASS** if `.cass/commit-template.md` exists AND `git commit.template` points to `cass-.gitmessage`
- **WARN** if `.cass/commit-template.md` exists but git config not set → fix: `git config commit.template cass-.gitmessage`
- **FAIL** if `.cass/commit-template.md` does not exist → fix: run `/cass:init`

---

### Check 3 — PR template

From context:
- **PASS** if `.cass/pr-template.md` exists
- **WARN** if only `.github/cass-pull_request_template.md` exists (legacy — still works, migrate by re-running `/cass:init`)
- **FAIL** if neither exists → fix: run `/cass:init`

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

**CRITICAL: missing `cass.projects` is NOT a failure. It is expected when init has not been run yet.**

- If `cass.projects` is empty or missing → output **`ℹ`** (INFO, blue) — do NOT use `✗`, do NOT increment failed counter, do NOT add to Action needed block. Show: `ℹ  not initialised  run /cass:init <project-name> to set up`
- If at least one project is configured → **PASS**

For each configured project, show:
```
  Project: <name>
    Main repo:      <mainRepoPath>   (branch: <mainBranch>)
    Worktree base:  <worktreePath>
```

For each project, check that `worktreePath` exists on disk:
- **PASS** if folder exists
- **WARN** if it doesn't → fix: `mkdir -p <worktreePath>` or re-run `/cass:init <project-name>`

---

### Final report

Output the report by running a bash `printf` block with ANSI color codes so the output is colored in the terminal. Use this color scheme:

- Cyan bold (`\033[1;36m`) — header box and section titles
- Green (`\033[32m`) — ✓ PASS
- Yellow (`\033[33m`) — ⚠ WARN
- Red (`\033[31m`) — ✗ FAIL
- Blue (`\033[34m`) — ℹ INFO
- Dim (`\033[2m`) — detail values on the right
- Reset (`\033[0m`) — after every colored segment

Print the report using this structure:

```bash
printf "\033[1;36m╔══════════════════════════════════════════╗\033[0m\n"
printf "\033[1;36m║  cass doctor  (v<version>)               ║\033[0m\n"
printf "\033[1;36m╚══════════════════════════════════════════╝\033[0m\n\n"

printf "\033[1;36mGit\033[0m\n"
printf "  \033[32m✓\033[0m  user.name / user.email    \033[2m<name> / <email>\033[0m\n"
printf "  \033[32m✓\033[0m  commit template            \033[2m.cass/commit-template.md\033[0m\n"
printf "  \033[31m✗\033[0m  PR template                \033[2mnot found → run /cass:init\033[0m\n\n"

printf "\033[1;36mGitHub CLI\033[0m\n"
printf "  \033[32m✓\033[0m  gh installed               \033[2mgh version 2.x.x\033[0m\n"
printf "  \033[32m✓\033[0m  gh authenticated           \033[2mlogged in as <user>\033[0m\n\n"

printf "\033[1;36mSerena MCP\033[0m\n"
printf "  \033[32m✓\033[0m  uvx installed              \033[2muv 0.x.x\033[0m\n"
printf "  \033[33m⚠\033[0m  serena reachable           \033[2mtimed out — may fail at session start\033[0m\n\n"

printf "\033[1;36mAtlassian MCP\033[0m\n"
printf "  \033[32m✓\033[0m  server reachable           \033[2mHTTP 200\033[0m\n"
printf "  \033[33m⚠\033[0m  ATLASSIAN_API_TOKEN        \033[2mnot set in environment\033[0m\n\n"

printf "\033[1;36mcass projects\033[0m\n"
printf "  \033[32m✓\033[0m  my-app    \033[2m/path/to/repo (branch: staging) | worktrees: /path/to/worktrees ✓\033[0m\n\n"

printf "\033[2m──────────────────────────────────────────\033[0m\n"
printf "  \033[32m%d passed\033[0m   \033[33m%d warnings\033[0m   \033[31m%d failed\033[0m\n\n" <X> <Y> <Z>
```

Fill in actual values from the checks. After the summary line, if there are any FAIL or WARN items print an action block:

```bash
printf "\033[1;31mAction needed\033[0m\n"
printf "\033[2m─────────────\033[0m\n"
printf "\033[31m✗\033[0m  .cass/pr-template.md missing       → run /cass:init\n"
printf "\033[33m⚠\033[0m  ATLASSIAN_API_TOKEN not set        → export ATLASSIAN_API_TOKEN=... in shell profile\n"
```

INFO items (like uninitialised project) do not count as failures and do not appear in the action block. They are shown inline in the cass projects section only.

If everything passes (no FAIL, no WARN), print:

```bash
printf "\033[1;32m✓ All checks passed. cass is ready to use.\033[0m\n"
```

If only INFO items remain (no FAIL, no WARN), still print the all-passed line — INFO is not a problem.
