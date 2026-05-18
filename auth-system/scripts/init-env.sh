#!/usr/bin/env sh
set -eu

cd "$(dirname "$0")/.."

FORCE="${1:-}"
if [ -f .env ] && [ "$FORCE" != "--force" ]; then
  echo ".env already exists. Use --force to overwrite it." >&2
  exit 1
fi

cookie_secret="$(openssl rand -hex 16)"
client_secret="$(openssl rand -hex 32)"
postgres_password="$(openssl rand -base64 24)"
admin_password="$(openssl rand -base64 24)"

cp .env.example .env
sed -i "s|CHANGE_ME_32_CHAR_COOKIE_SECRET|$cookie_secret|g" .env
sed -i "s|CHANGE_ME_OPENCLAW_AUTH_PROXY_SECRET|$client_secret|g" .env
sed -i "s|CHANGE_ME_POSTGRES_PASSWORD|$postgres_password|g" .env
sed -i "s|CHANGE_ME_KEYCLOAK_ADMIN_PASSWORD|$admin_password|g" .env

openclaw_base_url="$(grep '^OPENCLAW_BASE_URL=' .env | head -n1 | cut -d= -f2-)"
sed \
  -e "s|CHANGE_ME_OPENCLAW_AUTH_PROXY_SECRET|$client_secret|g" \
  -e "s|OPENCLAW_BASE_URL_PLACEHOLDER|$openclaw_base_url|g" \
  keycloak/company-realm.template.json > keycloak/realm-export/company-realm.json

echo "Created .env"
echo "Generated client secret and keycloak/realm-export/company-realm.json"
echo "Replace CHANGE_ME_TEST_USER_PASSWORD before first import, or create users manually after startup."
