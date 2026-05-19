#!/usr/bin/env bash
set -euo pipefail

AUTH_DOMAIN="auth.company.test-link.xin"
AUTH_ADMIN_DOMAIN="auth-admin.company.test-link.xin"
OPENCLAW_DOMAIN="openclaw.company.test-link.xin"

getent hosts "$AUTH_DOMAIN" "$AUTH_ADMIN_DOMAIN" "$OPENCLAW_DOMAIN" || true

cd /opt/auth-system
cp .env ".env.bak.$(date +%Y%m%d%H%M%S)"

sed -i \
  -e "s|^AUTH_DOMAIN=.*|AUTH_DOMAIN=$AUTH_DOMAIN|" \
  -e "s|^AUTH_ADMIN_DOMAIN=.*|AUTH_ADMIN_DOMAIN=$AUTH_ADMIN_DOMAIN|" \
  -e "s|^OPENCLAW_DOMAIN=.*|OPENCLAW_DOMAIN=$OPENCLAW_DOMAIN|" \
  -e "s|^AUTH_BASE_URL=.*|AUTH_BASE_URL=https://$AUTH_DOMAIN|" \
  -e "s|^AUTH_ADMIN_BASE_URL=.*|AUTH_ADMIN_BASE_URL=https://$AUTH_ADMIN_DOMAIN|" \
  -e "s|^OPENCLAW_BASE_URL=.*|OPENCLAW_BASE_URL=https://$OPENCLAW_DOMAIN|" \
  .env

grep -E '^(AUTH_DOMAIN|AUTH_ADMIN_DOMAIN|OPENCLAW_DOMAIN|AUTH_BASE_URL|AUTH_ADMIN_BASE_URL|OPENCLAW_BASE_URL|HTTP_PORT|HTTPS_PORT)' .env

