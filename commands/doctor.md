---
description: Health check — verifies that all cass dependencies are installed, MCP servers are reachable, git is configured, and Claude Code integrations are working
argument-hint: "[--debug]"
allowed-tools: [Bash]
model: haiku
---

Run the script:

```bash
bash "${CLAUDE_PLUGIN_ROOT}/hooks/scripts/doctor.sh" $ARGUMENTS
```

The script output ends with a line: `CASS_SUMMARY: v{ver} | {n} passed | {n} warnings | {n} failed`

Your entire text response must be exactly two lines (or one if no action needed):

```
cass v{ver}  ✓ {n} passed  ⚠ {n} warnings  ✗ {n} failed
Run /cass:init to fix.   ← only include this line if warnings > 0 or failed > 0
```

No other text.
