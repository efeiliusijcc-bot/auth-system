param(
    [string]$EnvFile = ".env",
    [switch]$Force
)

$ErrorActionPreference = "Stop"
$root = Split-Path -Parent $PSScriptRoot
$target = Join-Path $root $EnvFile
$example = Join-Path $root ".env.example"

if ((Test-Path -LiteralPath $target) -and -not $Force) {
    throw "$target already exists. Use -Force to overwrite it."
}

$cookieSecret = openssl rand -base64 32
$clientSecret = openssl rand -hex 32
$postgresPassword = openssl rand -base64 24
$adminPassword = openssl rand -base64 24

$content = Get-Content -LiteralPath $example -Raw
$content = $content.Replace("CHANGE_ME_32_BYTE_BASE64_COOKIE_SECRET", $cookieSecret)
$content = $content.Replace("CHANGE_ME_OPENCLAW_AUTH_PROXY_SECRET", $clientSecret)
$content = $content.Replace("CHANGE_ME_POSTGRES_PASSWORD", $postgresPassword)
$content = $content.Replace("CHANGE_ME_KEYCLOAK_ADMIN_PASSWORD", $adminPassword)

Set-Content -LiteralPath $target -Value $content -Encoding UTF8

$realmTemplatePath = Join-Path $root "keycloak\company-realm.template.json"
$realmPath = Join-Path $root "keycloak\realm-export\company-realm.json"
$realm = Get-Content -LiteralPath $realmTemplatePath -Raw
$openClawBaseUrl = (($content -split "`n") | Where-Object { $_ -match '^OPENCLAW_BASE_URL=' } | Select-Object -First 1) -replace '^OPENCLAW_BASE_URL=', ''
$realm = $realm.Replace("CHANGE_ME_OPENCLAW_AUTH_PROXY_SECRET", $clientSecret)
$realm = $realm.Replace("OPENCLAW_BASE_URL_PLACEHOLDER", $openClawBaseUrl.Trim())
Set-Content -LiteralPath $realmPath -Value $realm -Encoding UTF8

Write-Host "Created $target"
Write-Host "Generated client secret and updated keycloak/realm-export/company-realm.json"
Write-Host "Replace CHANGE_ME_TEST_USER_PASSWORD in keycloak/realm-export/company-realm.json before first import, or create users manually after startup."
