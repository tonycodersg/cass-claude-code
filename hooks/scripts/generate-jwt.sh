#!/usr/bin/env bash
# Generates a GitHub App JWT. Called by bot-token.sh with CASS_APP_ID and
# CASS_KEY_PATH set in the environment. Outputs the JWT to stdout.
uvx --quiet --with "PyJWT==2.13.0" --with "cryptography==50.0.0" python3 <<'PYEOF'
import jwt, time, os
app_id = os.environ['CASS_APP_ID']
key_path = os.environ['CASS_KEY_PATH']
private_key = open(key_path).read()
now = int(time.time())
payload = {"iat": now - 60, "exp": now + 600, "iss": app_id}
print(jwt.encode(payload, private_key, algorithm="RS256"))
PYEOF
