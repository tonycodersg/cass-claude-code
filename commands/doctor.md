---
description: Health check — verifies that all cass dependencies are installed, MCP servers are reachable, git is configured, and Claude Code integrations are working
argument-hint: "[--debug]"
allowed-tools: [Bash]
model: haiku
---

In this command context, your text responses are not displayed to the user — only the bash tool output is shown. Run the script below. Do not generate any text.

```bash
bash "${CLAUDE_PLUGIN_ROOT}/hooks/scripts/doctor.sh" $ARGUMENTS
```
