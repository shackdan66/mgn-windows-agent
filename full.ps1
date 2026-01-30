$ErrorActionPreference = "Stop"
$region = "us-west-2"
$mgnRoleArn = "arn:aws:iam::103891662525:role/MGN-Agent"
$tempPath = "C:\MGN-Install"

try {
    # Create temp directory
    if (Test-Path $tempPath) {
        Remove-Item -Path $tempPath -Recurse -Force
    }
    New-Item -ItemType Directory -Path $tempPath -Force | Out-Null
    
    # Install AWS Tools for PowerShell if needed
    Write-Host "=== Checking AWS PowerShell Module ==="
    if (-not (Get-Module -ListAvailable -Name AWS.Tools.SecurityToken)) {
        Write-Host "Installing AWS.Tools.SecurityToken module..."
        [Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
        Install-PackageProvider -Name NuGet -MinimumVersion 2.8.5.201 -Force -Scope AllUsers | Out-Null
        Install-Module -Name AWS.Tools.Common -Force -Scope AllUsers -AllowClobber
        Install-Module -Name AWS.Tools.SecurityToken -Force -Scope AllUsers -AllowClobber
    }
    
    Import-Module AWS.Tools.SecurityToken
    
    Write-Host "=== Verifying SSM Credentials ==="
    $identity = Get-STSCallerIdentity -Region $region
    Write-Host "Current Identity: $($identity.Arn)"
    
    Write-Host "=== Assuming MGN-Agent Role ==="
    $assumedRole = Use-STSRole `
        -RoleArn $mgnRoleArn `
        -RoleSessionName "MGN-Install-$env:COMPUTERNAME" `
        -DurationInSeconds 3600 `
        -Region $region
    
    if (-not $assumedRole.Credentials) {
        throw "Failed to assume MGN-Agent role"
    }
    
    $accessKey = $assumedRole.Credentials.AccessKeyId
    $secretKey = $assumedRole.Credentials.SecretAccessKey
    $sessionToken = $assumedRole.Credentials.SessionToken
    
    Write-Host "Successfully assumed MGN-Agent role"
    Write-Host "Credentials expire: $($assumedRole.Credentials.Expiration)"
    
    Write-Host "=== Downloading MGN Agent ==="
    [Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
    $mgnUrl = "https://aws-application-migration-service-$region.s3.$region.amazonaws.com/latest/windows/AwsReplicationWindowsInstaller.exe"
    
    Invoke-WebRequest -Uri $mgnUrl -OutFile "$tempPath\AwsReplicationWindowsInstaller.exe"
    
    if (-not (Test-Path "$tempPath\AwsReplicationWindowsInstaller.exe")) {
        throw "Failed to download MGN installer"
    }
    
    $installerSize = (Get-Item "$tempPath\AwsReplicationWindowsInstaller.exe").Length
    Write-Host "Installer downloaded: $([math]::Round($installerSize/1MB, 2)) MB"
    
    Write-Host "=== Installing MGN Agent ==="
    $installArgs = "--region $region --aws-access-key-id $accessKey --aws-secret-access-key $secretKey --aws-session-token $sessionToken --no-prompt"
    
    $process = Start-Process -FilePath "$tempPath\AwsReplicationWindowsInstaller.exe" `
        -ArgumentList $installArgs `
        -Wait -PassThru -NoNewWindow
    
    Write-Host "Installer Exit Code: $($process.ExitCode)"
    
    if ($process.ExitCode -ne 0) {
        throw "MGN Agent installation failed with exit code: $($process.ExitCode)"
    }
    
    Write-Host "=== Waiting for Service to Start ==="
    Start-Sleep -Seconds 30
    
    $mgnService = Get-Service -Name "AWS Replication Agent" -ErrorAction Stop
    
    if ($mgnService.Status -eq "Running") {
        Write-Host "=== SUCCESS: MGN Agent Installed and Running ===" -ForegroundColor Green
    } else {
        throw "MGN Agent service is not running. Status: $($mgnService.Status)"
    }
    
} catch {
    Write-Error "Installation failed: $_"
    exit 1
} finally {
    # Secure cleanup
    Remove-Variable -Name accessKey, secretKey, sessionToken, assumedRole -ErrorAction SilentlyContinue
    Remove-Item -Path $tempPath -Recurse -Force -ErrorAction SilentlyContinue
}