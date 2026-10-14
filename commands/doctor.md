---
description: Health check — verifies that all cass dependencies are installed, MCP servers are reachable, git is configured, and Claude Code integrations are working
allowed-tools: [Bash]
---

## Instructions

Run the doctor script and output the result:

```bash
bash "${CLAUDE_PLUGIN_ROOT}/hooks/scripts/doctor.sh"
```

Do not add any additional output or interpretation — the script handles everything.
