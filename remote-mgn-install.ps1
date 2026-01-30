# remote-mgn-install.ps1
# Installs AWS MGN Agent remotely on Windows servers using WinRM

param(
    [Parameter(Mandatory=$true)]
    [string]$ComputerName,

    [Parameter(Mandatory=$true)]
    [pscredential]$Credential,

    [Parameter(Mandatory=$true)]
    [string]$ActivationCode,

    [Parameter(Mandatory=$true)]
    [string]$ActivationId,

    [Parameter(Mandatory=$true)]
    [string]$Region
)

# Enable PS remoting if needed (requires admin)
# Enable-PSRemoting -Force -SkipNetworkProfileCheck

# Test connection
Write-Host "Testing WinRM connection to $ComputerName..." -ForegroundColor Cyan
Test-WSMan -ComputerName $ComputerName -Credential $Credential -ErrorAction Stop
Write-Host "Connection successful" -ForegroundColor Green

# Run the bootstrap script remotely
Write-Host "Running MGN bootstrap on $ComputerName..." -ForegroundColor Cyan

$scriptBlock = {
    param($ActivationCode, $ActivationId, $Region)

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
}

Invoke-Command -ComputerName $ComputerName -Credential $Credential -ScriptBlock $scriptBlock -ArgumentList $ActivationCode, $ActivationId, $Region

Write-Host "Remote MGN bootstrap completed on $ComputerName" -ForegroundColor Green</content>
<parameter name="filePath">/Users/dan/Library/CloudStorage/OneDrive-Slalom/Code Development/mgn-windows-agent/remote-mgn-install.ps1