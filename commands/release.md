---
description: Cut a release — bump version in plugin.json, update CHANGELOG, tag, push, and create a GitHub Release. Run from master after all PRs are merged.
argument-hint: "[version e.g. 0.7.0 — omit to auto-increment patch]"
allowed-tools: [Bash, Read, Edit, AskUserQuestion]
model: sonnet
---

## Context

- Working directory: !`pwd`
- Current branch: !`git branch --show-current 2>/dev/null`
- Current version: !`python3 -c "import json; print(json.load(open('.claude-plugin/plugin.json'))['version'])" 2>/dev/null || echo "unknown"`
- Latest tag: !`git describe --tags --abbrev=0 2>/dev/null || echo "none"`
- Commits since last tag: !`git log $(git describe --tags --abbrev=0 2>/dev/null)..HEAD --oneline 2>/dev/null || git log --oneline | head -20`
- Unreleased changelog: !`awk '/## \[Unreleased\]/{found=1; next} found && /## \[/{exit} found{print}' CHANGELOG.md 2>/dev/null`
- Today's date: !`date +%Y-%m-%d`
- User input: $ARGUMENTS

## Process

### Step 1 — Confirm branch

If current branch is not `master`, warn:
> "You're on `<branch>`, not `master`. Releases should be cut from master. Switch to master and merge all feature branches first, then re-run `/cass:release`."

Exit unless the user explicitly confirms they want to continue anyway.

---

### Step 2 — Determine version

**If `$ARGUMENTS` is provided**, use it as the new version (strip leading `v` if present).

**If empty**, read the current version from `plugin.json` and auto-increment the patch:
- `0.6.0` → `0.6.1`
- `0.6.1` → `0.6.2`

Show the user:
> "Releasing version `<new-version>` (current: `<current-version>`). Confirm? (y/n)"

Exit if they say no.

---

### Step 3 — Check for unreleased changes

If the `## [Unreleased]` section in `CHANGELOG.md` is empty, warn:
> "The [Unreleased] section in CHANGELOG.md is empty. Add entries before releasing, or confirm to release with no changelog entry."

---

### Step 4 — Bump version in plugin.json

Read `.claude-plugin/plugin.json`, update `"version"` to the new version, write it back.

---

### Step 5 — Update CHANGELOG

Replace the `## [Unreleased]` section header with the versioned entry:

```markdown
## [Unreleased]

## [<new-version>] - <today>
```

This preserves the `[Unreleased]` section for future entries and inserts the new release below it.

---

### Step 6 — Commit

```bash
git add .claude-plugin/plugin.json CHANGELOG.md
git commit -m "chore(release): bump to v<new-version> and update changelog

Co-Authored-By: Claude Sonnet 4.6 <noreply@anthropic.com>"
```

---

### Step 7 — Tag and push

```bash
git tag v<new-version>
git push origin master
git push origin v<new-version>
```

---

### Step 8 — Create GitHub Release

Generate release notes from the CHANGELOG section just promoted:

```bash
gh release create v<new-version> \
  --title "v<new-version>" \
  --notes "<changelog content for this version>"
```

---

### Step 9 — Report

Print:
```
Released v<new-version>
Tag:     v<new-version>
GitHub:  <release URL>

Install:
  git clone --branch v<new-version> https://github.com/tonycodersg/cass-claude-code ~/.claude/plugins/cass
```
