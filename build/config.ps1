# ElvUIChat Deployment Configuration

# Default WoW installation path
# Edit this to match your WoW installation location
$WOW_PATH = "D:\Games\World of Warcraft\_retail_\Interface\AddOns\ElvUIChat"

# Alternative paths (uncomment and use the one that matches your setup):
# $WOW_PATH = "C:\Program Files (x86)\World of Warcraft\_retail_\Interface\AddOns\ElvUIChat"
# $WOW_PATH = "$env:USERPROFILE\Documents\World of Warcraft\_retail_\Interface\AddOns\ElvUIChat"
# $WOW_PATH = "C:\Games\World of Warcraft\_retail_\Interface\AddOns\ElvUIChat"

# Export for use in other scripts
$env:ELVUICHAT_DEPLOY_PATH = $WOW_PATH
Write-Host "Deployment path configured: $WOW_PATH" -ForegroundColor Green
