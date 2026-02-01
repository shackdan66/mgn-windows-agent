# bootstrap-ssm.ps1
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

# Ensure TLS 1.2 for secure downloads
[System.Net.ServicePointManager]::SecurityProtocol = 'TLS12'

# Use system temp directory for setup
$tempPath = $env:TEMP + "\ssm"

# Create temp directory
New-Item -ItemType Directory -Path $tempPath -Force | Out-Null
Push-Location -Path $tempPath

Write-Host "=== Step 1: Installing SSM Agent ===" -ForegroundColor Cyan
Write-Host "Temp directory: $tempPath" -ForegroundColor Gray
Write-Host "Activation ID: $ActivationId" -ForegroundColor Gray
Write-Host "Region: $Region" -ForegroundColor Gray

# Download SSM Setup CLI
Write-Host "Downloading SSM Setup CLI..." -ForegroundColor Cyan
$ssmUrl = "https://amazon-ssm-$Region.s3.$Region.amazonaws.com/latest/windows_amd64/ssm-setup-cli.exe"
$ssmExePath = $tempPath + "\ssm-setup-cli.exe"

try {
    (New-Object System.Net.WebClient).DownloadFile($ssmUrl, $ssmExePath)
    Write-Host "SSM Setup CLI downloaded successfully" -ForegroundColor Green
} catch {
    throw "Failed to download SSM Setup CLI from $ssmUrl : $_"
}

# Register SSM Agent with hybrid activation
Write-Host "Registering SSM Agent with hybrid activation..." -ForegroundColor Cyan
$registerProcess = Start-Process -FilePath $ssmExePath -ArgumentList @(
    "-register",
    "-activation-code=`"$ActivationCode`"",
    "-activation-id=`"$ActivationId`"",
    "-region=`"$Region`""
) -Wait -NoNewWindow -PassThru

if ($registerProcess.ExitCode -ne 0) {
    Write-Host "SSM setup exited with code: $($registerProcess.ExitCode)" -ForegroundColor Red
}

Write-Host "Waiting for SSM Agent registration..." -ForegroundColor Yellow
Start-Sleep -Seconds 30

# Verify registration
Write-Host "Verifying registration status..." -ForegroundColor Cyan
$registrationFile = $env:ProgramData + "\Amazon\SSM\InstanceData\registration"
if (Test-Path $registrationFile) {
    Write-Host "Registration data found:" -ForegroundColor Green
    Get-Content $registrationFile
} else {
    Write-Host "Registration file not found at: $registrationFile" -ForegroundColor Yellow
}

Start-Sleep -Seconds 30

# Verify SSM agent is running
$ssmService = Get-Service -Name "AmazonSSMAgent" -ErrorAction SilentlyContinue
if (-not $ssmService) {
    throw "SSM Agent service not found. Installation may have failed."
}

if ($ssmService.Status -ne "Running") {
    Write-Host "SSM Agent status: $($ssmService.Status)" -ForegroundColor Red
    Write-Host "Checking service startup logs..." -ForegroundColor Yellow
    
    # Display recent error log entries
    if (Test-Path $logPath) {
        Write-Host "Recent SSM Agent log errors:" -ForegroundColor Red
        Get-Content $logPath -Tail 30 | Select-String -Pattern "Error|Failed|Exception" | ForEach-Object { Write-Host $_ -ForegroundColor Red }
    }
    
    # Try to start the service manually
    try {
        Write-Host "Attempting manual service start..." -ForegroundColor Yellow
        Start-Service -Name "AmazonSSMAgent" -ErrorAction Stop
        Start-Sleep -Seconds 15
        $ssmService.Refresh()
        if ($ssmService.Status -eq "Running") {
            Write-Host "SSM Agent started successfully after manual start" -ForegroundColor Green
        } else {
            Write-Host "Full SSM Agent log:" -ForegroundColor Red
            if (Test-Path $logPath) {
                Get-Content $logPath | ForEach-Object { Write-Host $_ -ForegroundColor Red }
            }
            throw "SSM Agent failed to start even after manual attempt. Check logs above for details."
        }
    } catch {
        Write-Host "Failed to start SSM Agent manually: $($_.Exception.Message)" -ForegroundColor Red
        Write-Host "Troubleshooting: 1) Verify ActivationCode and ActivationId are correct" -ForegroundColor Yellow
        Write-Host "Troubleshooting: 2) Confirm IAM role SSM Agent role exists with proper trust policy" -ForegroundColor Yellow
        Write-Host "Troubleshooting: 3) Ensure server has outbound connectivity to SSM endpoints" -ForegroundColor Yellow
        throw "SSM Agent failed to start. See troubleshooting steps above."
    }
}

Write-Host "SSM Agent installed and registered successfully" -ForegroundColor Green
Write-Host ""
Write-Host "=== Next Steps ===" -ForegroundColor Cyan
Write-Host "1. Find this server in AWS Systems Manager > Fleet Manager"
Write-Host "2. Run the MGN installation command via SSM Run Command"
Write-Host "3. The cleanup script will remove SSM Agent after MGN is installed"

# Cleanup and return to original directory
Pop-Location
Remove-Item -Path $tempPath -Recurse -Force -ErrorAction SilentlyContinue 


VRT-RDS-00B-WAT 