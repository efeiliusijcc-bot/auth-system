$ErrorActionPreference = "Stop"
$root = Split-Path -Parent $PSScriptRoot

Push-Location $root
try {
    $envFile = ".env"
    if (-not (Test-Path -LiteralPath $envFile)) {
        $envFile = ".env.example"
    }

    Write-Host "Validating docker compose config..."
    docker compose --env-file $envFile config --quiet

    Write-Host "Validating Keycloak realm JSON..."
    Get-Content -LiteralPath "keycloak\company-realm.template.json" -Raw | ConvertFrom-Json | Out-Null
    if (Test-Path -LiteralPath "keycloak\realm-export\company-realm.json") {
        Get-Content -LiteralPath "keycloak\realm-export\company-realm.json" -Raw | ConvertFrom-Json | Out-Null
    }

    Write-Host "Rendering nginx template with current .env..."
    docker compose --env-file $envFile config | Out-Null

    Write-Host "Validation completed."
}
finally {
    Pop-Location
}
