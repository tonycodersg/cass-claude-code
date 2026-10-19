<p align="center">
  <img src="assets/logo.svg" width="120" alt="cass logo" />
</p>

# cass

> A Claude Code **global plugin** that brings a structured **plan → build → review** pipeline to any project.
> Role-split commands for POs and developers. Parallel agents work in isolated worktrees — your main branch never changes.
> Hooks run automatically to guard against destructive commands and keep Claude context-aware.
> Each repo gets its own `.cass/` customization layer — override commands, agents, hooks, and templates, committed alongside your code.

**Latest stable: [v0.9.1](https://github.com/tonycodersg/cass-claude-code/releases/tag/v0.9.1)**

---

## Install

> **Pick one install method and stick with it.** Mixing clone + marketplace causes the marketplace cache to take precedence and get stuck on old versions.

### 1. Prerequisites

```bash
# GitHub CLI — required for PRs, issues, branch management
brew install gh && gh auth login

# uv — required for Serena MCP (code intelligence)
curl -LsSf https://astral.sh/uv/install.sh | sh
```

### 2a. Clone (recommended)

Reliable, always up-to-date with `git pull`:

```bash
# Latest stable (v0.9.1)
git clone --branch v0.9.1 https://tonycodersg@github.com/tonycodersg/cass-claude-code ~/.claude/plugins/cass

# Or track latest
git clone https://tonycodersg@github.com/tonycodersg/cass-claude-code ~/.claude/plugins/cass
```

Loads automatically in every Claude Code session. No restart needed.

**Update:**
```bash
cd ~/.claude/plugins/cass && git pull
```

### 2b. Marketplace

Easier to install, but cache can get stuck on old versions:

```
/plugin marketplace add tonycodersg/cass-claude-code
/plugin install cass@cass-marketplace --global
/reload-plugins
```

**Update:**
```
/plugin update cass@cass-marketplace
/reload-plugins
```

**If stuck on an old version**, reinstall fresh:
```
/plugin uninstall cass@cass-marketplace
/plugin install cass@cass-marketplace --global
/reload-plugins
```

> **Still seeing the old version after reinstall?** The marketplace cache can persist. Full reset:
> ```
> /plugin uninstall cass@cass-marketplace
> ```
> Then close and reopen Claude Code, reinstall, and `/reload-plugins`.

### 2c. Per session (one-off)

```bash
claude --plugin-dir /path/to/cass-claude-code
```

### 3. Verify

Open any project in Claude Code, then:

```
/cass:doctor
```

All checks green = ready to use.

---

## Quick start

```bash
# First time in a project — register paths and create templates
/cass:init my-app

# Verify your environment
/cass:doctor

# Run the e2e test suite (plugin repo only)
/cass:test-suite
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
| `/cass:init [project]` | Setup | Wizard-style setup — asks all questions upfront (project name, branch, worktree path, PR template, cass-bot, Playwright CI, post-PR hook), confirms, then executes silently |
| `/cass:doctor` | Setup | Health check — tools, MCP servers, git config, project settings, cass version |
| `/cass:customize` | Setup | Scaffold `.cass/` override package — commands, agents, hooks, post-PR callback |
| `/cass:eject` | Setup | Remove all cass config from this repo — undoes `/cass:init`. `--hard` also removes `.claude/commands/` |
| `/cass:plan [text or doc]` | PO | Requirement → risk-assessed plan → Jira / GitHub issue / MD file |
| `/cass:dev-feat [plan/ticket]` | Dev | Plan → feature branch + worktree → parallel SWE agents. Three autonomous modes: `--god` (SWE writes plan + implements), `--architect` (SA reviews plan first), `--full` (SA review + fix-review loop until clean, max 3 cycles). All modes post results to original ticket. |
| `/cass:commit` | Dev | Stage changes, generate semantic message, commit with co-author |
| `/cass:pr` | Dev | Create PR from current worktree — fires post-PR callback hook if configured |
| `/cass:review [PR or branch]` | Dev | Code review via pr-reviewer agent — P1 / P2 / P3 findings, lists all PR comment threads with resolved/unresolved status, walks through unresolved one by one |
| `/cass:clean-wt` | Dev | List worktrees by project, pick to remove |
| `/cass:test-suite` | Dev | End-to-end test suite — discovers all test cases under `tests/`, runs runner + LLM verifier per case in parallel, prints a `✓ good / ⚠ comment / ✗ fail` report. Plugin repo only. |

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

**Add a post-PR callback (Slack, webhooks, Jira transitions):**

`/cass:pr` automatically runs `.cass/hooks/scripts/post-pr.sh` after every PR is created — if the file exists. The script receives `$1` PR URL, `$2` source branch, `$3` target branch.

Run `/cass:customize hooks` to scaffold the stub, then uncomment the integration you want:

```bash
# .cass/hooks/scripts/post-pr.sh
curl -s -X POST "$SLACK_WEBHOOK_URL" \
  -H "Content-Type: application/json" \
  -d "{\"text\": \"PR ready for review: $1 ($2 → $3)\"}"
```

Commit `.cass/hooks/scripts/post-pr.sh` — your whole team gets the notification automatically.

**Add other repo-specific hooks:**
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

If the marketplace cache is stuck on an old version, reinstall fresh:
```
/plugin uninstall cass@cass-marketplace
/plugin install cass@cass-marketplace --global
/reload-plugins
```

---

## Testing

The plugin ships with an end-to-end test suite under `tests/`. Each test case has three stages:

```
tests/<command>/<scenario>/
  1-init/setup.sh                         ← scaffold an isolated temp repo
  2-test/run.md                           ← the slash command to run
  3-answers-and-expected/
    answers.json                          ← pre-filled AskUserQuestion responses
    expected.json                         ← file, output, and tool-call assertions
```

**Run all tests:**

```bash
bash tools/run-suite.sh
```

**Run one command group:**

```bash
bash tools/run-suite.sh tests/doctor
bash tools/run-suite.sh tests/commit
```

**Run one test case:**

```bash
bash tools/run-test.sh tests/doctor/all-pass
bash tools/run-test.sh tests/commit/happy-path
```

**`expected.json` format:**

```json
{
  "files": [
    { "path": ".cass/pr-template.md", "exists": true }
  ],
  "output": {
    "contains": ["✓", "cass v", "✗ 0 failed"],
    "not_contains": ["Run /cass:init to fix"]
  },
  "verifier_prompt": "Doctor should report all checks passing with version number shown"
}
```

After mechanical assertions, an LLM verifier (haiku) reads `verifier_prompt` and returns `✓ good`, `⚠ comment`, or `✗ fail`. Failed test folders are kept at `/tmp/cass-test-<id>/` for debugging.

**Current test cases (15):**

| Test | Command | What it covers |
|---|---|---|
| `doctor/all-pass` | `/cass:doctor` | All checks green |
| `doctor/missing-gh` | `/cass:doctor` | `gh` stubbed — failure detection + fix instructions |
| `init/happy-path` | `/cass:init` | Full 8-question wizard — settings + templates created |
| `commit/happy-path` | `/cass:commit` | Unstaged file — stage all, confirm, commit hash + co-author |
| `commit/empty-staging` | `/cass:commit` | Clean tree — "Nothing to commit" without a commit |
| `eject/happy-path` | `/cass:eject` | Removes `.cass/`, gitmessage, settings key, gitignore entries |
| `eject/hard-flag` | `/cass:eject --hard` | Same + removes `.claude/commands/` overrides |
| `review/clean-diff` | `/cass:review` | Clean subtract function — no P1 findings |
| `review/bugs-flagged` | `/cass:review` | Unchecked `arr[0]` — verifier asserts P1 raised |
| `pr-reviewer/planted-bug` | (agent) | Async/await null deref — P1 caught by pr-reviewer agent |
| `pr/happy-path` | `/cass:pr` | `gh` stubbed — PR body structure + URL output |
| `customize/happy-path` | `/cass:customize` | `.cass/` override scaffold created |
| `clean-wt/remove-one` | `/cass:clean-wt` | Simulated worktree + settings — removal flow |
| `plan/to-file` | `/cass:plan` | Auth requirement → Goal/Scope/Risks saved as MD |
| `dev-feat/god-mode` | `/cass:dev-feat --god` | Trivial plan → zero-touch flow starts without prompting |

---

## Docs

- [Technical reference](docs/TECHNICAL.md) — agents, command details, prerequisites, plugin structure
- [Changelog](CHANGELOG.md)
