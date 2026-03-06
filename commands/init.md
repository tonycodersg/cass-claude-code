---
description: Initialise a project with the cass plugin setup — generates .claude folder and copies commit and PR templates
allowed-tools: [Bash, Read, Write]
---

## Task

Initialise the current project with the cass plugin setup.

## Current state

- Working directory: !`pwd`
- .claude folder exists: !`[ -d .claude ] && echo "yes" || echo "no"`
- .github folder exists: !`[ -d .github ] && echo "yes" || echo "no"`
- cass-.gitmessage exists: !`[ -f cass-.gitmessage ] && echo "yes" || echo "no"`
- cass-pull_request_template.md exists: !`[ -f .github/cass-pull_request_template.md ] && echo "yes" || echo "no"`

## Instructions

Work through these steps in order. Stop and report if any step fails.

### Step 1 — Check .claude

If the `.claude` folder already exists, print:

> "`.claude/` already exists — skipping init. No files were modified."

Then stop. Do not proceed further.

### Step 2 — Run /init

Run the built-in `/init` command to generate the `.claude/` folder and `CLAUDE.md` for this project.

### Step 3 — Copy commit template

Copy `${CLAUDE_PLUGIN_ROOT}/assets/commit-template/.gitmessage` to `cass-.gitmessage` in the project root.

Then configure git to use it:

```bash
git config commit.template cass-.gitmessage
```

If `cass-.gitmessage` already exists, skip the copy and print:
> "`cass-.gitmessage` already exists — skipped."

### Step 4 — Copy PR template

Create `.github/` if it does not exist, then copy `${CLAUDE_PLUGIN_ROOT}/assets/pr-template/pull_request_template.md` to `.github/cass-pull_request_template.md`.

If `.github/cass-pull_request_template.md` already exists, skip the copy and print:
> "`.github/cass-pull_request_template.md` already exists — skipped."

### Step 5 — Report

Print a summary of what was done:

```
cass init complete
  ✓ .claude/                          generated
  ✓ cass-.gitmessage                  copied  (or: skipped — already exists)
  ✓ .github/cass-pull_request_template.md  copied  (or: skipped — already exists)
```
