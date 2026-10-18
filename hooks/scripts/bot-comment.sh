#!/usr/bin/env bash
# Post a comment to a GitHub PR or issue using cass-bot identity.
# Falls back to personal gh token if bot is not configured.
#
# Usage:
#   bot-comment.sh pr <number> <body>
#   bot-comment.sh issue <number> <body>

TYPE="$1"   # pr | issue
NUMBER="$2"
BODY="$3"

LOGO_URL="https://raw.githubusercontent.com/tonycodersg/cass-claude-code/master/assets/logo.png"
SIGNATURE=$'\n\n---\n<img src="'"$LOGO_URL"'" width="16" align="left" /> *Posted by [cass-bot](https://github.com/tonycodersg/cass-claude-code)*'
BODY="${BODY}${SIGNATURE}"

if [ -z "$TYPE" ] || [ -z "$NUMBER" ] || [ -z "$BODY" ]; then
  echo "Usage: bot-comment.sh <pr|issue> <number> <body>" >&2
  exit 1
fi

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
BOT_TOKEN=$("$SCRIPT_DIR/bot-token.sh" 2>/dev/null)

OWNER=$(gh repo view --json owner --jq '.owner.login' 2>/dev/null)
REPO=$(gh repo view --json name --jq '.name' 2>/dev/null)

if [ -n "$BOT_TOKEN" ]; then
  # Post via bot token using GitHub REST API
  if [ "$TYPE" = "pr" ]; then
    ENDPOINT="https://api.github.com/repos/$OWNER/$REPO/issues/$NUMBER/comments"
  else
    ENDPOINT="https://api.github.com/repos/$OWNER/$REPO/issues/$NUMBER/comments"
  fi

  curl -s -X POST \
    -H "Authorization: token $BOT_TOKEN" \
    -H "Accept: application/vnd.github+json" \
    -H "Content-Type: application/json" \
    "$ENDPOINT" \
    -d "$(python3 -c "import json,sys; print(json.dumps({'body': sys.argv[1]}))" "$BODY")" \
    > /dev/null

  echo "✓ Posted as cass-bot"
else
  # Fallback to personal gh token
  if [ "$TYPE" = "pr" ]; then
    gh pr comment "$NUMBER" --body "$BODY"
  else
    gh issue comment "$NUMBER" --body "$BODY"
  fi
fi
