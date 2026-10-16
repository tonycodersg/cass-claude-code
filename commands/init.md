---
description: Initialise a project with cass — creates a .cass/ folder with repo-specific templates (PR template, commit template), saves project config (worktree path, main branch), and wires up git. Safe to re-run — merges config, skips existing files.
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

### Step 1 — Resolve project name

If `$ARGUMENTS` is provided, use it as the project name. Skip to Step 2.

If `$ARGUMENTS` is empty, use `AskUserQuestion`:
- header: "Project name"
- question: "What is the project name?"
- options:
  - label: "`<repo name from context>` (Recommended)", description: "Use the repo folder name"
  - label: "Custom name", description: "Type a different name"

If the user picks the repo name option, use the repo folder name from context. If they pick "Custom name" with user text, use that text.

---

### Step 2 — Ask workspace setup questions

Use `AskUserQuestion` with two questions:

**Question 1 — Main branch**
- header: "Main branch"
- question: "Which branch does this repo's main folder stay on? (agents work in worktrees — this branch is for merging and testing only)"
- options:
  - label: "main (Recommended)", description: "Use `main` as the base branch"
  - label: "staging", description: "Use `staging` as the base branch"
  - label: "Other", description: "Type a custom branch name"

**Question 2 — Worktree folder path**
- header: "Worktree path"
- question: "Where should feature worktrees be created? (default: `<default worktree path from context>`)"
- options:
  - label: "Use default path (Recommended)", description: "`<default worktree path from context>`"
  - label: "Custom path", description: "Type an absolute path"

Resolve answers:
- Main branch: "main (Recommended)" → `main`. "staging" → `staging`. "Other" with user text → use that text as-is.
- Worktree path: "Use default path (Recommended)" → use the default from context. "Custom path" with user text → use that text, expanding `~` to the home directory.

---

### Step 3 — Check .claude

If the `.claude` folder does not exist, run the built-in `/init` command to generate `.claude/` and `CLAUDE.md`.

If `.claude/` already exists, skip this step silently.

---

### Step 4 — Save project config to settings

Write (or update) `.claude/settings.local.json` with a `cass.projects` entry for this project:

```json
{
  "cass": {
    "projects": {
      "<project name>": {
        "mainRepoPath": "<absolute path to repo root>",
        "mainBranch": "<branch>",
        "worktreePath": "<resolved absolute worktree path>",
        "prTemplate": ".cass/pr-template.md"
      }
    }
  }
}
```

If `.claude/settings.local.json` already exists:
- Merge the new project entry into `cass.projects` — do not overwrite other projects or other keys
- If this project name already exists in `cass.projects`, update its values

---

### Step 5 — Create .cass/ folder and copy templates

Create `.cass/` if it does not exist:

```bash
mkdir -p .cass
```

**Commit template:**

If `.cass/commit-template.md` already exists, skip and print:
> "`.cass/commit-template.md` already exists — skipped."

Otherwise copy `${CLAUDE_PLUGIN_ROOT}/assets/commit-template/.gitmessage` to `.cass/commit-template.md`, then wire git:

```bash
cp .cass/commit-template.md cass-.gitmessage
git config commit.template cass-.gitmessage
```

**PR template:**

If `.cass/pr-template.md` already exists, skip and print:
> "`.cass/pr-template.md` already exists — skipped."

Otherwise ask:

> **PR template**
> Would you like to use a custom PR template, or start with the cass default?
>
> 1. Use cass default template (recommended)
> 2. Use an existing file from this repo — provide the path (e.g. `.github/pull_request_template.md`)

**If option 1:** copy `${CLAUDE_PLUGIN_ROOT}/assets/pr-template/pull_request_template.md` to `.cass/pr-template.md`.

**If option 2:** read the file at the provided path. If it exists, copy it to `.cass/pr-template.md`. If not:
> "File not found at `<path>`. Falling back to cass default."
And copy the default instead.

---

### Step 6 — Update .gitignore

Append to `.gitignore` (or create it) if these entries are not already present:

```
# cass — personal config, do not commit
.cass/settings.local.json
```

---

### Step 7 — Create worktree base folder

```bash
mkdir -p <worktree path>
```

---

### Step 7b — cass-bot GitHub App setup (optional)

Ask the user using `AskUserQuestion`:
- header: "cass-bot"
- question: "Would you like to set up a cass-bot GitHub App so agent comments post under a bot identity instead of your personal account?"
- options:
  - label: "Set up cass-bot (Recommended)", description: "Agent comments (reviews, plans, ticket updates) will show as cass-bot, not your personal account"
  - label: "Skip", description: "Agent comments will post using your personal GitHub account"

If the user skips, proceed to Step 8.

**If setting up cass-bot:**

**Check if bot already configured globally:**

```python
import json
d = json.load(open(f"{HOME}/.claude/settings.local.json"))
app_id = d.get("cassBot", {}).get("appId", "")
```

**If `appId` exists** — bot is already created, just install it on this repo:

```bash
# Get installation URL for this repo
gh api /apps/cass-bot/installations
```

Tell the user:
> "cass-bot is already configured (App ID: `<id>`). Installing on this repo..."

Use `gh api` to install, or give the user the one-click install URL:
> "Open this URL to install cass-bot on this repo: `https://github.com/apps/cass-bot/installations/new`"

**If `appId` is empty** — first-time setup:

1. Generate the app manifest URL and tell the user:

> **Create cass-bot in one click**
>
> Open this URL in your browser — GitHub will pre-fill the app settings:
>
> `https://github.com/settings/apps/new?manifest=<URL-encoded manifest below>`
>
> Manifest:
> ```json
> {
>   "name": "cass-bot",
>   "description": "cass AI agent — posts code reviews, plans, and status updates",
>   "public": false,
>   "default_permissions": {
>     "issues": "write",
>     "pull_requests": "write",
>     "contents": "read"
>   },
>   "default_events": []
> }
> ```
>
> After clicking **Create GitHub App**:
> 1. Note the **App ID** shown on the app settings page
> 2. Scroll down and click **Generate a private key** — a `.pem` file will download

2. Ask the user for the two values using `AskUserQuestion`:
   - "Paste the App ID:" (text input via Other)
   - "Paste the full path to the downloaded .pem file:" (text input via Other)

3. Save to `~/.claude/settings.local.json` globally:

```python
import json, os
path = os.path.expanduser("~/.claude/settings.local.json")
d = json.load(open(path)) if os.path.exists(path) else {}
d.setdefault("cassBot", {})
d["cassBot"]["appId"] = "<app id>"
d["cassBot"]["privateKeyPath"] = "<pem path>"
json.dump(d, open(path, "w"), indent=2)
```

4. Save as repo secrets:

```bash
gh secret set CASS_BOT_APP_ID --body "<app id>"
gh secret set CASS_BOT_PRIVATE_KEY < "<pem path>"
```

5. Give the user the install URL:
> "One more step — install cass-bot on this repo: `https://github.com/apps/cass-bot/installations/new`"

Print confirmation:
> "✓ cass-bot configured — agent comments will now post under the bot identity"

---

### Step 7c — Branch protection (merge gate)

Set up branch protection on the main branch to require at least one approval before any PR can be merged. This prevents agents (or anyone) from merging unreviewed code.

Run:

```bash
gh api repos/{owner}/{repo}/branches/<mainBranch>/protection \
  --method PUT \
  --header "Accept: application/vnd.github+json" \
  --field enforce_admins=false \
  --field required_status_checks=null \
  --field restrictions=null \
  --field "required_pull_request_reviews[required_approving_review_count]=1" \
  --field "required_pull_request_reviews[dismiss_stale_reviews]=true"
```

Get owner and repo from:
```bash
gh repo view --json owner,name --jq '"\(.owner.login)/\(.name)"'
```

**If the command succeeds**, print:
> "✓ Branch protection set on `<mainBranch>` — 1 approval required before merge, stale reviews dismissed"

**If it fails** (e.g. not a repo admin), print a warning but do not stop init:
> "⚠ Could not set branch protection — you may not have admin access. Set it manually: repo Settings → Branches → Add rule → require pull request reviews"

---

### Step 8 — Report

Output the report via `printf` with ANSI color codes:

```bash
printf "\033[1;36m╔══════════════════════════════════════════╗\033[0m\n"
printf "\033[1;36m║  cass init complete                      ║\033[0m\n"
printf "\033[1;36m╚══════════════════════════════════════════╝\033[0m\n\n"
printf "\033[2mProject:  \033[0m\033[1m<project name>\033[0m\n"
printf "\033[2mRepo:     \033[0m<absolute path>  \033[2m(branch: <main branch>)\033[0m\n"
printf "\033[2mWorktrees:\033[0m <worktree path>\n\n"

printf "\033[1;36mPrerequisites\033[0m\n"
printf "  \033[32m✓\033[0m  git identity      \033[2m<name> / <email>\033[0m\n"
printf "  \033[32m✓\033[0m  gh installed      \033[2mgh version 2.x.x\033[0m\n"
printf "  \033[32m✓\033[0m  gh authenticated  \033[2mlogged in as <user>\033[0m\n"
printf "  \033[32m✓\033[0m  uvx installed     \033[2muv 0.x.x\033[0m\n\n"

printf "\033[1;36mFiles\033[0m\n"
printf "  \033[32m✓\033[0m  .claude/settings.local.json   \033[2msaved\033[0m\n"
printf "  \033[32m✓\033[0m  .cass/commit-template.md      \033[2mcopied\033[0m\n"
printf "  \033[32m✓\033[0m  .cass/pr-template.md          \033[2mcopied\033[0m\n"
printf "  \033[32m✓\033[0m  cass-.gitmessage              \033[2mlinked\033[0m\n"
printf "  \033[32m✓\033[0m  .gitignore                    \033[2mupdated\033[0m\n"
printf "  \033[32m✓\033[0m  worktree base folder          \033[2mcreated\033[0m\n"
printf "  \033[32m✓\033[0m  cass-bot                      \033[2mconfigured\033[0m\n"   # or: "skipped"
printf "  \033[32m✓\033[0m  branch protection             \033[2m1 approval required\033[0m\n\n"  # or: "⚠ skipped — insufficient permissions"

printf "\033[2m──────────────────────────────────────────\033[0m\n"
printf "\033[1;36mNext steps\033[0m\n"
printf "  \033[33m1.\033[0m Commit .cass/ so your team gets the same templates:\n"
printf "     \033[2mgit add .cass/ && git commit -m \"chore: add cass templates\"\033[0m\n"
printf "  \033[33m2.\033[0m Verify full setup:  \033[1m/cass:doctor\033[0m\n"
printf "  \033[33m3.\033[0m Start building:     \033[1m/cass:plan\033[0m  or  \033[1m/cass:dev-feat\033[0m\n"
```

Use actual values from context. For skipped files, replace `copied` with `skipped — already exists` in dim text.
