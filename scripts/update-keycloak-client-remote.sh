#!/usr/bin/env bash
set -euo pipefail

cd /opt/auth-system
set -a
# shellcheck disable=SC1091
. ./.env
set +a

docker compose up -d --force-recreate keycloak nginx

echo "Waiting for Keycloak..."
for _ in $(seq 1 60); do
  if docker inspect --format '{{.State.Health.Status}}' auth-keycloak 2>/dev/null | grep -q healthy; then
    break
  fi
  sleep 5
done

docker exec auth-keycloak /opt/keycloak/bin/kcadm.sh config credentials \
  --server http://localhost:8080 \
  --realm master \
  --user "$KEYCLOAK_ADMIN" \
  --password "$KEYCLOAK_ADMIN_PASSWORD"

client_id="$(docker exec auth-keycloak /opt/keycloak/bin/kcadm.sh get clients \
  -r company \
  -q clientId="$KEYCLOAK_CLIENT_ID" \
  --fields id \
  --format csv \
  --noquotes | tail -n 1)"

docker exec auth-keycloak /opt/keycloak/bin/kcadm.sh update "clients/$client_id" \
  -r company \
  -s "redirectUris=[\"$OPENCLAW_BASE_URL/oauth2/callback\"]" \
  -s "webOrigins=[\"$OPENCLAW_BASE_URL\"]" \
  -s "attributes.post.logout.redirect.uris=$OPENCLAW_BASE_URL/*"

docker compose up -d --force-recreate oauth2-proxy nginx

docker compose ps

