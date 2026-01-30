# cleanup-ssm.ps1
# Run via SSM Run Command after MGN agent is confirmed working

$ErrorActionPreference = "Stop"

Write-Host "=== Verifying MGN Agent ===" -ForegroundColor Cyan

# Check MGN agent status
$mgnService = Get-Service -Name "AWS Replication Agent" -ErrorAction SilentlyContinue
if ($mgnService.Status -ne "Running") {
    throw "MGN Agent is not running. Aborting SSM removal."
}

Write-Host "MGN Agent is running" -ForegroundColor Green

Write-Host "=== Removing SSM Agent ===" -ForegroundColor Cyan

# Stop SSM Agent
Stop-Service -Name "AmazonSSMAgent" -Force

# Uninstall SSM Agent
$ssmUninstall = Get-WmiObject -Class Win32_Product | Where-Object { $_.Name -like "*Amazon SSM Agent*" }
if ($ssmUninstall) {
    $ssmUninstall.Uninstall() | Out-Null
}

# Alternative uninstall method
$uninstallPath = "C:\Program Files\Amazon\SSM\Uninstall.exe"
if (Test-Path $uninstallPath) {
    Start-Process -FilePath $uninstallPath -ArgumentList "/S" -Wait -NoNewWindow
}

# Clean up SSM directories
Remove-Item -Path "C:\Program Files\Amazon\SSM" -Recurse -Force -ErrorAction SilentlyContinue
Remove-Item -Path "C:\ProgramData\Amazon\SSM" -Recurse -Force -ErrorAction SilentlyContinue

# Clean up bootstrap directory
Remove-Item -Path "C:\MGN-Bootstrap" -Recurse -Force -ErrorAction SilentlyContinue

Write-Host "SSM Agent removed successfully" -ForegroundColor Green
Write-Host "MGN Agent will continue replication independently" -ForegroundColor Green