#!/usr/bin/env sh
set -eu

cd "$(dirname "$0")/.."

echo "Validating docker compose config..."
ENV_FILE=".env"
if [ ! -f "$ENV_FILE" ]; then
  ENV_FILE=".env.example"
fi
docker compose --env-file "$ENV_FILE" config --quiet

PYTHON_BIN="$(command -v python3 || command -v python)"

echo "Validating Keycloak realm template JSON..."
"$PYTHON_BIN" -m json.tool keycloak/company-realm.template.json >/dev/null

if [ -f keycloak/realm-export/company-realm.json ]; then
  echo "Validating generated Keycloak realm JSON..."
  "$PYTHON_BIN" -m json.tool keycloak/realm-export/company-realm.json >/dev/null
fi

echo "Validation completed."
