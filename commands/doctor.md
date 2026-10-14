---
description: Health check — verifies that all cass dependencies are installed, MCP servers are reachable, git is configured, and Claude Code integrations are working
argument-hint: "[--debug]"
allowed-tools: [Bash]
model: haiku
---

Plugin version: !`python3 -c "import json; print(json.load(open('${CLAUDE_PLUGIN_ROOT}/.claude-plugin/plugin.json'))['version'])" 2>/dev/null || echo "unknown"`

Run the script:

```bash
bash "${CLAUDE_PLUGIN_ROOT}/hooks/scripts/doctor.sh" $ARGUMENTS
```

After it runs, your entire text response must follow this exact format — nothing more:

```
cass v{VERSION}  ✓ {N} passed  ⚠ {N} warnings  ✗ {N} failed
{one line fix if needed, or omit}
```

No summaries. No lists. No explanations.
