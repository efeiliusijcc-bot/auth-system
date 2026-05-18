param(
    [string]$OpenClawUrl = "https://openclaw.company.local",
    [string]$AuthUrl = "https://auth.company.local",
    [switch]$SkipCertificateCheck
)

$ErrorActionPreference = "Stop"

if ($SkipCertificateCheck) {
    if ("TrustAllCertsPolicy" -as [type]) {
        [System.Net.ServicePointManager]::CertificatePolicy = New-Object TrustAllCertsPolicy
    }
    else {
        Add-Type @"
using System.Net;
using System.Security.Cryptography.X509Certificates;
public class TrustAllCertsPolicy : ICertificatePolicy {
    public bool CheckValidationResult(ServicePoint srvPoint, X509Certificate certificate, WebRequest request, int certificateProblem) {
        return true;
    }
}
"@
        [System.Net.ServicePointManager]::CertificatePolicy = New-Object TrustAllCertsPolicy
    }
}

function Invoke-Check {
    param(
        [string]$Name,
        [scriptblock]$Action
    )

    Write-Host "==> $Name"
    & $Action
}

$common = @{
    MaximumRedirection = 0
    TimeoutSec = 15
    ErrorAction = "SilentlyContinue"
}

if ($SkipCertificateCheck) {
    [System.Net.ServicePointManager]::ServerCertificateValidationCallback = { $true }
}

Invoke-Check "OpenClaw unauthenticated request should redirect or return 401/403" {
    $response = Invoke-WebRequest -Uri $OpenClawUrl @common
    Write-Host "Status:" $response.StatusCode
    if ($response.Headers.Location) {
        Write-Host "Location:" $response.Headers.Location
    }
}

Invoke-Check "Keycloak discovery should be reachable" {
    $issuer = "$AuthUrl/realms/company/.well-known/openid-configuration"
    $response = Invoke-WebRequest -Uri $issuer -TimeoutSec 15
    Write-Host "Status:" $response.StatusCode
    $json = $response.Content | ConvertFrom-Json
    Write-Host "Issuer:" $json.issuer
}

Invoke-Check "Container status" {
    docker compose ps
}
