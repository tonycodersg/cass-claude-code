---
description: Health check — verifies that all cass dependencies are installed, MCP servers are reachable, git is configured, and Claude Code integrations are working
argument-hint: "[--debug]"
allowed-tools: [Bash]
model: haiku
---

Run the script. After it completes, output at most one short recommendation line if there are failures or warnings — nothing else. No summaries, no lists, no re-stating what the script already printed.

```bash
bash "${CLAUDE_PLUGIN_ROOT}/hooks/scripts/doctor.sh" $ARGUMENTS
```
