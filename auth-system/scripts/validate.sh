#!/usr/bin/env sh
set -eu

cd "$(dirname "$0")/.."

echo "Validating docker compose config..."
ENV_FILE=".env"
if [ ! -f "$ENV_FILE" ]; then
  ENV_FILE=".env.example"
fi
docker compose --env-file "$ENV_FILE" config --quiet

echo "Validating Keycloak realm template JSON..."
python -m json.tool keycloak/company-realm.template.json >/dev/null

if [ -f keycloak/realm-export/company-realm.json ]; then
  echo "Validating generated Keycloak realm JSON..."
  python -m json.tool keycloak/realm-export/company-realm.json >/dev/null
fi

echo "Validation completed."
