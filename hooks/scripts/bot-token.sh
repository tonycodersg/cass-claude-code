#!/usr/bin/env bash
# Generates a short-lived GitHub App installation token for cass-bot.
# Reads CASS_BOT_APP_ID and CASS_BOT_PRIVATE_KEY_PATH from ~/.claude/settings.local.json
# Outputs the token to stdout, or exits 1 if bot is not configured.

GLOBAL_SETTINGS="$HOME/.claude/settings.local.json"

if [ ! -f "$GLOBAL_SETTINGS" ]; then
  exit 1
fi

APP_ID=$(python3 -c "
import json, sys
try:
  d = json.load(open('$GLOBAL_SETTINGS'))
  print(d.get('cassBot', {}).get('appId', ''))
except: pass
" 2>/dev/null)

KEY_PATH=$(python3 -c "
import json, sys
try:
  d = json.load(open('$GLOBAL_SETTINGS'))
  print(d.get('cassBot', {}).get('privateKeyPath', ''))
except: pass
" 2>/dev/null)

if [ -z "$APP_ID" ] || [ -z "$KEY_PATH" ] || [ ! -f "$KEY_PATH" ]; then
  exit 1
fi

# Generate JWT using PyJWT via uvx
JWT=$(uvx --quiet --with "PyJWT==2.13.0" --with "cryptography==50.0.0" python3 - "$APP_ID" "$KEY_PATH" <<'PYEOF'
import jwt, time, sys
app_id = sys.argv[1]
key_path = sys.argv[2]
private_key = open(key_path).read()
now = int(time.time())
payload = {"iat": now - 60, "exp": now + 600, "iss": app_id}
print(jwt.encode(payload, private_key, algorithm="RS256"))
PYEOF
)

if [ -z "$JWT" ]; then
  exit 1
fi

# Get installation ID for this repo
OWNER=$(gh repo view --json owner --jq '.owner.login' 2>/dev/null)
REPO=$(gh repo view --json name --jq '.name' 2>/dev/null)

INSTALLATION_ID=$(curl -s \
  -H "Authorization: Bearer $JWT" \
  -H "Accept: application/vnd.github+json" \
  "https://api.github.com/repos/$OWNER/$REPO/installation" \
  | python3 -c "import json,sys; print(json.load(sys.stdin).get('id',''))" 2>/dev/null)

if [ -z "$INSTALLATION_ID" ]; then
  exit 1
fi

# Exchange for installation token
TOKEN=$(curl -s -X POST \
  -H "Authorization: Bearer $JWT" \
  -H "Accept: application/vnd.github+json" \
  "https://api.github.com/app/installations/$INSTALLATION_ID/access_tokens" \
  | python3 -c "import json,sys; print(json.load(sys.stdin).get('token',''))" 2>/dev/null)

if [ -z "$TOKEN" ]; then
  exit 1
fi

echo "$TOKEN"
