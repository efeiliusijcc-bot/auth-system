#!/usr/bin/env sh
set -eu

cd "$(dirname "$0")/.."
mkdir -p certs

openssl req -x509 -nodes -newkey rsa:2048 -days 730 \
  -keyout certs/openclaw.key \
  -out certs/openclaw.crt \
  -subj "/CN=openclaw.company.local" \
  -addext "subjectAltName=DNS:openclaw.company.local,DNS:auth.company.local,DNS:auth-admin.company.local"

echo "Created certs/openclaw.crt and certs/openclaw.key"

