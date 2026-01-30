$ErrorActionPreference = "Stop"
$region = "us-east-1"
$mgnRoleArn = "arn:aws:iam::103891662525:role/MGN-Agent"

try {
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
    
    Write-Host "=== Step 1: Get Current Identity (SSM-Hybrid-Agent) ==="
    $currentIdentity = Get-STSCallerIdentity -Region $region
    Write-Host "Account:  $($currentIdentity.Account)"
    Write-Host "Arn:      $($currentIdentity.Arn)"
    Write-Host "UserId:   $($currentIdentity.UserId)"
    
    Write-Host "`n=== Step 2: Assume MGN-Agent Role ==="
    $assumedRole = Use-STSRole `
        -RoleArn $mgnRoleArn `
        -RoleSessionName "Test-$env:COMPUTERNAME" `
        -DurationInSeconds 900 `
        -Region $region
    
    Write-Host "AccessKeyId:     $($assumedRole.Credentials.AccessKeyId)"
    Write-Host "Expiration:      $($assumedRole.Credentials.Expiration)"
    Write-Host "SessionToken:    $($assumedRole.Credentials.SessionToken.Substring(0,20))..."
    
    Write-Host "`n=== Step 3: Verify Assumed Role Identity ==="
    $assumedIdentity = Get-STSCallerIdentity `
        -AccessKey $assumedRole.Credentials.AccessKeyId `
        -SecretKey $assumedRole.Credentials.SecretAccessKey `
        -SessionToken $assumedRole.Credentials.SessionToken `
        -Region $region
    
    Write-Host "Account:  $($assumedIdentity.Account)"
    Write-Host "Arn:      $($assumedIdentity.Arn)"
    Write-Host "UserId:   $($assumedIdentity.UserId)"
    
    Write-Host "`n=== SUCCESS: Assume Role Working ===" -ForegroundColor Green
    
} catch {
    Write-Host "`n=== FAILED ===" -ForegroundColor Red
    Write-Error $_
    exit 1
}