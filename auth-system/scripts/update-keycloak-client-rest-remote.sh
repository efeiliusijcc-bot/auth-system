#!/usr/bin/env bash
set -euo pipefail

cd /opt/auth-system
set -a
# shellcheck disable=SC1091
. ./.env
set +a

python3 - <<'PY'
import json
import os
import ssl
import urllib.parse
import urllib.request

auth_base = os.environ["AUTH_BASE_URL"]
openclaw_base = os.environ["OPENCLAW_BASE_URL"]
admin_user = os.environ["KEYCLOAK_ADMIN"]
admin_password = os.environ["KEYCLOAK_ADMIN_PASSWORD"]
client_id = os.environ["KEYCLOAK_CLIENT_ID"]

ctx = ssl._create_unverified_context()

def request(method, url, data=None, token=None):
    headers = {}
    body = None
    if data is not None:
        if isinstance(data, dict):
            body = urllib.parse.urlencode(data).encode()
            headers["Content-Type"] = "application/x-www-form-urlencoded"
        else:
            body = json.dumps(data).encode()
            headers["Content-Type"] = "application/json"
    if token:
        headers["Authorization"] = f"Bearer {token}"
    req = urllib.request.Request(url, data=body, headers=headers, method=method)
    with urllib.request.urlopen(req, context=ctx, timeout=30) as resp:
        raw = resp.read()
        if not raw:
            return None
        return json.loads(raw)

token_response = request("POST", f"{auth_base}/realms/master/protocol/openid-connect/token", {
    "client_id": "admin-cli",
    "username": admin_user,
    "password": admin_password,
    "grant_type": "password",
})
token = token_response["access_token"]

clients = request("GET", f"{auth_base}/admin/realms/company/clients?clientId={urllib.parse.quote(client_id)}", token=token)
if not clients:
    raise SystemExit(f"client not found: {client_id}")

client = clients[0]
client["redirectUris"] = [f"{openclaw_base}/oauth2/callback"]
client["webOrigins"] = [openclaw_base]
attrs = client.setdefault("attributes", {})
attrs["post.logout.redirect.uris"] = f"{openclaw_base}/*"

request("PUT", f"{auth_base}/admin/realms/company/clients/{client['id']}", data=client, token=token)
print(json.dumps({
    "clientId": client_id,
    "redirectUris": client["redirectUris"],
    "webOrigins": client["webOrigins"],
    "postLogout": attrs["post.logout.redirect.uris"],
}, ensure_ascii=False))
PY

docker compose up -d --force-recreate oauth2-proxy nginx
docker compose ps

