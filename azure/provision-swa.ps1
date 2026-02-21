#!/usr/bin/env pwsh
## provision-swa.ps1
## Creates the Azure Static Web App for game.maassel.dev (Free tier).
## Run once. Requires: az login, correct subscription set.
##
## Usage: .\azure\provision-swa.ps1 [-ResourceGroup "my-rg"]

param(
    [string]$ResourceGroup = "platformer-game-rg",
    [string]$Location = "eastus2",
    [string]$SiteName = "platformer-game"
)

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

Write-Host "🚀 Provisioning Azure SWA for game.maassel.dev..." -ForegroundColor Cyan

# 1. Create resource group if it doesn't exist
$rg = az group show --name $ResourceGroup 2>$null | ConvertFrom-Json
if (-not $rg) {
    Write-Host "Creating resource group $ResourceGroup..." -ForegroundColor Yellow
    az group create --name $ResourceGroup --location $Location | Out-Null
}

# 2. Deploy bicep
Write-Host "Deploying bicep template..." -ForegroundColor Yellow
$deployment = az deployment group create `
    --resource-group $ResourceGroup `
    --template-file "$PSScriptRoot\swa.bicep" `
    --parameters siteName=$SiteName location=$Location `
    --query "properties.outputs" `
    -o json | ConvertFrom-Json

$hostname = $deployment.defaultHostname.value
$token = $deployment.deploymentToken.value

Write-Host ""
Write-Host "✅ SWA provisioned!" -ForegroundColor Green
Write-Host "   Default URL: https://$hostname"
Write-Host "   Deploy token: $token"
Write-Host ""
Write-Host "📋 Next steps:" -ForegroundColor Cyan
Write-Host "   1. Add GitHub secret: AZURE_STATIC_WEB_APPS_API_TOKEN = $token"
Write-Host "      -> https://github.com/nsmaassel/platformer-game/settings/secrets/actions"
Write-Host ""
Write-Host "   2. Add DNS CNAME record:"
Write-Host "      Name:  game"
Write-Host "      Value: $hostname"
Write-Host "      (In your DNS provider for maassel.dev)"
Write-Host ""
Write-Host "   3. Push a commit with dist/ folder to trigger the deploy workflow."
