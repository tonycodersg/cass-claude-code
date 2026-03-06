# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## What This Repo Is

This is a **Claude Code plugin** named `cass`. Plugins extend Claude Code with slash commands, auto-invoked skills, subagents, hooks, and MCP server integrations. The plugin is loaded into other projects via `claude --plugin-dir` or by symlinking into a project's `.claude/plugins/` directory.

## Plugin Structure

```
.claude-plugin/plugin.json   # Plugin manifest (name, description, author)
commands/                    # Slash commands — user-invoked via /cass:<name>
skills/<name>/SKILL.md       # Auto-invoked skills — triggered by Claude based on description
agents/                      # Autonomous subagents Claude can spawn
hooks/hooks.json             # Event hooks (PreToolUse, PostToolUse, Stop, etc.)
.mcp.json                    # MCP server configuration (optional)
```

## Authoring Guidelines

### Commands (`commands/<name>.md`)

- Frontmatter: `description`, `argument-hint`, `allowed-tools`, `model`
- Use `$ARGUMENTS` to receive user input
- Use `!`backtick shell command backtick`` for inline shell context injected at invocation time
- Invoked as `/cass:<name>` from any project that loads this plugin

### Skills (`skills/<name>/SKILL.md`)

- Frontmatter: `name`, `description`, `version`
- The `description` field controls when Claude auto-loads the skill — include specific trigger phrases
- Supporting files go in `references/`, `examples/`, `scripts/` subdirectories beside `SKILL.md`

### Agents (`agents/<name>.md`)

- Frontmatter: `name`, `description`, `model`, `color`, `tools`
- `description` uses `<example>` blocks for reliable triggering
- Claude spawns agents via the Agent tool when context matches the description

### Hooks (`hooks/hooks.json`)

- Events: `PreToolUse`, `PostToolUse`, `Stop`, `SubagentStop`, `SessionStart`, `SessionEnd`, `UserPromptSubmit`, `PreCompact`, `Notification`
- Use `${CLAUDE_PLUGIN_ROOT}` for portable paths to hook scripts
- Hook scripts exit 0 to allow, non-zero to block; output JSON `{"decision": "block", "reason": "..."}` for PreToolUse

### MCP Servers (`.mcp.json`)

```json
{
  "server-name": {
    "type": "stdio",
    "command": "npx",
    "args": ["-y", "@package/name"],
    "env": { "API_KEY": "${MY_ENV_VAR}" }
  }
}
```

## Loading This Plugin

```bash
# One-off session
claude --plugin-dir /path/to/cass-claude-code

# Per-project (add to .claude/plugins/)
ln -s /path/to/cass-claude-code ~/.claude/plugins/cass
```
