---
description: Initialise a project with the cass plugin setup — asks for project name, worktree path, and main branch, then generates .claude folder and copies commit and PR templates. Safe to run multiple times.
argument-hint: "[project name]"
allowed-tools: [Bash, Read, Write, AskUserQuestion]
---

## Context

- Working directory: !`pwd`
- Repo root: !`git rev-parse --show-toplevel 2>/dev/null || pwd`
- Repo name: !`basename $(git rev-parse --show-toplevel 2>/dev/null) 2>/dev/null || basename $(pwd)`
- .claude folder exists: !`[ -d .claude ] && echo "yes" || echo "no"`
- cass-.gitmessage exists: !`[ -f cass-.gitmessage ] && echo "yes" || echo "no"`
- PR template exists: !`[ -f .github/cass-pull_request_template.md ] && echo "yes" || echo "no"`
- Existing settings: !`cat .claude/settings.local.json 2>/dev/null || echo "NOT FOUND"`
- Default worktree path: !`echo "$(dirname $(git rev-parse --show-toplevel 2>/dev/null))/$(basename $(git rev-parse --show-toplevel 2>/dev/null))-agent-works"`
- User input: $ARGUMENTS

## Instructions

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
        "worktreePath": "<resolved absolute worktree path>"
      }
    }
  }
}
```

If `.claude/settings.local.json` already exists:
- Merge the new project entry into `cass.projects` — do not overwrite other projects or other keys
- If this project name already exists in `cass.projects`, update its values

---

### Step 5 — Copy commit template

Copy `${CLAUDE_PLUGIN_ROOT}/assets/commit-template/.gitmessage` to `cass-.gitmessage` in the project root, then configure git:

```bash
git config commit.template cass-.gitmessage
```

If `cass-.gitmessage` already exists, skip the copy and print:
> "`cass-.gitmessage` already exists — skipped."

---

### Step 6 — Set up PR template

If `.github/cass-pull_request_template.md` already exists, skip this step and print:
> "`.github/cass-pull_request_template.md` already exists — skipped."

Otherwise, ask:

> **PR template**
> Would you like to use a custom PR template from this repo?
>
> 1. Use cass default template (recommended)
> 2. Use an existing file from this repo — provide the path (e.g. `.github/pull_request_template.md`)

**If option 1:** create `.github/` if it doesn't exist, then copy `${CLAUDE_PLUGIN_ROOT}/assets/pr-template/pull_request_template.md` to `.github/cass-pull_request_template.md`.

**If option 2:** read the file at the path they provided. If it exists, copy it to `.github/cass-pull_request_template.md`. If the file doesn't exist, warn:
> "File not found at `<path>`. Falling back to cass default template."
And copy the default instead.

Save the chosen template source to `.claude/settings.local.json` under the project config:
```json
{
  "cass": {
    "projects": {
      "<project name>": {
        "prTemplate": "default"  // or the path they provided
      }
    }
  }
}
```

---

### Step 7 — Create worktree base folder

If the worktree path does not already exist, create it:

```bash
mkdir -p <worktree path>
```

---

### Step 8 — Report

Print a final summary:

```
cass init complete
==================
Project:        <project name>

  Main repo:      /absolute/path/to/repo   (branch: staging)
  Worktree base:  /absolute/path/to/repo-agent-works

  ✓  .claude/settings.local.json   saved
  ✓  cass-.gitmessage              copied  (or: skipped — already exists)
  ✓  .github/cass-pull_request_template.md   copied from <default / path they provided>  (or: skipped — already exists)
  ✓  worktree base folder          created  (or: already exists)

Run /cass:doctor to verify the full setup.
```
