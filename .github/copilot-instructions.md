# AI Coding Guidelines for mgn-windows-agent

## Project Overview
This repository contains a PowerShell bootstrap script (`bootstrap-mgn.ps1`) for deploying AWS Application Migration Service (MGN) agents on Windows servers using SSM hybrid activation. The script automates SSM agent installation and registration for secure, automated MGN deployment.

## Key Architecture Patterns
- **Single-script deployment**: All logic resides in `bootstrap-mgn.ps1` with mandatory parameters for activation code, ID, and region
- **Temp directory management**: Uses `C:\MGN-Bootstrap` for downloads and cleanup
- **Service verification**: Checks SSM agent status after installation using `Get-Service`
- **Error handling**: Strict mode with `$ErrorActionPreference = "Stop"` and explicit error checking

## PowerShell Conventions
- **Parameter validation**: Use `[Parameter(Mandatory=$true)]` for required inputs
- **Silent installations**: Use `/S` and `/qn` flags for quiet MSI installs via `Start-Process`
- **Web downloads**: Prefer `Invoke-WebRequest` with `-OutFile` for AWS S3 resources
- **Service management**: Verify Windows services with `Get-Service -Name "ServiceName"`
- **Colored output**: Use `Write-Host -ForegroundColor` for user feedback (Cyan for steps, Yellow for waits, Green for success)
- **Cleanup**: Remove temp files immediately after use with `Remove-Item -Force`

## AWS Integration Patterns
- **SSM URLs**: Construct regional S3 URLs like `https://amazon-ssm-$Region.s3.$Region.amazonaws.com/latest/windows_amd64/AmazonSSMAgentSetup.exe`
- **Activation parameters**: Pass ACTIVATIONCODE, ACTIVATIONID, and REGION to installer
- **Hybrid activation**: Designed for on-premises servers without direct AWS connectivity

## Development Workflow
- **Testing**: Run script locally with test parameters to verify parameter handling and error paths
- **Validation**: Check service status and cleanup behavior on test systems
- **AWS setup**: Use README.md commands to create SSM activations and IAM roles before deployment

## File References
- [bootstrap-mgn.ps1](bootstrap-mgn.ps1): Main deployment script with parameter handling and installation logic
- [README.md](README.md): AWS setup instructions and IAM policy examples</content>
<parameter name="filePath">/Users/dan/Library/CloudStorage/OneDrive-Slalom/Code Development/mgn-windows-agent/.github/copilot-instructions.md