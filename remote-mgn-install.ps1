# remote-mgn-install.ps1
# Installs AWS MGN Agent remotely on one or more Windows servers using WinRM

param(
    [Parameter(Mandatory=$true)]
    [string[]]$ComputerName,   

    [Parameter(Mandatory=$false)]
    [pscredential]$Credential,

    [Parameter(Mandatory=$true)]
    [string]$ActivationCode,

    [Parameter(Mandatory=$true)]
    [string]$ActivationId,

    [Parameter(Mandatory=$true)]
    [string]$Region
)

# -------------------------
# Remote ScriptBlock
# -------------------------
$scriptBlock = {
    param($ActivationCode, $ActivationId, $Region)

    $ErrorActionPreference = "Stop"
    $tempPath = "C:\Windows\Temp"

    New-Item -ItemType Directory -Path $tempPath -Force | Out-Null
    Write-Host "=== Step 1: Installing SSM Agent ===" -ForegroundColor Cyan

    $ssmUrl = "https://amazon-ssm-$Region.s3.$Region.amazonaws.com/latest/windows_amd64/AmazonSSMAgentSetup.exe"
    Invoke-WebRequest -Uri $ssmUrl -OutFile "$tempPath\SSMAgentSetup.exe"

    Start-Process -FilePath "$tempPath\SSMAgentSetup.exe" -ArgumentList @(
        "/S",
        "/v`"/qn ACTIVATIONCODE=$ActivationCode ACTIVATIONID=$ActivationId REGION=$Region`""
    ) -Wait -NoNewWindow

    Write-Host "Waiting for SSM Agent to register..." -ForegroundColor Yellow
    Start-Sleep -Seconds 60

    $ssmService = Get-Service -Name "AmazonSSMAgent" -ErrorAction SilentlyContinue
    if (-not $ssmService) { throw "SSM Agent service not found." }

    if ($ssmService.Status -ne "Running") {
        Write-Host "SSM Agent status: $($ssmService.Status)" -ForegroundColor Red
        Start-Service -Name "AmazonSSMAgent" -ErrorAction Stop
        Start-Sleep -Seconds 10
    }

    Write-Host "SSM Agent installed and registered successfully" -ForegroundColor Green
    Write-Host ""
    Write-Host "=== Next Steps ===" -ForegroundColor Cyan
    Write-Host "1. Find this server in AWS Systems Manager > Fleet Manager"
    Write-Host "2. Run the MGN installation command via SSM Run Command"
    Write-Host "3. Cleanup script will remove SSM Agent after MGN install"

    Remove-Item "$tempPath\SSMAgentSetup.exe" -Force
}

# -------------------------
# LOOP THROUGH ALL COMPUTERS
# -------------------------
foreach ($Computer in $ComputerName) {

    Write-Host ""
    Write-Host "===============================" -ForegroundColor DarkCyan
    Write-Host " Processing $Computer" -ForegroundColor Cyan
    Write-Host "===============================" -ForegroundColor DarkCyan

    Write-Host "Testing WinRM connection to $Computer..." -ForegroundColor Cyan
    try {
        if ($Credential) {
            Test-WSMan -ComputerName $Computer -Credential $Credential -ErrorAction Stop
        } else {
            Test-WSMan -ComputerName $Computer -ErrorAction Stop
        }
        Write-Host "Connection successful" -ForegroundColor Green
    }
    catch {
        Write-Host "Failed to connect to ${Computer}: $($_.Exception.Message)" -ForegroundColor Red
        continue
    }

    Write-Host "Running MGN bootstrap on $Computer..." -ForegroundColor Cyan

    try {
        if ($Credential) {
            Invoke-Command -ComputerName $Computer -Credential $Credential `
                -ScriptBlock $scriptBlock -ArgumentList $ActivationCode, $ActivationId, $Region
        } else {
            Invoke-Command -ComputerName $Computer `
                -ScriptBlock $scriptBlock -ArgumentList $ActivationCode, $ActivationId, $Region
        }

        Write-Host "Remote MGN bootstrap completed on $Computer" -ForegroundColor Green
    }
    catch {
        Write-Host "Error running bootstrap on ${Computer}: $($_.Exception.Message)" -ForegroundColor Red
        continue
    }
} 
