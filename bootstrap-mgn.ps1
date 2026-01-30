# bootstrap-mgn.ps1
# Run this on the source server to be migrated

param(
    [Parameter(Mandatory=$true)]
    [string]$ActivationCode,
    
    [Parameter(Mandatory=$true)]
    [string]$ActivationId,
    
    [Parameter(Mandatory=$true)]
    [string]$Region
)

$ErrorActionPreference = "Stop"
$tempPath = "C:\Windows\Temp"

# Create temp directory
New-Item -ItemType Directory -Path $tempPath -Force | Out-Null

Write-Host "=== Step 1: Installing SSM Agent ===" -ForegroundColor Cyan

# Download SSM Agent
$ssmUrl = "https://amazon-ssm-$Region.s3.$Region.amazonaws.com/latest/windows_amd64/AmazonSSMAgentSetup.exe"
Invoke-WebRequest -Uri $ssmUrl -OutFile "$tempPath\SSMAgentSetup.exe"

# Install SSM Agent with hybrid activation
Start-Process -FilePath "$tempPath\SSMAgentSetup.exe" -ArgumentList @(
    "/S",
    "/v`"/qn ACTIVATIONCODE=$ActivationCode ACTIVATIONID=$ActivationId REGION=$Region`""
) -Wait -NoNewWindow

# Wait for SSM agent to register
Write-Host "Waiting for SSM Agent to register..." -ForegroundColor Yellow
Start-Sleep -Seconds 30

# Verify SSM agent is running
$ssmService = Get-Service -Name "AmazonSSMAgent" -ErrorAction SilentlyContinue
if ($ssmService.Status -ne "Running") {
    throw "SSM Agent failed to start"
}

Write-Host "SSM Agent installed and registered successfully" -ForegroundColor Green
Write-Host ""
Write-Host "=== Next Steps ===" -ForegroundColor Cyan
Write-Host "1. Find this server in AWS Systems Manager > Fleet Manager"
Write-Host "2. Run the MGN installation command via SSM Run Command"
Write-Host "3. The cleanup script will remove SSM Agent after MGN is installed"

# Cleanup installer
Remove-Item "$tempPath\SSMAgentSetup.exe" -Force