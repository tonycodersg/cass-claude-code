---
description: Clean up worktrees — lists initialized projects, shows worktrees with branch name and last modified date, removes the ones you select
argument-hint: "[optional: worktree base path override]"
allowed-tools: [Bash, AskUserQuestion]
model: haiku
---

## Context

- Working directory: !`pwd`
- Repo root: !`git rev-parse --show-toplevel 2>/dev/null || pwd`
- User input: $ARGUMENTS
- cass settings: !`cat .claude/settings.local.json 2>/dev/null || echo "NOT FOUND"`

## Process

### Step 1 — Select project

**If `$ARGUMENTS` is provided**, use it as the worktree base path and skip to Step 2.

**Otherwise**, read `cass.projects` from settings:
- No projects → tell the user to run `/cass:init <project-name>` first and exit
- One project → use it automatically
- Multiple projects → list them and ask which one

---

### Step 2 — List worktrees

Run:

```bash
ls -1 <worktree-base>
```

For each folder, get branch and last modified date:

```bash
git -C <worktree-path> branch --show-current 2>/dev/null || echo "detached"
stat -f "%Sm" -t "%Y-%m-%d" <worktree-path> 2>/dev/null || stat --format="%y" <worktree-path> 2>/dev/null | cut -d' ' -f1
```

---

### Step 3 — Show list and ask

Display:

```
#   Folder                   Branch                    Modified
─── ──────────────────────── ───────────────────────── ──────────
1   feat-user-auth/          feat/user-auth            2026-07-20
2   feat-payment/            feat/payment              2026-07-22
3   feat-old-thing/          feat/old-thing            2026-06-10
```

Ask:
> "Which worktrees do you want to remove? Enter numbers separated by commas (e.g. 1,3), or `all`, or `none`:"

---

### Step 4 — Remove selected

For each selected worktree:

```bash
git worktree remove <worktree-path> --force
git branch -d <branch-name> 2>/dev/null || true
```

Then check if a remote tracking branch still exists:

```bash
git ls-remote --heads origin <branch-name>
```

- If it **does not exist** on remote → skip, nothing to do
- If it **exists** on remote → ask once for all remaining:
  > "Remote branches still exist for: `feat/user-auth`, `feat/old-thing`. Delete them on origin? (y/n)"

  If yes:
  ```bash
  git push origin --delete <branch-name> 2>/dev/null || true
  ```

---

### Step 5 — Report

```
Done
====
Removed: feat-user-auth/    feat/user-auth
Removed: feat-old-thing/    feat/old-thing
Kept:    feat-payment/      feat/payment

Remaining: 1 worktree
```

If the base folder is now empty, offer to remove it:
> "Worktree folder is now empty. Remove it? (y/n)"
