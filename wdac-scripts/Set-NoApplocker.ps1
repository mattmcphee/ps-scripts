<# 
.SYNOPSIS 
    Overwriting or Merge with current Managed Installer (MI) AppLocker Rules
.DESCRIPTION 
    Configure AppLocker xml to add Intune and SCCM as a managed installer, sets EnforcementMode="Enabled"
    Include Dll, EXE benign Deny rules for %OSDRIVE%
    Use -Merge to merge with existing rules, otherwise it will overwrite.
.PARAMETER Set
    -Set this will merge the policies. If not used default behaviour will be to merge
.PARAMETER Mode
    -Mode (AuditOnly or Enabled) configures the managed installer enforcement mode. Defaults to AuditOnly
.OUTPUTS 
    C:\Windows\Temp\AppLockerBeforeScript.xml
    C:\Windows\Temp\AppLockerMIPolicy.xml (gets deleted)
    C:\Windows\Temp\AppLockerAfterScript.xml
.EXAMPLE
    Set-ManagedInstaller-Intune_SCCM_AppLocker_BenignDeny-Signed.ps1
    Will Merge these settings to the current AppLocker settings 
.EXAMPLE
    Set-ManagedInstaller-Intune_SCCM_AppLocker_BenignDeny-Signed.ps1 -Mode AuditOnly -Set
    This will overwrite the current settings and Managed installer Enforcement Mode to AuditOnly
.NOTES
       Name:            Set-ManagedInstaller-Intune_SCCM_AppLocker_BenignDeny-Signed.ps1
       Version:         1.0
       Author:          Victor Rodriguez
       Creation Date:   1.0 - 18/07/2024
                        1.1 - 19/08/2024 - MM - ManagedInstaller ccm version max changed to any maximum
                        1.2 - 21/08/2024 - MM - IntuneWindowsAgent.exe max version changed to any maximum
#>     

[CmdletBinding(DefaultParameterSetName="Default")]
param (
    # Mode - whether to set the managedinstaller setting to auditonly or enabled
    [Parameter(Mandatory=$true)]
    [ValidateSet("Enabled","AuditOnly")]
    [string]
    $Mode,
    # Set - whether to overwrite or merge
    [Parameter(Mandatory=$true)]
    [ValidateSet("Merge","Overwrite")]
    [string]
    $Set
)
Write-Host "Setting ManagedInstaller EnforcementMode to $Mode"

# Configure new managed installer xml
$AppLockerMIPolicy = `
@"
<AppLockerPolicy Version="1"></AppLockerPolicy>
"@

# Document current settings
Get-AppLockerPolicy -Effective -XML > C:\Windows\Temp\AppLockerBeforeScript.xml

# Create the new xml
$AppLockerMIPolicy | Out-File -FilePath C:\Windows\Temp\AppLockerMIPolicy.xml

if ($Set -eq "Overwrite") {
    Set-AppLockerPolicy -XmlPolicy C:\Windows\Temp\AppLockerMIPolicy.xml `
        -ErrorAction SilentlyContinue
    Write-Host "Overwriting MI AppLocker Rules"
} else {
    Set-AppLockerPolicy -XmlPolicy C:\Windows\Temp\AppLockerMIPolicy.xml `
        -Merge -ErrorAction SilentlyContinue
    Write-Host "Merging MI AppLocker Rules"
}

Start-Process -FilePath "$env:windir\System32\appidtel.exe" `
    -ArgumentList "start -mionly" | Wait-Process
Remove-Item -Path C:\Windows\Temp\AppLockerMIPolicy.xml
Start-Sleep -Seconds 10
Get-AppLockerPolicy -Effective -XML > C:\Windows\Temp\AppLockerAfterScript.xml
Write-Host "Before and After Applocker xml can be found here C:\Windows\Temp\"