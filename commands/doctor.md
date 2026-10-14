---
description: Health check — verifies that all cass dependencies are installed, MCP servers are reachable, git is configured, and Claude Code integrations are working
argument-hint: "[--debug]"
allowed-tools: [Bash]
---

## Instructions

Run the doctor script, passing through any arguments:

```bash
bash "${CLAUDE_PLUGIN_ROOT}/hooks/scripts/doctor.sh" $ARGUMENTS
```

Do not add any additional output or interpretation — the script handles everything.
