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
#>     

[CmdletBinding(DefaultParameterSetName="Default")]
param (
    [ValidateSet("Enabled","AuditOnly")] $Mode = "AuditOnly",
    [switch] $Set = $false
)
Write-Host "Setting ManagedInstaller EnforcementMode to $Mode"

# Configure new managed installer xml
$AppLockerMIPolicy= 
@"
<AppLockerPolicy Version="1">
    <RuleCollection Type="Appx" EnforcementMode="NotConfigured"/>
    <RuleCollection Type="Dll" EnforcementMode="AuditOnly">
        <FilePathRule Id="86f235ad-3f7b-4121-bc95-ea8bde3a5db5" Name="Dummy Rule" Description="" UserOrGroupSid="S-1-1-0" Action="Deny">
            <Conditions>
                <FilePathCondition Path="%OSDRIVE%\ThisWillBeBlocked.dll"/>
            </Conditions>
        </FilePathRule>
        <RuleCollectionExtensions>
            <ThresholdExtensions>
                <Services EnforcementMode="Enabled"/>
            </ThresholdExtensions>
            <RedstoneExtensions>
                <SystemApps Allow="Enabled"/>
            </RedstoneExtensions>
        </RuleCollectionExtensions>
    </RuleCollection>
    <RuleCollection Type="Exe" EnforcementMode="AuditOnly">
        <FilePathRule Id="9420c496-046d-45ab-bd0e-455b2649e41e" Name="Dummy Rule" Description="" UserOrGroupSid="S-1-1-0" Action="Deny">
            <Conditions>
                <FilePathCondition Path="%OSDRIVE%\ThisWillBeBlocked.exe"/>
            </Conditions>
        </FilePathRule>
        <RuleCollectionExtensions>
            <ThresholdExtensions>
                <Services EnforcementMode="Enabled"/>
            </ThresholdExtensions>
            <RedstoneExtensions>
                <SystemApps Allow="Enabled"/>
            </RedstoneExtensions>
        </RuleCollectionExtensions>
    </RuleCollection>
    <RuleCollection Type="ManagedInstaller" EnforcementMode="Enabled">
        <FilePublisherRule Id="18674b3c-24a2-4f4b-89e5-e59c0bd5a271" Name="CCMSETUP.EXE version 5.0.9106.1000 exactly in MICROSOFT CONFIGURATION MANAGER from O=MICROSOFT CORPORATION, L=REDMOND, S=WASHINGTON, C=US" Description="" UserOrGroupSid="S-1-1-0" Action="Allow">
            <Conditions>
                <FilePublisherCondition PublisherName="O=MICROSOFT CORPORATION, L=REDMOND, S=WASHINGTON, C=US" ProductName="*" BinaryName="CCMSETUP.EXE">
                    <BinaryVersionRange LowSection="5.0.9106.1000" HighSection="5.0.9106.1000"/>
                </FilePublisherCondition>
            </Conditions>
        </FilePublisherRule>
        <FilePublisherRule Id="44bc26ae-171e-4d9b-98f3-f9bffdf5b7e3" Name="CCMEXEC.EXE version 5.0.9106.1000 exactly in MICROSOFT CONFIGURATION MANAGER from O=MICROSOFT CORPORATION, L=REDMOND, S=WASHINGTON, C=US" Description="" UserOrGroupSid="S-1-1-0" Action="Allow">
            <Conditions>
                <FilePublisherCondition PublisherName="O=MICROSOFT CORPORATION, L=REDMOND, S=WASHINGTON, C=US" ProductName="*" BinaryName="CCMEXEC.EXE">
                    <BinaryVersionRange LowSection="5.0.9106.1000" HighSection="5.0.9106.1000"/>
                </FilePublisherCondition>
            </Conditions>
        </FilePublisherRule>
        <FilePublisherRule Id="6ead5a35-5bac-4fe4-a0a4-be8885012f87" Name="CMM - CCMEXEC.EXE, 5.0.0.0+, Microsoft signed" Description="" UserOrGroupSid="S-1-1-0" Action="Allow">
            <Conditions>
                <FilePublisherCondition PublisherName="O=MICROSOFT CORPORATION, L=REDMOND, S=WASHINGTON, C=US" ProductName="*" BinaryName="CCMEXEC.EXE">
                    <BinaryVersionRange LowSection="5.0.0.0" HighSection="*"/>
                </FilePublisherCondition>
            </Conditions>
        </FilePublisherRule>
        <FilePublisherRule Id="8e23170d-e0b7-4711-b6d0-d208c960f30e" Name="CCM - CCMSETUP.EXE, 5.0.0.0+, Microsoft signed" Description="" UserOrGroupSid="S-1-1-0" Action="Allow">
            <Conditions>
                <FilePublisherCondition PublisherName="O=MICROSOFT CORPORATION, L=REDMOND, S=WASHINGTON, C=US" ProductName="*" BinaryName="CCMSETUP.EXE">
                    <BinaryVersionRange LowSection="5.0.0.0" HighSection="*"/>
                </FilePublisherCondition>
            </Conditions>
        </FilePublisherRule>
        <FilePublisherRule Id="f7d5c414-e933-4dc1-96b2-a2c90223846b" Name="MICROSOFT.MANAGEMENT.SERVICES.INTUNEWINDOWSAGENT.EXE version 1.76.152.0 exactly in MICROSOFT® INTUNE™ from O=MICROSOFT CORPORATION, L=REDMOND, S=WASHINGTON, C=US" Description="" UserOrGroupSid="S-1-1-0" Action="Allow">
            <Conditions>
                <FilePublisherCondition PublisherName="O=MICROSOFT CORPORATION, L=REDMOND, S=WASHINGTON, C=US" ProductName="MICROSOFT® INTUNE™" BinaryName="MICROSOFT.MANAGEMENT.SERVICES.INTUNEWINDOWSAGENT.EXE">
                    <BinaryVersionRange LowSection="1.76.152.0" HighSection="1.76.152.0"/>
                </FilePublisherCondition>
            </Conditions>
        </FilePublisherRule>
    </RuleCollection>
    <RuleCollection Type="Msi" EnforcementMode="NotConfigured"/>
    <RuleCollection Type="Script" EnforcementMode="NotConfigured"/>
</AppLockerPolicy>
"@

# Document current settings
Get-AppLockerPolicy -Effective -XML >  C:\Windows\Temp\AppLockerBeforeScript.xml

# Create the new xml
$AppLockerMIPolicy | Out-File -FilePath C:\Windows\Temp\AppLockerMIPolicy.xml

if($Set)
{
    Set-AppLockerPolicy -XmlPolicy C:\Windows\Temp\AppLockerMIPolicy.xml -ErrorAction SilentlyContinue
    Write-Host "Overwriting MI AppLocker Rules"
}
else 
{
    Set-AppLockerPolicy -XmlPolicy C:\Windows\Temp\AppLockerMIPolicy.xml -Merge -ErrorAction SilentlyContinue
    Write-Host "Merging MI AppLocker Rules"
}

Start-Process -FilePath "$env:windir\System32\appidtel.exe" -ArgumentList "start -mionly" | Wait-Process
Remove-Item -Path C:\Windows\Temp\AppLockerMIPolicy.xml
Start-Sleep 30
Get-AppLockerPolicy -Effective -XML > C:\Windows\Temp\AppLockerAfterScript.xml
Write-Host "Before and After Applocker xml can be found here C:\Windows\Temp\"
