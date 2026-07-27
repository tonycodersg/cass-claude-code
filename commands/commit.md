---
description: Stage changes, generate a semantic commit message from the diff, and commit with Claude co-authorship. Called by dev-feat/SWE agent or run manually.
argument-hint: "[optional: commit message hint or ticket ref]"
allowed-tools: [Bash, AskUserQuestion]
model: haiku
---

## Context

- Working directory: !`pwd`
- Git status: !`git status --short 2>/dev/null`
- Staged diff: !`git diff --cached --stat 2>/dev/null`
- Unstaged diff: !`git diff --stat 2>/dev/null`
- User hint: $ARGUMENTS

## Process

### Step 1 — Check for changes

If both staged and unstaged are empty, print:
> "Nothing to commit — working tree is clean."

And exit.

---

### Step 2 — Stage files

If there are **unstaged** changes, ask:
> "Which files should I stage?
> 1. All changed files (`git add -A`)
> 2. Only already-staged files — commit as-is
> 3. Let me choose — list the files"

If option 3, list the unstaged files and ask the user to type the ones to stage.

If there are **only staged** changes already, skip this step.

---

### Step 3 — Generate commit message

Read the full staged diff:
```bash
git diff --cached
```

Generate a semantic commit message following this format:

```
<type>(<scope>): <short summary>

<body — optional, only if the change needs explanation>

Refs: <ticket ref if provided in $ARGUMENTS>
Co-authored-by: Claude <claude@anthropic.com>
```

Rules:
- `type`: `feat` / `fix` / `chore` / `refactor` / `docs` / `test` / `style` / `perf`
- `scope`: inferred from the files changed (e.g. `auth`, `api`, `ui`, `db`) — omit if unclear
- `summary`: imperative, present tense, no period, max 72 chars
- `body`: only include if the WHY is non-obvious — skip for simple changes
- `Refs:` line: only include if `$ARGUMENTS` contains a ticket ref (e.g. `PROJ-123`, `#42`)
- `Co-authored-by:` line: always present

---

### Step 4 — Show and confirm

Present the generated message:

```
Commit message:
───────────────────────────────────────
<generated message>
───────────────────────────────────────
1. Commit with this message
2. Edit the message
3. Cancel
```

If the user chooses **Edit**, show the message and ask them to type the revised version. Use their version as-is.

If the user chooses **Cancel**, exit without committing.

---

### Step 5 — Commit

```bash
git commit -m "<confirmed message>"
```

Print the commit hash and summary on success:
```
✓ Committed: abc1234 feat(auth): add JWT refresh token endpoint
```

---

## Constraints

- Never commit without user confirmation
- Never use `--no-verify` or skip hooks
- Always include `Co-authored-by: Claude <claude@anthropic.com>` in the footer
- Never stage `.env`, credential files, or binary files — warn the user if any are detected in the unstaged list
