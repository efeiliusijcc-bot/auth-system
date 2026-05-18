param(
    [string[]]$DnsName = @("openclaw.company.local", "auth.company.local", "auth-admin.company.local"),
    [string]$OutDir = "certs",
    [string]$Name = "openclaw"
)

$ErrorActionPreference = "Stop"
$root = Split-Path -Parent $PSScriptRoot
$targetDir = Join-Path $root $OutDir
New-Item -ItemType Directory -Force -Path $targetDir | Out-Null

$crtPath = Join-Path $targetDir "$Name.crt"
$keyPath = Join-Path $targetDir "$Name.key"
$san = ($DnsName | ForEach-Object { "DNS:$_" }) -join ","

openssl req -x509 -nodes -newkey rsa:2048 -days 730 `
    -keyout $keyPath `
    -out $crtPath `
    -subj "/CN=$($DnsName[0])" `
    -addext "subjectAltName=$san"

Write-Host "Created $crtPath and $keyPath"
