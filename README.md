# cass

A Claude Code plugin. Replace this description with what your plugin does.

## Structure

```
cass-claude-code/
├── .claude-plugin/
│   └── plugin.json          # Plugin metadata
├── commands/
│   └── example-command.md   # Slash commands (/cass:example-command)
├── skills/
│   └── example-skill/
│       └── SKILL.md         # Auto-invoked skills
├── agents/                  # (optional) Autonomous subagents
├── hooks/                   # (optional) Event hooks
│   └── hooks.json
└── .mcp.json                # (optional) MCP server config
```

## Components

### Commands (`commands/`)

User-invoked via `/cass:<command-name>`. Each `.md` file is one command.

Frontmatter fields:
- `description` — shown in `/help`
- `argument-hint` — argument hint shown to user
- `allowed-tools` — pre-approved tools (reduces permission prompts)
- `model` — override model (`haiku`, `sonnet`, `opus`)

Use `$ARGUMENTS` in the body to receive user-provided arguments.
Use `!`backtick command backtick`` for inline shell context.

### Skills (`skills/<skill-name>/SKILL.md`)

Auto-invoked by Claude based on the `description` frontmatter. Write specific trigger phrases so Claude knows when to load the skill.

Frontmatter fields:
- `name` — skill identifier
- `description` — trigger conditions (be specific)
- `version` — semantic version

### Agents (`agents/<agent-name>.md`)

Autonomous subagents Claude can spawn. Frontmatter fields: `name`, `description`, `model`, `color`, `tools`.

### Hooks (`hooks/hooks.json`)

Event-driven automation. Events: `PreToolUse`, `PostToolUse`, `Stop`, `SessionStart`, `SessionEnd`, `UserPromptSubmit`.

### MCP Servers (`.mcp.json`)

External tool integration via Model Context Protocol:
```json
{
  "server-name": {
    "type": "stdio",
    "command": "npx",
    "args": ["-y", "@your/mcp-package"]
  }
}
```

## Installation

```bash
# Load for a single session
claude --plugin-dir /path/to/cass-claude-code

# Or install to a project's .claude/plugins/
```
