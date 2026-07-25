---
description: Clean up merged worktrees — lists all agent worktrees, checks PR status, and removes worktrees + branches for merged PRs
argument-hint: "[optional: worktree base path override]"
allowed-tools: [Bash, AskUserQuestion, Read]
model: haiku
---

## Context

- Working directory: !`pwd`
- Repo name: !`basename $(git rev-parse --show-toplevel 2>/dev/null) 2>/dev/null || basename $(pwd)`
- Repo root: !`git rev-parse --show-toplevel 2>/dev/null || pwd`
- User input: $ARGUMENTS
- cass settings: !`cat .claude/settings.local.json 2>/dev/null || echo "NOT FOUND"`

## Your Role

Find all cass-managed worktrees, check whether their PRs have been merged, and clean up the ones that are done. Ask before removing anything that looks uncertain.

## Process

### Step 1 — Find worktree base

If `$ARGUMENTS` is provided, use it as the worktree base path directly.

Otherwise, read `cass.projects` from `.claude/settings.local.json` (already injected in context above):
- If one project → use its `worktreePath`
- If multiple projects → ask the user which project's worktrees to clean
- If no projects → tell the user to run `/cass:init <project-name>` first and exit

### Step 2 — List active worktrees

```bash
git worktree list --porcelain
```

Filter for worktrees that live inside the worktree base path identified in Step 1.

### Step 3 — Check PR status for each worktree

For each worktree found:

```bash
# Get the branch name for this worktree
git -C <worktree-path> branch --show-current

# Check if a PR exists and its state
gh pr list --head <branch-name> --json number,title,state,mergedAt --limit 1
```

Classify each worktree:
- **Merged** — PR state is `MERGED`
- **Open** — PR is open (not yet merged)
- **No PR** — no PR found for this branch
- **Unknown** — gh command failed or branch is detached

### Step 4 — Report and confirm

Present a summary table:

```
Worktree cleanup report
=======================
<worktree-base>/feat-user-auth/       branch: feat/user-auth          PR #12 — MERGED ✓
<worktree-base>/PROJ-123-api-layer/   branch: feat/PROJ-123-api-layer PR #13 — OPEN
<worktree-base>/PROJ-123-ui/          branch: feat/PROJ-123-ui        PR #14 — MERGED ✓
<worktree-base>/feat-old-thing/       branch: feat/old-thing          No PR found
```

Ask:
> "Found [N] merged worktrees ready to clean. Shall I remove them and delete their branches?
> (Open PRs and 'No PR' worktrees will be skipped unless you confirm separately)"

For any "No PR" worktrees, ask individually:
> "No PR found for `<branch>` in `<folder>`. Remove this worktree anyway? (y/n)"

### Step 5 — Clean up

For each confirmed worktree to remove:

```bash
# Remove the worktree
git worktree remove <worktree-path> --force

# Delete the local branch
git branch -d <branch-name>

# Delete the remote branch (optional — ask first)
gh pr view <pr-number> --json mergedAt | grep -q mergedAt && git push origin --delete <branch-name> 2>/dev/null || true
```

Before deleting remote branches, ask:
> "Also delete the remote branches on origin? (They may already be deleted if auto-delete is enabled on your repo)"

### Step 6 — Final report

```
Cleanup complete
================
Removed: <worktree-path> (PR #N merged)
Removed: <worktree-path> (PR #N merged)
Skipped: <worktree-path> (PR open)
Skipped: <worktree-path> (user chose to keep)

Remaining worktrees: <N>
```

If the worktree base folder is now empty after cleanup, offer to remove it:
> "The worktree folder `<worktree-base>` is now empty. Remove it?"
