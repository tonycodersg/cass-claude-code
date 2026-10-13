---
description: Remove all cass config and files from the current repo — undoes /cass:init. Removes .cass/, clears cass.projects from settings, unsets git commit template, and cleans .gitignore entries.
argument-hint: "[--hard to also remove .claude/commands/ overrides]"
allowed-tools: [Bash, Read, Write, AskUserQuestion]
---

## Context

- Working directory: !`pwd`
- Repo name: !`basename $(git rev-parse --show-toplevel 2>/dev/null) 2>/dev/null || basename $(pwd)`
- .cass exists: !`[ -d .cass ] && echo "yes" || echo "no"`
- .claude/commands exists: !`[ -d .claude/commands ] && echo "yes" || echo "no"`
- cass-.gitmessage exists: !`[ -f cass-.gitmessage ] && echo "yes" || echo "no"`
- git commit template: !`git config commit.template 2>/dev/null || echo "NOT SET"`
- cass settings: !`cat .claude/settings.local.json 2>/dev/null || echo "NOT FOUND"`
- User input: $ARGUMENTS

## Instructions

### Step 1 — Confirm

Ask the user:

```bash
printf "\033[1;33m╔══════════════════════════════════════════╗\033[0m\n"
printf "\033[1;33m║  cass eject                              ║\033[0m\n"
printf "\033[1;33m╚══════════════════════════════════════════╝\033[0m\n\n"
printf "This will remove all cass config from \033[1m<repo name>\033[0m:\n\n"
printf "  \033[2m•  .cass/                        (deleted)\033[0m\n"
printf "  \033[2m•  cass.projects in settings     (cleared)\033[0m\n"
printf "  \033[2m•  cass-.gitmessage              (deleted)\033[0m\n"
printf "  \033[2m•  git commit.template config    (unset)\033[0m\n"
printf "  \033[2m•  .gitignore cass entries       (removed)\033[0m\n\n"
printf "Continue? (y/n) "
```

If `$ARGUMENTS` contains `--hard`, also include:
```
  •  .claude/commands/  (deleted — removes command overrides)
```

Stop if the user says no.

---

### Step 2 — Remove .cass/

If `.cass/` exists:
```bash
rm -rf .cass/
```

---

### Step 3 — Remove cass-.gitmessage and unset git config

If `cass-.gitmessage` exists:
```bash
rm -f cass-.gitmessage
```

If `git config commit.template` is set to `cass-.gitmessage`:
```bash
git config --unset commit.template
```

---

### Step 4 — Clear cass.projects from settings

Read `.claude/settings.local.json`. If it exists:
- Remove the `cass` key from the JSON
- If the resulting JSON is empty (`{}`), delete the file entirely
- Otherwise write the cleaned JSON back

---

### Step 5 — Clean .gitignore

Remove these lines from `.gitignore` if present:
```
# cass — personal config, do not commit
.cass/settings.local.json
```

---

### Step 6 — Remove .claude/commands/ overrides (--hard only)

If `$ARGUMENTS` contains `--hard` and `.claude/commands/` exists:
```bash
rm -rf .claude/commands/
```

---

### Step 7 — Report

```bash
printf "\033[1;36m╔══════════════════════════════════════════╗\033[0m\n"
printf "\033[1;36m║  cass ejected                            ║\033[0m\n"
printf "\033[1;36m╚══════════════════════════════════════════╝\033[0m\n\n"
printf "  \033[32m✓\033[0m  .cass/                     \033[2mremoved\033[0m\n"
printf "  \033[32m✓\033[0m  cass-.gitmessage           \033[2mremoved\033[0m\n"
printf "  \033[32m✓\033[0m  git commit.template        \033[2munset\033[0m\n"
printf "  \033[32m✓\033[0m  cass.projects in settings  \033[2mcleared\033[0m\n"
printf "  \033[32m✓\033[0m  .gitignore                 \033[2mcleaned\033[0m\n\n"
printf "\033[2mRun /cass:init <project> to set up again.\033[0m\n"
```

For any item that was already absent, print `skipped — not found` in dim instead of `removed`.
