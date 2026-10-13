---
description: Scaffold a .cass/ customization package in the current repo — creates the override folder structure so teams can customize commands, agents, hooks, and templates without touching the global plugin.
argument-hint: "[optional: space-separated list of things to scaffold e.g. commands hooks agents]"
allowed-tools: [Bash, Read, Write, AskUserQuestion]
model: haiku
---

## Context

- Working directory: !`pwd`
- Repo name: !`basename $(git rev-parse --show-toplevel 2>/dev/null) 2>/dev/null || basename $(pwd)`
- Plugin root: !`echo "${CLAUDE_PLUGIN_ROOT}"`
- .cass exists: !`[ -d .cass ] && echo "yes" || echo "no"`
- .cass/commands exists: !`[ -d .cass/commands ] && echo "yes" || echo "no"`
- .cass/agents exists: !`[ -d .cass/agents ] && echo "yes" || echo "no"`
- .cass/hooks exists: !`[ -d .cass/hooks ] && echo "yes" || echo "no"`
- User input: $ARGUMENTS

## Your Role

Scaffold the `.cass/` customization package for this repo. This gives teams a structured place to override any part of the global cass plugin — commands, agents, hooks, and templates — without forking it.

The global plugin lives in `~/.claude/plugins/cass` and is shared across all projects. The `.cass/` folder in each repo is the local layer — it takes precedence over the global plugin for that project.

## Process

### Step 1 — Confirm scope

If `$ARGUMENTS` is provided, scaffold only the listed parts (e.g. `commands hooks`).

Otherwise, ask:

> **What would you like to customise?**
> Select all that apply:
> 1. Commands — override or extend any `/cass:<name>` command for this repo
> 2. Agents — override agent behaviour (swe, sa, planner, pr-reviewer, devops)
> 3. Hooks — add repo-specific hooks (PreToolUse, Stop, UserPromptSubmit, etc.)
> 4. All of the above

---

### Step 2 — Create folder structure

Create the requested folders under `.cass/`:

```bash
mkdir -p .cass/commands
mkdir -p .cass/agents
mkdir -p .cass/hooks/scripts
```

Only create the folders the user selected.

---

### Step 3 — Write README

Write `.cass/README.md`:

```markdown
# .cass — repo customizations

This folder contains repo-specific overrides for the global [cass plugin](https://github.com/tonycodersg/cass-claude-code).

## Structure

```
.cass/
  commands/           ← override any /cass:<name> command for this repo
  agents/             ← override any cass agent (swe, sa, planner, etc.)
  hooks/              ← repo-specific hooks
    hooks.json
    scripts/
  pr-template.md      ← PR body template (used by /cass:pr and swe agent)
  commit-template.md  ← commit message template (used by /cass:commit)
```

## How overrides work

- **Commands**: place a file named `cass:<name>.md` in `.cass/commands/`. It will be used instead of the plugin's version when running `/cass:<name>` in this project.
- **Agents**: place a file named `<agent-name>.md` in `.cass/agents/`. Same override pattern.
- **Hooks**: define hooks in `.cass/hooks/hooks.json`. These run alongside (not instead of) the plugin's global hooks.
- **Templates**: edit `.cass/pr-template.md` and `.cass/commit-template.md` directly.

## What to commit

| File | Commit? |
|---|---|
| `.cass/commands/` | Yes — team shares command overrides |
| `.cass/agents/` | Yes |
| `.cass/hooks/` | Yes |
| `.cass/pr-template.md` | Yes |
| `.cass/commit-template.md` | Yes |
| `.cass/settings.local.json` | No — gitignore this |
```

---

### Step 4 — Write example stubs

**If commands selected**, write `.cass/commands/.gitkeep` and a `HOWTO.md`:

```markdown
# Customising commands

Copy any command from the global plugin and edit it here:

  cp ~/.claude/plugins/cass/commands/pr.md .cass/commands/cass:pr.md

Claude Code will use this version instead of the plugin's when running /cass:pr in this project.

Available commands to override:
  cass:init, cass:plan, cass:plan-task, cass:dev-feat, cass:commit,
  cass:pr, cass:review, cass:clean-wt, cass:test, cass:doctor
```

**If agents selected**, write `.cass/agents/HOWTO.md`:

```markdown
# Customising agents

Copy any agent from the global plugin and edit it here:

  cp ~/.claude/plugins/cass/agents/swe.md .cass/agents/swe.md

Available agents to override:
  swe, sa, planner, pr-reviewer, devops
```

**If hooks selected**, write `.cass/hooks/hooks.json` with an empty but valid structure:

```json
{
  "hooks": [
    // Add repo-specific hooks here.
    // These run alongside the global plugin hooks, not instead of them.
    // Example:
    // {
    //   "event": "Stop",
    //   "command": "bash ${CLAUDE_PLUGIN_ROOT}/.cass/hooks/scripts/my-hook.sh"
    // }
  ]
}
```

---

### Step 5 — Update .gitignore

Ensure `.cass/settings.local.json` is in `.gitignore`. If not already present, append:

```
.cass/settings.local.json
```

---

### Step 6 — Report

```
.cass/ customization package created
=====================================
Repo: <repo name>

  .cass/README.md                ✓ created
  .cass/commands/HOWTO.md        ✓ created   (if selected)
  .cass/agents/HOWTO.md          ✓ created   (if selected)
  .cass/hooks/hooks.json         ✓ created   (if selected)

Next steps:
  • Commit .cass/ to version-control so your team gets the same setup
  • To override a command: cp ~/.claude/plugins/cass/commands/<name>.md .cass/commands/cass:<name>.md
  • To override an agent:  cp ~/.claude/plugins/cass/agents/<name>.md .cass/agents/<name>.md
  • To add a hook:         edit .cass/hooks/hooks.json
```
