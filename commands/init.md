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

**If any check fails**, print a clear blocklist and stop:

```
cass init — prerequisites missing
===================================
✗  gh not installed     → brew install gh
✗  gh not authenticated → gh auth login
✗  uvx not installed    → curl -LsSf https://astral.sh/uv/install.sh | sh

Fix the above, then re-run /cass:init.
```

Do not proceed until all prerequisites pass.

---

### Step 1 — Resolve project name

If `$ARGUMENTS` is provided, use it as the project name.

If `$ARGUMENTS` is empty, ask:
> "What is the project name? (press Enter to use the repo folder name: `<repo name from context>`)"

If the user presses Enter or leaves it blank, use the repo folder name from context.

---

### Step 2 — Ask workspace setup questions

Ask the user these two questions together in a single message:

> **cass init — workspace setup for `<project name>`**
>
> **1. Worktree folder path**
> Feature branches will be checked out as worktrees here so agents work in isolation without touching this main repo folder.
>
> Default: `<default worktree path from context>`
>
> Press Enter to use the default, or type a custom absolute path.
>
> **2. Main branch**
> This main repo folder will stay checked out on this branch (for merging and testing only — agents work in worktrees).
>
> 1. `main` (default)
> 2. `staging`
> 3. Other — type the branch name

Resolve answers:
- Worktree path: if blank/Enter → use the default from context. Expand `~` to home directory if present.
- Main branch: if they chose 1 or pressed Enter → `main`. If they chose 2 → `staging`. If they typed a custom name → use it as-is.

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

### Step 8 — Report

```
cass init complete
==================
Project:        <project name>

  Main repo:      /absolute/path/to/repo   (branch: main)
  Worktree base:  /absolute/path/to/repo-agent-works

Prerequisites
  ✓  git identity                     <name> / <email>
  ✓  gh installed                     gh version 2.x.x
  ✓  gh authenticated                 logged in as <user>
  ✓  uvx installed                    uv 0.x.x

Files
  ✓  .claude/settings.local.json      saved
  ✓  .cass/commit-template.md         copied  (or: skipped — already exists)
  ✓  .cass/pr-template.md             copied  (or: skipped — already exists)
  ✓  cass-.gitmessage                 linked from .cass/commit-template.md
  ✓  .gitignore                       updated
  ✓  worktree base folder             created  (or: already exists)

Next steps
  1. Commit .cass/ to version-control so your team gets the same templates:
       git add .cass/ && git commit -m "chore: add cass templates"
  2. Run /cass:doctor any time to verify the full setup.
  3. Start your first feature: /cass:plan or /cass:dev-feat
```
