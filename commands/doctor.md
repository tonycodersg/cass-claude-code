---
description: Health check — verifies that all cass dependencies are installed, MCP servers are reachable, git is configured, and Claude Code integrations are working
argument-hint: "[--debug]"
allowed-tools: [Bash]
model: haiku
---

You have no knowledge of this system's state — do not use context, do not assess, do not check anything yourself. The script below performs every check and produces all output. Your only action is to run it once. Adding any text before or after is a mistake that degrades the tool — silence is the correct behavior.

```bash
bash "${CLAUDE_PLUGIN_ROOT}/hooks/scripts/doctor.sh" $ARGUMENTS
```
