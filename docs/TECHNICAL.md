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
- `--auto-post` posts findings as a GitHub PR comment without asking — used in automated pipelines
- Applies fixes only on explicit direction

### qa — `sonnet`

Triggered by `/cass:qa`.

**Default mode** (post-implementation coverage fill)
- Reads existing test files and source code
- Identifies untested functions, branches, and error paths
- Writes test assertions and runs the suite

**`--tdd <plan-file>` mode** (pre-implementation stubs)
- Reads plan file — extracts testable units from Success Criteria (falls back to Goal + Approach)
- Writes failing test stubs; stubs fail because the module doesn't exist yet (correct TDD behaviour)
- Posts a QA Test Plan report to the ticket via cass-bot

**`--verify-pr <branch>` mode** (post-PR verification)
- Checks out the PR branch, runs the full suite
- Identifies coverage gaps introduced by the PR
- Posts findings to both the PR and the original ticket

### security — `sonnet`

Triggered by `/cass:security` or `/cass:review --security`.

- Runs `semgrep --config=auto` on the diff if semgrep is available
- Falls back to manual OWASP Top 10 review if semgrep is not installed or JSON parse fails
- Reports findings as P1 (critical) / P2 (medium) / P3 (low) matching pr-reviewer format

### onboarder — `sonnet`

Triggered by `/cass:onboard`.

- Reads `CLAUDE.md`, `README.md`, package manifests, folder structure (`-maxdepth 2`), cass config
- Reads `git log` and recent GitHub PRs/issues for activity context
- Runs `git log --format="%ae"` to identify top contributors by area
- Writes `.cass/ONBOARDING.md` with sections: What it does, How it works, Key directories, Running locally, Who to ask, Common workflows

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

### `/cass:pr [base branch] [--no-qa]`

Run inside a worktree. Auto-detects PR target:
- Sub-task branch → parent feature branch
- Main feature branch → `staging` (confirms before creating, option to change)

PR body includes: What / Why / How / Risks / Test Coverage / Architecture Review / Implementation Steps / Checklist / Claude session ID.

After the PR is created, automatically spawns in parallel:
- `qa --verify-pr` — runs the suite and posts gaps to the PR and ticket
- `pr-reviewer --auto-post` — posts review findings as a GitHub PR comment

`--no-qa` skips the qa spawn (pr-reviewer still runs).

### `/cass:review [PR number or URL] [--security]`

Triggers `pr-reviewer` agent. Reports P1 / P2 / P3 / Plan Compliance. Never applies fixes without direction.

`--security` also spawns the `security` agent in parallel — SAST + OWASP Top 10 on the same diff.

### `/cass:qa [--tdd <plan-file>] [--verify-pr <branch>]`

Routes to the qa agent in one of three modes (see agent description above).

### `/cass:security [PR number or URL]`

Triggers the `security` agent on the current branch diff or a specific PR. Reports P1/P2/P3 security findings. Standalone alternative to `/cass:review --security`.

### `/cass:onboard`

Triggers the `onboarder` agent. Generates `.cass/ONBOARDING.md` for the current repository.

### `/cass:clean-wt`

1. Lists projects from `cass.projects`; asks which to clean if multiple
2. Shows all worktree folders with branch name and last modified date
3. User picks which to remove by number
4. Removes worktrees and local branches; checks remote before prompting remote deletion

### `/cass:test-suite`

End-to-end test suite (plugin repo only). Discovers all test cases under `tests/`, runs each via `tools/run-test.sh` in parallel, and prints an aggregated report.

```
/cass:test-suite              # run all tests
/cass:test-suite tests/doctor # run only doctor tests
```

### `/cass:plan-task [--qa] <task>`

Single-ticket planner — writes a structured plan file and creates a GitHub issue.

`--qa` auto-spawns the qa agent in `--tdd` mode after the ticket is created (no confirmation prompt). Without the flag, the planner asks via `AskUserQuestion` whether to spawn qa.

---

## Assets

| File | Copied to | Purpose |
|---|---|---|
| `assets/commit-template/.gitmessage` | `cass-.gitmessage` | Semantic commit format with Claude co-author |
| `assets/pr-template/pull_request_template.md` | `.github/cass-pull_request_template.md` | PR body with Risks, Test Coverage, and Checklist |

---

## Testing

The plugin ships with an end-to-end test suite that runs each slash command in an isolated temp repo.

### Structure

```
tests/<command>/<scenario>/
  1-init/setup.sh                    ← bash script: scaffold an isolated git repo
  2-test/run.md                      ← the slash command to run (first non-empty line)
  3-answers-and-expected/
    answers.json                     ← AskUserQuestion responses (keyed by header)
    expected.json                    ← assertions + verifier prompt
```

### expected.json schema

```json
{
  "files": [
    { "path": ".cass/pr-template.md", "exists": true },
    { "path": ".claude/settings.local.json", "contains": "staging" }
  ],
  "output": {
    "contains": ["✓", "cass v"],
    "not_contains": ["error"]
  },
  "tool_calls": [
    { "tool": "Bash", "input_contains": "mkdir -p .cass" },
    { "tool": "AskUserQuestion", "count": 1 }
  ],
  "verifier_prompt": "Describe what success looks like — the LLM judge reads this"
}
```

### answers.json schema

Map by question header (the `header:` field in `AskUserQuestion`). The runner injects them into the prompt:

```json
{
  "Main branch": "staging",
  "PR template": "cass default",
  "Confirm setup": "Looks good"
}
```

Empty `{}` for commands that ask no questions (e.g. `cass:doctor`).

### Tools

| Script | Purpose |
|---|---|
| `tools/run-test.sh <folder>` | Run one test case end-to-end |
| `tools/run-suite.sh [folder]` | Run all (or a subset of) test cases in parallel |
| `tools/assert-results.py` | Mechanical assertions against results.json + expected.json |
| `tools/verify-output.sh` | LLM-as-judge — returns `✓ good`, `⚠ comment`, or `✗ fail` |

### Env overrides

`setup.sh` can write a `.cass-test-env` file (`KEY=VALUE` lines) to override environment variables before Claude runs — used to stub tools like `gh`:

```bash
# setup.sh
cat > ./bin/gh <<'EOF'
#!/usr/bin/env bash
exit 127
EOF
chmod +x ./bin/gh
echo "PATH=$(pwd)/bin:$PATH" > .cass-test-env
```

### Current test cases

| Test | Command | What it covers |
|---|---|---|
| `doctor/all-pass` | `/cass:doctor` | All checks green — git identity, templates, `gh`, `uvx` |
| `doctor/missing-gh` | `/cass:doctor` | `gh` stubbed to exit 127 — failure detection + fix instructions |
| `init/happy-path` | `/cass:init` | Full 8-question wizard — settings + templates created |
| `commit/happy-path` | `/cass:commit` | Unstaged file — stage all, confirm, commit hash + co-author footer |
| `commit/empty-staging` | `/cass:commit` | Clean working tree — "Nothing to commit" without a commit |
| `eject/happy-path` | `/cass:eject` | Removes `.cass/`, gitmessage, settings cass key, gitignore entries |
| `eject/hard-flag` | `/cass:eject --hard` | Same + removes `.claude/commands/` overrides |
| `review/clean-diff` | `/cass:review` | Clean subtract function — verifies no P1 findings |
| `review/bugs-flagged` | `/cass:review` | Unchecked `arr[0]` access — verifier asserts P1 raised |
| `pr-reviewer/planted-bug` | (agent) | Async/await null deref planted in `src/auth.ts` — P1 caught |
| `pr/happy-path` | `/cass:pr` | `gh` stubbed — PR body structure + URL in output |
| `pr/qa-verification` | `/cass:pr` | After PR created, qa `--verify-pr` + pr-reviewer spawn in parallel |
| `customize/happy-path` | `/cass:customize` | Clean repo — `.cass/` override scaffold created |
| `clean-wt/remove-one` | `/cass:clean-wt` | Simulated worktree + settings — removal flow |
| `plan/to-file` | `/cass:plan` | Auth requirement → Goal/Scope/Risks saved as MD in `docs/` |
| `dev-feat/god-mode` | `/cass:dev-feat --god` | Trivial plan doc → zero-touch implementation flow |
| `qa/writes-missing-test` | `/cass:qa` | Default mode — fills coverage gap on an untested `divide()` function |
| `qa/tdd-from-plan` | `/cass:qa --tdd` | TDD mode — writes failing stubs from plan Success Criteria |
| `qa/tdd-no-criteria` | `/cass:qa --tdd` | TDD mode — falls back to Goal + Approach when no Success Criteria section |
| `qa/verify-pr` | `/cass:qa --verify-pr` | Post-PR mode — identifies coverage gap on `feat/add-divide` branch |
| `security/injection-in-diff` | `/cass:review --security` | SQL injection via string concat — flagged as P1 (OWASP A03) |
| `security/standalone` | `/cass:security` | Command injection in `exec()` calls — security agent invoked standalone |
| `onboarder/generates-guide` | `/cass:onboard` | Reads project context, writes `.cass/ONBOARDING.md` |
| `planner/qa-flag` | `/cass:plan-task --qa` | `--qa` force flag — qa agent auto-spawned after ticket without asking |
| `planner/qa-offer` | `/cass:plan-task` | Interactive path — planner offers qa via `AskUserQuestion`, user says yes |

> `plan`, `dev-feat`, `qa`, and `security` tests spawn internal sub-agents and take longer (~2–5 min each). Tests that need `gh` stub it locally so no real GitHub repo is required.

### Report format

```
cass test suite  25 test(s) discovered
═══════════════════════════════════════════════════
  ✓ good    clean-wt / remove-one
  ✓ good    commit / empty-staging
  ✓ good    commit / happy-path
  ✓ good    customize / happy-path
  ✓ good    dev-feat / god-mode
  ✓ good    doctor / all-pass
  ✓ good    doctor / missing-gh
  ✓ good    eject / happy-path
  ✓ good    eject / hard-flag
  ✓ good    init / happy-path
  ✓ good    onboarder / generates-guide
  ✓ good    plan / to-file
  ✓ good    planner / qa-flag
  ✓ good    planner / qa-offer
  ✓ good    pr-reviewer / planted-bug
  ✓ good    pr / happy-path
  ✓ good    pr / qa-verification
  ✓ good    qa / tdd-from-plan
  ✓ good    qa / tdd-no-criteria
  ✓ good    qa / verify-pr
  ✓ good    qa / writes-missing-test
  ✓ good    review / bugs-flagged
  ✓ good    review / clean-diff
  ✓ good    security / injection-in-diff
  ✓ good    security / standalone
═══════════════════════════════════════════════════

  25 passed  ·  0 comment  ·  0 failed
```

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
tests/                         e2e test cases
tools/                         test runner scripts
.mcp.json                      MCP server config
```
