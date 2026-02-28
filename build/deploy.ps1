# ElvUIChat Deployment Script
# Deploys the addon to WoW's AddOns folder

param(
    [string]$SourceDir = "source\ElvUIChat",
    [string]$TargetDir = $null
)

# Load configuration if target not specified
if (-not $TargetDir) {
    $configPath = Join-Path $PSScriptRoot "config.ps1"
    if (Test-Path $configPath) {
        . $configPath
        $TargetDir = $env:ELVUICHAT_DEPLOY_PATH
    } else {
        Write-Host "ERROR: No target directory specified and no config.ps1 found." -ForegroundColor Red
        Write-Host "Create build/config.ps1 or specify target: .\deploy.ps1 -TargetDir 'C:\Path\To\WoW\AddOns\ElvUIChat'" -ForegroundColor Yellow
        exit 1
    }
}

# Resolve full paths
$SourcePath = Join-Path (Get-Location) $SourceDir | Resolve-Path -ErrorAction SilentlyContinue
if (-not $SourcePath) {
    Write-Host "ERROR: Source directory not found: $SourceDir" -ForegroundColor Red
    exit 1
}

Write-Host "`nElvUIChat Deployment" -ForegroundColor Cyan
Write-Host "===================" -ForegroundColor Cyan
Write-Host "Source: $SourcePath" -ForegroundColor White
Write-Host "Target: $TargetDir" -ForegroundColor White

# Delete existing target if it exists
if (Test-Path $TargetDir) {
    Write-Host "`nRemoving existing addon..." -ForegroundColor Yellow
    Remove-Item -Path $TargetDir -Recurse -Force
}

# Deploy
Write-Host "Deploying addon..." -ForegroundColor Green
New-Item -ItemType Directory -Path $TargetDir -Force | Out-Null
Copy-Item -Path "$SourcePath\*" -Destination $TargetDir -Recurse -Force

# Verify
if (Test-Path "$TargetDir\ElvUIChat.toc") {
    $tocVersion = Select-String -Path "$TargetDir\ElvUIChat.toc" -Pattern "## Interface: (\d+)" | ForEach-Object { $_.Matches.Groups[1].Value }
    $addonVersion = Select-String -Path "$TargetDir\ElvUIChat.toc" -Pattern "## Version: ([\d.]+)" | ForEach-Object { $_.Matches.Groups[1].Value }
    
    Write-Host "`nDeployment successful!" -ForegroundColor Green
    Write-Host "  Interface: $tocVersion" -ForegroundColor Gray
    Write-Host "  Version: $addonVersion" -ForegroundColor Gray
    Write-Host "`nReady to test in-game with /reload" -ForegroundColor Cyan
} else {
    Write-Host "`nDeployment failed - TOC file not found in target" -ForegroundColor Red
    exit 1
}
