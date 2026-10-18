---
description: Initialise a project with cass — wizard-style setup that asks all questions upfront, confirms with the user, then executes silently. Creates .cass/ templates, saves project config, wires git, optionally sets up cass-bot and Playwright CI. Safe to re-run.
argument-hint: "[project name]"
allowed-tools: [Bash, Read, Write, AskUserQuestion]
---

## Context

- Working directory: !`pwd`
- Repo root: !`git rev-parse --show-toplevel 2>/dev/null || pwd`
- Repo name: !`basename $(git rev-parse --show-toplevel 2>/dev/null) 2>/dev/null || basename $(pwd)`
- .claude folder exists: !`[ -d .claude ] && echo "yes" || echo "no"`
- .cass folder exists: !`[ -d .cass ] && echo "yes" || echo "no"`
- .cass/pr-template.md exists: !`[ -f .cass/pr-template.md ] && echo "yes" || echo "no"`
- .cass/commit-template.md exists: !`[ -f .cass/commit-template.md ] && echo "yes" || echo "no"`
- Existing settings: !`cat .claude/settings.local.json 2>/dev/null || echo "NOT FOUND"`
- Default worktree path: !`echo "$(dirname $(git rev-parse --show-toplevel 2>/dev/null))/$(basename $(git rev-parse --show-toplevel 2>/dev/null))-agent-works"`
- gh version: !`gh --version 2>/dev/null | head -1 || echo "NOT FOUND"`
- gh auth: !`gh auth status 2>/dev/null | grep -i "logged in" | head -1 || echo "NOT AUTHENTICATED"`
- uvx version: !`uvx --version 2>/dev/null || echo "NOT FOUND"`
- git user name: !`git config user.name 2>/dev/null || echo "NOT SET"`
- git user email: !`git config user.email 2>/dev/null || echo "NOT SET"`
- cass-bot configured globally: !`python3 -c "import json; d=json.load(open('${HOME}/.claude/settings.local.json')); print('yes' if d.get('cassBot',{}).get('appId') else 'no')" 2>/dev/null || echo "no"`
- User input: $ARGUMENTS

## Instructions

### Step 0 — Prerequisite check

Before doing anything, verify the required tools are available from context. Collect all failures and report them together — do not stop on the first one.

| Tool | Check | Fix if missing |
|---|---|---|
| `git` identity | `git user.name` and `git user.email` both set | `git config --global user.name "Name"` and `git config --global user.email "you@example.com"` |
| `gh` installed | `gh --version` returned a version | `brew install gh` or https://cli.github.com |
| `gh` authenticated | auth status shows logged in | `gh auth login` |
| `uvx` installed | `uvx --version` returned a version | `curl -LsSf https://astral.sh/uv/install.sh \| sh` |

**If any check fails**, output a colored blocklist via `printf` and stop:

```bash
printf "\033[1;31m╔══════════════════════════════════════════╗\033[0m\n"
printf "\033[1;31m║  cass init — prerequisites missing       ║\033[0m\n"
printf "\033[1;31m╚══════════════════════════════════════════╝\033[0m\n\n"
printf "\033[31m✗\033[0m  gh not installed     → brew install gh\n"
printf "\033[31m✗\033[0m  gh not authenticated → gh auth login\n"
printf "\033[31m✗\033[0m  uvx not installed    → curl -LsSf https://astral.sh/uv/install.sh | sh\n\n"
printf "\033[2mFix the above, then re-run /cass:init.\033[0m\n"
```

Only print the lines that actually failed. Do not proceed until all prerequisites pass.

---

### Step 1 — Ask all setup questions upfront

Use `AskUserQuestion` with all questions in a single call. Do not ask them one at a time.

**Q1 — Project name** (skip if `$ARGUMENTS` is provided — use that value directly)
- header: "Project name"
- question: "What is the project name?"
- options:
  - label: "`<repo name>` (Recommended)", description: "Use the repo folder name — keeps things consistent with git"
  - label: "Custom name", description: "Type a different name for this project"

**Q2 — Main branch**
- header: "Main branch"
- question: "Which branch do agents base their work on? Feature branches are created from here and PRs merge back here."
- options:
  - label: "staging (Recommended)", description: "Standard integration branch — agents branch off staging, PRs target staging"
  - label: "main", description: "Use if your team works directly off main with no staging layer"
  - label: "Other", description: "Type a custom branch name"

**Q3 — Worktree path**
- header: "Worktree path"
- question: "Where should feature worktrees be created? Agents work here in isolation — your main repo folder stays untouched."
- options:
  - label: "`<default worktree path>` (Recommended)", description: "Sibling folder next to your repo — easy to find, standard cass convention"
  - label: "Custom path", description: "Type an absolute path"

**Q4 — PR template**
- header: "PR template"
- question: "Which PR template should cass use when creating pull requests?"
- options:
  - label: "cass default (Recommended)", description: "Structured template with What / Why / How / Risks / Checklist / Affected Screens sections"
  - label: "Use existing file", description: "Type a path to an existing template in this repo (e.g. `.github/pull_request_template.md`)"

**Q5 — cass-bot GitHub App** (skip if already configured globally — show "already configured" message instead)
- header: "cass-bot"
- question: "Set up a cass-bot GitHub App? Agent comments (reviews, plans, ticket updates) will post under the bot identity instead of your personal account."
- options:
  - label: "Set up cass-bot (Recommended)", description: "Keeps agent activity separate from your personal GitHub account — one-time setup, shared across all repos"
  - label: "Skip for now", description: "Agent comments will post using your personal GitHub token — can set up later by re-running /cass:init"

**Q6 — Playwright CI**
- header: "Playwright CI"
- question: "Add a Playwright e2e CI workflow? When a PR is created, Claude identifies affected screens from the diff and triggers only the relevant specs automatically."
- options:
  - label: "Add Playwright CI (Recommended)", description: "Copies workflow to `.github/workflows/playwright-ci.yml` — GitHub runs it on every PR, results posted as PR comment"
  - label: "Skip", description: "Add later by copying `${CLAUDE_PLUGIN_ROOT}/assets/playwright/playwright-ci.yml` manually"

**Q7 — Post-PR hook**
- header: "Post-PR hook"
- question: "Fire a callback after every PR is created? Useful for Slack notifications, Jira transitions, or custom webhooks."
- options:
  - label: "Skip (set up later)", description: "Run `/cass:customize hooks` at any time to scaffold the callback script"
  - label: "Slack notification", description: "Scaffolds a post-pr.sh stub with a Slack webhook example"
  - label: "Generic webhook", description: "Scaffolds a post-pr.sh stub with a curl webhook example"

---

### Step 2 — Resolve all answers

After receiving all answers, resolve the final values:

| Setting | Resolution |
|---|---|
| Project name | Repo name if recommended selected; user text if custom |
| Main branch | `staging` / `main` / user-typed text |
| Worktree path | Default path / user-typed path (expand `~` to home directory) |
| PR template | `cass-default` / file path provided |
| cass-bot | `setup` / `skip` |
| Playwright CI | `yes` / `no` |
| Post-PR hook | `none` / `slack` / `webhook` |

---

### Step 3 — Confirmation summary

Present a confirmation summary before doing anything. Ask the user to confirm with `AskUserQuestion`:

- header: "Confirm setup"
- question: "Here's your cass setup — does everything look right?"

Show the summary as the question body:

```
  Project:       <name>
  Main branch:   <branch>
  Worktree path: <path>
  PR template:   <cass default | path>
  cass-bot:      <set up | skip>
  Playwright CI: <yes | no>
  Post-PR hook:  <none | slack | webhook>
```

- options:
  - label: "Looks good — run setup", description: "Execute all steps with the settings above"
  - label: "Start over", description: "Go back to Step 1 and answer the questions again"

If the user picks "Start over" — return to Step 1. If "Looks good" — proceed to Step 4.

---

### Step 4 — Execute silently

Run all steps in order without asking further questions. Print a single progress line per step (no sub-questions):

```
  → Creating .claude/ folder...
  → Saving project config...
  → Setting up .cass/ templates...
  → Wiring git commit template...
  → Updating .gitignore...
  → Creating worktree base folder...
  → Setting up cass-bot...          (if selected)
  → Adding Playwright CI workflow... (if selected)
  → Scaffolding post-PR hook...      (if selected)
```

**4a — Create .claude/**
If `.claude/` does not exist, run the built-in `/init` command. Otherwise skip silently.

**4b — Save project config**
Write (or merge) `.claude/settings.local.json`:

```json
{
  "cass": {
    "projects": {
      "<project name>": {
        "mainRepoPath": "<absolute repo root>",
        "mainBranch": "<branch>",
        "worktreePath": "<worktree path>",
        "prTemplate": ".cass/pr-template.md"
      }
    }
  }
}
```

**4c — Create .cass/ and copy templates**

```bash
mkdir -p .cass
```

Commit template — copy `${CLAUDE_PLUGIN_ROOT}/assets/commit-template/.gitmessage` to `.cass/commit-template.md`, then:
```bash
cp .cass/commit-template.md cass-.gitmessage
git config commit.template cass-.gitmessage
```
Skip if `.cass/commit-template.md` already exists.

PR template:
- If `cass-default`: copy `${CLAUDE_PLUGIN_ROOT}/assets/pr-template/pull_request_template.md` to `.cass/pr-template.md`
- If existing file: copy the user-provided path to `.cass/pr-template.md`
- Skip if `.cass/pr-template.md` already exists

**4d — Update .gitignore**
Append if not already present:
```
# cass — personal config, do not commit
.cass/settings.local.json
```

**4e — Create worktree base folder**
```bash
mkdir -p <worktree path>
```

**4f — cass-bot setup** (if selected)

Check if `cassBot.appId` already exists in `~/.claude/settings.local.json`:
- If yes: install on this repo only (provide install URL)
- If no: run the full setup flow:
  1. Print the GitHub App manifest URL for one-click creation
  2. Ask for App ID and .pem path
  3. Save to `~/.claude/settings.local.json` globally
  4. Run `gh secret set CASS_BOT_APP_ID` and `gh secret set CASS_BOT_PRIVATE_KEY`
  5. Print install URL: `https://github.com/apps/cass-bot/installations/new`

**4g — Playwright CI** (if selected)
```bash
mkdir -p .github/workflows
```
Copy `${CLAUDE_PLUGIN_ROOT}/assets/playwright/playwright-ci.yml` to `.github/workflows/playwright-ci.yml`.
Skip if file already exists.

**4h — Post-PR hook** (if slack or webhook selected)
```bash
mkdir -p .cass/hooks/scripts
```
Copy `${CLAUDE_PLUGIN_ROOT}/assets/hooks/post-pr.sh` to `.cass/hooks/scripts/post-pr.sh` and uncomment the relevant block (Slack or webhook). Make executable:
```bash
chmod +x .cass/hooks/scripts/post-pr.sh
```

---

### Step 5 — Final report

Output the complete report via `printf`:

```bash
printf "\033[1;36m╔══════════════════════════════════════════╗\033[0m\n"
printf "\033[1;36m║  cass init complete                      ║\033[0m\n"
printf "\033[1;36m╚══════════════════════════════════════════╝\033[0m\n\n"

printf "\033[2mProject:  \033[0m\033[1m<name>\033[0m\n"
printf "\033[2mRepo:     \033[0m<path>  \033[2m(branch: <branch>)\033[0m\n"
printf "\033[2mWorktrees:\033[0m <worktree path>\n\n"

printf "\033[1;36mPrerequisites\033[0m\n"
printf "  \033[32m✓\033[0m  git identity      \033[2m<name> / <email>\033[0m\n"
printf "  \033[32m✓\033[0m  gh installed      \033[2m<version>\033[0m\n"
printf "  \033[32m✓\033[0m  gh authenticated  \033[2m<user>\033[0m\n"
printf "  \033[32m✓\033[0m  uvx installed     \033[2m<version>\033[0m\n\n"

printf "\033[1;36mFiles\033[0m\n"
printf "  \033[32m✓\033[0m  .claude/settings.local.json    \033[2msaved\033[0m\n"
printf "  \033[32m✓\033[0m  .cass/commit-template.md       \033[2mcopied\033[0m\n"  # or skipped
printf "  \033[32m✓\033[0m  .cass/pr-template.md           \033[2mcopied\033[0m\n"  # or skipped
printf "  \033[32m✓\033[0m  cass-.gitmessage               \033[2mlinked\033[0m\n"
printf "  \033[32m✓\033[0m  .gitignore                     \033[2mupdated\033[0m\n"
printf "  \033[32m✓\033[0m  worktree base folder           \033[2mcreated\033[0m\n"
printf "  \033[32m✓\033[0m  cass-bot                       \033[2mconfigured\033[0m\n"      # if set up, else skipped
printf "  \033[32m✓\033[0m  playwright-ci.yml              \033[2madded\033[0m\n"           # if selected, else skipped
printf "  \033[32m✓\033[0m  post-pr.sh                     \033[2mscaffolded\033[0m\n\n"   # if selected, else skipped

printf "\033[2m──────────────────────────────────────────\033[0m\n"
printf "\033[1;36mNext steps\033[0m\n"
printf "  \033[33m1.\033[0m Commit .cass/ so your team gets the same setup:\n"
printf "     \033[2mgit add .cass/ && git commit -m \"chore: add cass config\"\033[0m\n"
printf "  \033[33m2.\033[0m Verify:      \033[1m/cass:doctor\033[0m\n"
printf "  \033[33m3.\033[0m Start:       \033[1m/cass:plan\033[0m  or  \033[1m/cass:dev-feat\033[0m\n"
```

Use actual values. For skipped files replace `copied` with `skipped — already exists` in dim text.
