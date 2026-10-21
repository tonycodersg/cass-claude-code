---
name: bot-comment
description: Use when posting a review, QA report, plan, or status update as a GitHub PR comment or ticket comment via the cass-bot identity.
version: 1.0.0
---

## Invocation

```bash
bash "${CLAUDE_PLUGIN_ROOT}/hooks/scripts/bot-comment.sh" <type> <ref> "<markdown body>"
```

**Types:**

| Type | `<ref>` | Example |
|---|---|---|
| `pr` | PR number | `bash "..." pr 42 "## Review\n..."` |
| `issue` | Issue number | `bash "..." issue 17 "## Plan\n..."` |
| `ticket` | Jira key or GitHub issue URL | `bash "..." ticket PROJ-42 "## QA Report\n..."` |

## Identity

Uses the cass-bot GitHub App identity if configured (set via `/cass:init`). Falls back to the personal `gh` token automatically — no extra configuration needed.

## Fallback

If `bot-comment.sh` is not available (plugin not installed, path wrong, or `gh` unauthenticated), do not fail silently — output the full comment text so the user can post it manually.
