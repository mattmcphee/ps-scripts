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
        <FilePublisherRule Id="f7d5c414-e933-4dc1-96b2-a2c90223846b" Name="MICROSOFT.MANAGEMENT.SERVICES.INTUNEWINDOWSAGENT.EXE version 1.76.152.0 exactly in MICROSOFTÂ® INTUNEâ„¢ from O=MICROSOFT CORPORATION, L=REDMOND, S=WASHINGTON, C=US" Description="" UserOrGroupSid="S-1-1-0" Action="Allow">
            <Conditions>
                <FilePublisherCondition PublisherName="O=MICROSOFT CORPORATION, L=REDMOND, S=WASHINGTON, C=US" ProductName="MICROSOFTÂ® INTUNEâ„¢" BinaryName="MICROSOFT.MANAGEMENT.SERVICES.INTUNEWINDOWSAGENT.EXE">
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

# SIG # Begin signature block
# MIIlywYJKoZIhvcNAQcCoIIlvDCCJbgCAQExDzANBglghkgBZQMEAgEFADB5Bgor
# BgEEAYI3AgEEoGswaTA0BgorBgEEAYI3AgEeMCYCAwEAAAQQH8w7YFlLCE63JNLG
# KX7zUQIBAAIBAAIBAAIBAAIBADAxMA0GCWCGSAFlAwQCAQUABCBDvWD7xtY8NCyj
# rw/OM81dS+5M2wXZtF0K6tY4jJAAbaCCH9gwggWNMIIEdaADAgECAhAOmxiO+dAt
# 5+/bUOIIQBhaMA0GCSqGSIb3DQEBDAUAMGUxCzAJBgNVBAYTAlVTMRUwEwYDVQQK
# EwxEaWdpQ2VydCBJbmMxGTAXBgNVBAsTEHd3dy5kaWdpY2VydC5jb20xJDAiBgNV
# BAMTG0RpZ2lDZXJ0IEFzc3VyZWQgSUQgUm9vdCBDQTAeFw0yMjA4MDEwMDAwMDBa
# Fw0zMTExMDkyMzU5NTlaMGIxCzAJBgNVBAYTAlVTMRUwEwYDVQQKEwxEaWdpQ2Vy
# dCBJbmMxGTAXBgNVBAsTEHd3dy5kaWdpY2VydC5jb20xITAfBgNVBAMTGERpZ2lD
# ZXJ0IFRydXN0ZWQgUm9vdCBHNDCCAiIwDQYJKoZIhvcNAQEBBQADggIPADCCAgoC
# ggIBAL/mkHNo3rvkXUo8MCIwaTPswqclLskhPfKK2FnC4SmnPVirdprNrnsbhA3E
# MB/zG6Q4FutWxpdtHauyefLKEdLkX9YFPFIPUh/GnhWlfr6fqVcWWVVyr2iTcMKy
# unWZanMylNEQRBAu34LzB4TmdDttceItDBvuINXJIB1jKS3O7F5OyJP4IWGbNOsF
# xl7sWxq868nPzaw0QF+xembud8hIqGZXV59UWI4MK7dPpzDZVu7Ke13jrclPXuU1
# 5zHL2pNe3I6PgNq2kZhAkHnDeMe2scS1ahg4AxCN2NQ3pC4FfYj1gj4QkXCrVYJB
# MtfbBHMqbpEBfCFM1LyuGwN1XXhm2ToxRJozQL8I11pJpMLmqaBn3aQnvKFPObUR
# WBf3JFxGj2T3wWmIdph2PVldQnaHiZdpekjw4KISG2aadMreSx7nDmOu5tTvkpI6
# nj3cAORFJYm2mkQZK37AlLTSYW3rM9nF30sEAMx9HJXDj/chsrIRt7t/8tWMcCxB
# YKqxYxhElRp2Yn72gLD76GSmM9GJB+G9t+ZDpBi4pncB4Q+UDCEdslQpJYls5Q5S
# UUd0viastkF13nqsX40/ybzTQRESW+UQUOsxxcpyFiIJ33xMdT9j7CFfxCBRa2+x
# q4aLT8LWRV+dIPyhHsXAj6KxfgommfXkaS+YHS312amyHeUbAgMBAAGjggE6MIIB
# NjAPBgNVHRMBAf8EBTADAQH/MB0GA1UdDgQWBBTs1+OC0nFdZEzfLmc/57qYrhwP
# TzAfBgNVHSMEGDAWgBRF66Kv9JLLgjEtUYunpyGd823IDzAOBgNVHQ8BAf8EBAMC
# AYYweQYIKwYBBQUHAQEEbTBrMCQGCCsGAQUFBzABhhhodHRwOi8vb2NzcC5kaWdp
# Y2VydC5jb20wQwYIKwYBBQUHMAKGN2h0dHA6Ly9jYWNlcnRzLmRpZ2ljZXJ0LmNv
# bS9EaWdpQ2VydEFzc3VyZWRJRFJvb3RDQS5jcnQwRQYDVR0fBD4wPDA6oDigNoY0
# aHR0cDovL2NybDMuZGlnaWNlcnQuY29tL0RpZ2lDZXJ0QXNzdXJlZElEUm9vdENB
# LmNybDARBgNVHSAECjAIMAYGBFUdIAAwDQYJKoZIhvcNAQEMBQADggEBAHCgv0Nc
# Vec4X6CjdBs9thbX979XB72arKGHLOyFXqkauyL4hxppVCLtpIh3bb0aFPQTSnov
# Lbc47/T/gLn4offyct4kvFIDyE7QKt76LVbP+fT3rDB6mouyXtTP0UNEm0Mh65Zy
# oUi0mcudT6cGAxN3J0TU53/oWajwvy8LpunyNDzs9wPHh6jSTEAZNUZqaVSwuKFW
# juyk1T3osdz9HNj0d1pcVIxv76FQPfx2CWiEn2/K2yCNNWAcAgPLILCsWKAOQGPF
# mCLBsln1VWvPJ6tsds5vIy30fnFqI2si/xK4VC0nftg62fC2h5b9W9FcrBjDTZ9z
# twGpn1eqXijiuZQwggXbMIIDw6ADAgECAhMgAAAAIlpsblRztOpCAAAAAAAiMA0G
# CSqGSIb3DQEBCwUAMFwxEjAQBgoJkiaJk/IsZAEZFgJhdTETMBEGCgmSJomT8ixk
# ARkWA2NvbTETMBEGCgmSJomT8ixkARkWA2JtZDEcMBoGA1UEAxMTQk1EIElzc3Vp
# bmcgQ0EgMSBHNDAeFw0yMzExMDEwMzMzNTlaFw0yNjEwMzEwMzMzNTlaMBAxDjAM
# BgNVBAMTBXZyLnN1MIIBIjANBgkqhkiG9w0BAQEFAAOCAQ8AMIIBCgKCAQEAv0lq
# s2/OstnpIbGu3fOqrJnB7hAColK+IPmk+hUSv0Om0jSjgG4PwtiPD6r578uN+fDJ
# T0/Z3My/1Lh3c5qd53WUNpTnSc/bw+S0+ScZXOqRi0yzqoLcuR9uMv0kkS5K5t3D
# Tto+hRPQphLRDPJ1cbXLVZK9cN7JvFf2Zmyl0vG9A/a3Rn2SPgishK7S54CyK3KF
# VMGsry4idyddzOC2b5YLxf1KIY+vZlod0DEkE9HTnUFhH3wxdlCLTYnK7S78RkZ5
# H4ePpvkt7JkhZgwALBdRek6cTg8kVlyOysJSCsys0VnEn3FWGwS71RCFn+qTSpDb
# lIz1nDEIibWmRqUqTQIDAQABo4IB4DCCAdwwOwYJKwYBBAGCNxUHBC4wLAYkKwYB
# BAGCNxUIn7s/hPCFSPWNB4G5wyiG3u99gQqB7JtY8L49AgFkAgEDMBMGA1UdJQQM
# MAoGCCsGAQUFBwMDMAsGA1UdDwQEAwIHgDAbBgkrBgEEAYI3FQoEDjAMMAoGCCsG
# AQUFBwMDMB0GA1UdDgQWBBTdJR19f/vUWP/+91vV3rF8DloSKTAfBgNVHSMEGDAW
# gBTN0yUMxwnCtpXIbxeaoir2yfeRNjBKBgNVHR8EQzBBMD+gPaA7hjlodHRwOi8v
# cGtpLmJtZC5jb20uYXUvcGtpL0JNRCUyMElzc3VpbmclMjBDQSUyMDElMjBHNC5j
# cmwwVQYIKwYBBQUHAQEESTBHMEUGCCsGAQUFBzAChjlodHRwOi8vcGtpLmJtZC5j
# b20uYXUvcGtpL0JNRCUyMElzc3VpbmclMjBDQSUyMDElMjBHNC5jcnQwKwYDVR0R
# BCQwIqAgBgorBgEEAYI3FAIDoBIMEHZyLnN1QGJtZC5jb20uYXUwTgYJKwYBBAGC
# NxkCBEEwP6A9BgorBgEEAYI3GQIBoC8ELVMtMS01LTIxLTM2NDY4ODYzLTExMTEy
# Mzk1NDUtMTIzMjgyODQzNi0zNDc3ODANBgkqhkiG9w0BAQsFAAOCAgEAkAoU/+jB
# z8BV1KDz7iyeWzEz89Ri7g5v0rZ2awkEXdHmO+ivrBrn3Wg2HySeW3epzgUxEce/
# mSutlQvcjdFsGMme243PeJuAj+lAgKcAPrbXPxpf0JsE/9HrAcSTYjlVITt0S5OG
# ylC6MBX5VcAwmogNIYy3bk6b42mpTzDYh+XiyeS7kjfT1nEW8rLTH7fIqJsSMX42
# gDUIFs1YFSzX0bAuhqYjNd/LtlxeetWFk6zsVN671RTzTTwOn5nbmxnGEWGAagDD
# Y0duVfQnsZAGZOrUC+zAtpYw/FerwX9OhgHjk9P8pcTwgCVSTlppb46nBPlW5BxY
# fLtGf2k0pRLtU0sRrtmH4qrsc6tXqmYeFWCJ1Pupm67InI4rRkgGrJbcqczvru5c
# e4Ukp4WFsWFaW0jrLQcPtKk5evxot31ko3D/oscg86PQimeYod1qBiJizQqdnrxQ
# keiOFe46wA2/zLYnzzddW2LOoW6QdILT/YHGhkyzUSxvSA+p6lLBCNwPTebygqdN
# oKN3t/rM+V1Z/poO6r4W0ruqnbe4G5mnFZFIY8A+u3AXLjhot/57xjUVquarVWzT
# 0QDCY0Gj57GI0drKQj+jdD245AGLLpr4Wdn+WLa918l5EZarM1TXw0vs0MyobnYV
# DlLxOrLmO4taPyfOGEyXvL+KnoqfDQk/lVQwggauMIIElqADAgECAhAHNje3JFR8
# 2Ees/ShmKl5bMA0GCSqGSIb3DQEBCwUAMGIxCzAJBgNVBAYTAlVTMRUwEwYDVQQK
# EwxEaWdpQ2VydCBJbmMxGTAXBgNVBAsTEHd3dy5kaWdpY2VydC5jb20xITAfBgNV
# BAMTGERpZ2lDZXJ0IFRydXN0ZWQgUm9vdCBHNDAeFw0yMjAzMjMwMDAwMDBaFw0z
# NzAzMjIyMzU5NTlaMGMxCzAJBgNVBAYTAlVTMRcwFQYDVQQKEw5EaWdpQ2VydCwg
# SW5jLjE7MDkGA1UEAxMyRGlnaUNlcnQgVHJ1c3RlZCBHNCBSU0E0MDk2IFNIQTI1
# NiBUaW1lU3RhbXBpbmcgQ0EwggIiMA0GCSqGSIb3DQEBAQUAA4ICDwAwggIKAoIC
# AQDGhjUGSbPBPXJJUVXHJQPE8pE3qZdRodbSg9GeTKJtoLDMg/la9hGhRBVCX6SI
# 82j6ffOciQt/nR+eDzMfUBMLJnOWbfhXqAJ9/UO0hNoR8XOxs+4rgISKIhjf69o9
# xBd/qxkrPkLcZ47qUT3w1lbU5ygt69OxtXXnHwZljZQp09nsad/ZkIdGAHvbREGJ
# 3HxqV3rwN3mfXazL6IRktFLydkf3YYMZ3V+0VAshaG43IbtArF+y3kp9zvU5Emfv
# DqVjbOSmxR3NNg1c1eYbqMFkdECnwHLFuk4fsbVYTXn+149zk6wsOeKlSNbwsDET
# qVcplicu9Yemj052FVUmcJgmf6AaRyBD40NjgHt1biclkJg6OBGz9vae5jtb7IHe
# IhTZgirHkr+g3uM+onP65x9abJTyUpURK1h0QCirc0PO30qhHGs4xSnzyqqWc0Jo
# n7ZGs506o9UD4L/wojzKQtwYSH8UNM/STKvvmz3+DrhkKvp1KCRB7UK/BZxmSVJQ
# 9FHzNklNiyDSLFc1eSuo80VgvCONWPfcYd6T/jnA+bIwpUzX6ZhKWD7TA4j+s4/T
# Xkt2ElGTyYwMO1uKIqjBJgj5FBASA31fI7tk42PgpuE+9sJ0sj8eCXbsq11GdeJg
# o1gJASgADoRU7s7pXcheMBK9Rp6103a50g5rmQzSM7TNsQIDAQABo4IBXTCCAVkw
# EgYDVR0TAQH/BAgwBgEB/wIBADAdBgNVHQ4EFgQUuhbZbU2FL3MpdpovdYxqII+e
# yG8wHwYDVR0jBBgwFoAU7NfjgtJxXWRM3y5nP+e6mK4cD08wDgYDVR0PAQH/BAQD
# AgGGMBMGA1UdJQQMMAoGCCsGAQUFBwMIMHcGCCsGAQUFBwEBBGswaTAkBggrBgEF
# BQcwAYYYaHR0cDovL29jc3AuZGlnaWNlcnQuY29tMEEGCCsGAQUFBzAChjVodHRw
# Oi8vY2FjZXJ0cy5kaWdpY2VydC5jb20vRGlnaUNlcnRUcnVzdGVkUm9vdEc0LmNy
# dDBDBgNVHR8EPDA6MDigNqA0hjJodHRwOi8vY3JsMy5kaWdpY2VydC5jb20vRGln
# aUNlcnRUcnVzdGVkUm9vdEc0LmNybDAgBgNVHSAEGTAXMAgGBmeBDAEEAjALBglg
# hkgBhv1sBwEwDQYJKoZIhvcNAQELBQADggIBAH1ZjsCTtm+YqUQiAX5m1tghQuGw
# GC4QTRPPMFPOvxj7x1Bd4ksp+3CKDaopafxpwc8dB+k+YMjYC+VcW9dth/qEICU0
# MWfNthKWb8RQTGIdDAiCqBa9qVbPFXONASIlzpVpP0d3+3J0FNf/q0+KLHqrhc1D
# X+1gtqpPkWaeLJ7giqzl/Yy8ZCaHbJK9nXzQcAp876i8dU+6WvepELJd6f8oVInw
# 1YpxdmXazPByoyP6wCeCRK6ZJxurJB4mwbfeKuv2nrF5mYGjVoarCkXJ38SNoOeY
# +/umnXKvxMfBwWpx2cYTgAnEtp/Nh4cku0+jSbl3ZpHxcpzpSwJSpzd+k1OsOx0I
# SQ+UzTl63f8lY5knLD0/a6fxZsNBzU+2QJshIUDQtxMkzdwdeDrknq3lNHGS1yZr
# 5Dhzq6YBT70/O3itTK37xJV77QpfMzmHQXh6OOmc4d0j/R0o08f56PGYX/sr2H7y
# Rp11LB4nLCbbbxV7HhmLNriT1ObyF5lZynDwN7+YAN8gFk8n+2BnFqFmut1VwDop
# hrCYoCvtlUG3OtUVmDG0YgkPCr2B2RP+v6TR81fZvAT6gt4y3wSJ8ADNXcL50CN/
# AAvkdgIm2fBldkKmKYcJRyvmfxqkhQ/8mJb2VVQrH4D6wPIOK+XW+6kvRBVK5xMO
# Hds3OBqhK/bt1nz8MIIGwjCCBKqgAwIBAgIQBUSv85SdCDmmv9s/X+VhFjANBgkq
# hkiG9w0BAQsFADBjMQswCQYDVQQGEwJVUzEXMBUGA1UEChMORGlnaUNlcnQsIElu
# Yy4xOzA5BgNVBAMTMkRpZ2lDZXJ0IFRydXN0ZWQgRzQgUlNBNDA5NiBTSEEyNTYg
# VGltZVN0YW1waW5nIENBMB4XDTIzMDcxNDAwMDAwMFoXDTM0MTAxMzIzNTk1OVow
# SDELMAkGA1UEBhMCVVMxFzAVBgNVBAoTDkRpZ2lDZXJ0LCBJbmMuMSAwHgYDVQQD
# ExdEaWdpQ2VydCBUaW1lc3RhbXAgMjAyMzCCAiIwDQYJKoZIhvcNAQEBBQADggIP
# ADCCAgoCggIBAKNTRYcdg45brD5UsyPgz5/X5dLnXaEOCdwvSKOXejsqnGfcYhVY
# wamTEafNqrJq3RApih5iY2nTWJw1cb86l+uUUI8cIOrHmjsvlmbjaedp/lvD1isg
# HMGXlLSlUIHyz8sHpjBoyoNC2vx/CSSUpIIa2mq62DvKXd4ZGIX7ReoNYWyd/nFe
# xAaaPPDFLnkPG2ZS48jWPl/aQ9OE9dDH9kgtXkV1lnX+3RChG4PBuOZSlbVH13gp
# OWvgeFmX40QrStWVzu8IF+qCZE3/I+PKhu60pCFkcOvV5aDaY7Mu6QXuqvYk9R28
# mxyyt1/f8O52fTGZZUdVnUokL6wrl76f5P17cz4y7lI0+9S769SgLDSb495uZBkH
# NwGRDxy1Uc2qTGaDiGhiu7xBG3gZbeTZD+BYQfvYsSzhUa+0rRUGFOpiCBPTaR58
# ZE2dD9/O0V6MqqtQFcmzyrzXxDtoRKOlO0L9c33u3Qr/eTQQfqZcClhMAD6FaXXH
# g2TWdc2PEnZWpST618RrIbroHzSYLzrqawGw9/sqhux7UjipmAmhcbJsca8+uG+W
# 1eEQE/5hRwqM/vC2x9XH3mwk8L9CgsqgcT2ckpMEtGlwJw1Pt7U20clfCKRwo+wK
# 8REuZODLIivK8SgTIUlRfgZm0zu++uuRONhRB8qUt+JQofM604qDy0B7AgMBAAGj
# ggGLMIIBhzAOBgNVHQ8BAf8EBAMCB4AwDAYDVR0TAQH/BAIwADAWBgNVHSUBAf8E
# DDAKBggrBgEFBQcDCDAgBgNVHSAEGTAXMAgGBmeBDAEEAjALBglghkgBhv1sBwEw
# HwYDVR0jBBgwFoAUuhbZbU2FL3MpdpovdYxqII+eyG8wHQYDVR0OBBYEFKW27xPn
# 783QZKHVVqllMaPe1eNJMFoGA1UdHwRTMFEwT6BNoEuGSWh0dHA6Ly9jcmwzLmRp
# Z2ljZXJ0LmNvbS9EaWdpQ2VydFRydXN0ZWRHNFJTQTQwOTZTSEEyNTZUaW1lU3Rh
# bXBpbmdDQS5jcmwwgZAGCCsGAQUFBwEBBIGDMIGAMCQGCCsGAQUFBzABhhhodHRw
# Oi8vb2NzcC5kaWdpY2VydC5jb20wWAYIKwYBBQUHMAKGTGh0dHA6Ly9jYWNlcnRz
# LmRpZ2ljZXJ0LmNvbS9EaWdpQ2VydFRydXN0ZWRHNFJTQTQwOTZTSEEyNTZUaW1l
# U3RhbXBpbmdDQS5jcnQwDQYJKoZIhvcNAQELBQADggIBAIEa1t6gqbWYF7xwjU+K
# PGic2CX/yyzkzepdIpLsjCICqbjPgKjZ5+PF7SaCinEvGN1Ott5s1+FgnCvt7T1I
# jrhrunxdvcJhN2hJd6PrkKoS1yeF844ektrCQDifXcigLiV4JZ0qBXqEKZi2V3mP
# 2yZWK7Dzp703DNiYdk9WuVLCtp04qYHnbUFcjGnRuSvExnvPnPp44pMadqJpddNQ
# 5EQSviANnqlE0PjlSXcIWiHFtM+YlRpUurm8wWkZus8W8oM3NG6wQSbd3lqXTzON
# 1I13fXVFoaVYJmoDRd7ZULVQjK9WvUzF4UbFKNOt50MAcN7MmJ4ZiQPq1JE3701S
# 88lgIcRWR+3aEUuMMsOI5ljitts++V+wQtaP4xeR0arAVeOGv6wnLEHQmjNKqDbU
# uXKWfpd5OEhfysLcPTLfddY2Z1qJ+Panx+VPNTwAvb6cKmx5AdzaROY63jg7B145
# WPR8czFVoIARyxQMfq68/qTreWWqaNYiyjvrmoI1VygWy2nyMpqy0tg6uLFGhmu6
# F/3Ed2wVbK6rr3M66ElGt9V/zLY4wNjsHPW2obhDLN9OTH0eaHDAdwrUAuBcYLso
# /zjlUlrWrBciI0707NMX+1Br/wd3H3GXREHJuEbTbDJ8WC9nR2XlG3O2mflrLAZG
# 70Ee8PBf4NvZrZCARK+AEEGKMIIG7DCCBNSgAwIBAgITNQAAAALQZkt+ZnXzywAA
# AAAAAjANBgkqhkiG9w0BAQsFADBXMRIwEAYKCZImiZPyLGQBGRYCYXUxEzARBgoJ
# kiaJk/IsZAEZFgNjb20xEzARBgoJkiaJk/IsZAEZFgNibWQxFzAVBgNVBAMTDkJN
# RCBSb290IENBIEc0MB4XDTIzMDYxMTIzMDgyNFoXDTMzMDYxMTIzMTgyNFowXDES
# MBAGCgmSJomT8ixkARkWAmF1MRMwEQYKCZImiZPyLGQBGRYDY29tMRMwEQYKCZIm
# iZPyLGQBGRYDYm1kMRwwGgYDVQQDExNCTUQgSXNzdWluZyBDQSAxIEc0MIICIjAN
# BgkqhkiG9w0BAQEFAAOCAg8AMIICCgKCAgEAz8x/9sgDhYPEIfxgruf/qdWngrJq
# 3rMif2LPSj8rZ+btT9Gy9S+M+8E3sy2R7SzYqVE3QU7DOifIAJ6e0/NZf/iz4kKC
# gGBhOhw+z06OoN6u4q+Kr7e0iLzoWHgEAi0Q8FqPvjFiIZdZLmY+e4+xmY2Zvp6a
# WzedaN2qeFVX2Ygq5cLy22WwUyJAYW4vbUEC/hiLAcYjf0pxPvoAzvb9l/Zh8yaE
# k1v7hIvtKt3okHImeWDk2frSRko0MB/xaIL3dww0d+q9RWMu2IIQ4+9vLUeYQCwj
# txuakuMLdq83eRMGJXQeCexo/S411LB/UsHpy8PdSX2CB4kCdQgV7+gtKiFm1DFD
# RhdbLBocC6tLxz8qUBokUFzVdP7Zc3OJvj0savWgK9tFQZwTnUMBGvwhzWFBccGf
# 2HDYFLwIKxReZQWKgEo+frtSoAQ6OYiuwqWeujIg2c28SHLuy1PsmHFx11T1mWPI
# tn0EtVxwAgAmTPLSG+BMLVyGtQcHGwKE0wN4nB0YDUQYwmzLp0Brp9MkxUBdK1qQ
# DLI8tFGTXkdJnElAhzqMSurXTM/E5W7341x7qpXSt1EsawyK9u0fkuoSdyLxzkQt
# CVsfjFRstjSXnJ7memCejpxCnQehik0xnZU91VGqMi7V3ChfDdcXAx4OxU28s9ID
# yX819Y43q4RE3aECAwEAAaOCAaowggGmMBAGCSsGAQQBgjcVAQQDAgEAMB0GA1Ud
# DgQWBBTN0yUMxwnCtpXIbxeaoir2yfeRNjCBgwYDVR0gBHwwejB4BggqAwSLL0NZ
# BTBsMDoGCCsGAQUFBwICMC4eLABMAGUAZwBhAGwAIABQAG8AbABpAGMAeQAgAFMA
# dABhAHQAZQBtAGUAbgB0MC4GCCsGAQUFBwIBFiJodHRwOi8vcGtpLmJtZC5jb20u
# YXUvcGtpL2Nwcy5odG1sMBkGCSsGAQQBgjcUAgQMHgoAUwB1AGIAQwBBMAsGA1Ud
# DwQEAwIBhjAPBgNVHRMBAf8EBTADAQH/MB8GA1UdIwQYMBaAFPYnl2aA7inf9Q3I
# 6drjUTr3ksg0MEMGA1UdHwQ8MDowOKA2oDSGMmh0dHA6Ly9wa2kuYm1kLmNvbS5h
# dS9wa2kvQk1EJTIwUm9vdCUyMENBJTIwRzQuY3JsME4GCCsGAQUFBwEBBEIwQDA+
# BggrBgEFBQcwAoYyaHR0cDovL3BraS5ibWQuY29tLmF1L3BraS9CTUQlMjBSb290
# JTIwQ0ElMjBHNC5jcnQwDQYJKoZIhvcNAQELBQADggIBACLP3NoCk2HYRG2qqJur
# Cda7Fyz19BWlaCG8eTovb3PxyTR42lGmq86vMY5cfDJVAFsN85qb4+CMXxhEGpwk
# XVywXX7oyWr4vFAbG10A+s0+Ow/5s3+Dffa+aG8TpsPdw/xQ0mRZWTgF1Nipu846
# nUJi/K0gXdEZVBXaguMKH0N5CzCsyR538NsQLjYILYwwm67R1VuZN0rBEPcC5ohF
# pDOYFuiYwMCik7TCdkktOpfJQRyKO0GUsmXCD8CIiJ4GtNZtaRmje7ldAlVe5PEn
# i8G9Tx4Lj4KN+W3hswCKvezUllVnNIXGe7Mv86DfBIwMoiLnYTv4ScQH7IRgLkkw
# ALZsnst7rDW/xqLGxS4VIvILz6L5G5oXCVGKJpFlXwoVF8OzArf/Zd5tnTeB8oO7
# 2JsjZfM3P2qdFfhei9G3c7CJF0+gwRA3FvbvKMEY6NsoNYkMU2s5iLj8MO039EFD
# 1Rc+oJ5FpefIoTt5OOXt8t5vuT3BMIptYTrhi9MY05bE/EamtpcSvlb3qH1tH3P3
# K832i8APMrmzzDmwmMbO0b5tA2K09uBk3XSRvbvWwa0DxbJ8jgJrkUtVOzBhC1Y7
# NqjsYixoRMUb4WEt932PdySlyiZaZ6NMC1y730PPHR7Lm+zEp2PFX4LTfukm+Ejh
# GM4078bHsoSVuINSm78vDX2eMYIFSTCCBUUCAQEwczBcMRIwEAYKCZImiZPyLGQB
# GRYCYXUxEzARBgoJkiaJk/IsZAEZFgNjb20xEzARBgoJkiaJk/IsZAEZFgNibWQx
# HDAaBgNVBAMTE0JNRCBJc3N1aW5nIENBIDEgRzQCEyAAAAAiWmxuVHO06kIAAAAA
# ACIwDQYJYIZIAWUDBAIBBQCggYQwGAYKKwYBBAGCNwIBDDEKMAigAoAAoQKAADAZ
# BgkqhkiG9w0BCQMxDAYKKwYBBAGCNwIBBDAcBgorBgEEAYI3AgELMQ4wDAYKKwYB
# BAGCNwIBFTAvBgkqhkiG9w0BCQQxIgQgzIcJ2zD8BY9RP4Vxnp24WNxZ/iiMT/+3
# GQGR7H/r3WAwDQYJKoZIhvcNAQEBBQAEggEAp+YYOr7m3yajr4/0SWEkaBhOdFc0
# dejWLE9IzRhzGOrQZt6n8WpXgbI5cCAuXAXEbfqL6N9NLWZoXXjaNMzmFJCSa2bl
# B0kj5oVNfrsrsYtWhbPKr22g8b795HDcNQo8mcEGR2ZXooJVJO6AybuBrv1f7dPT
# /5ZUfN8pkXjbXr/zNOe6sRLawDaqttU6eR5++BEX1StI/yv/9Aqcm6kc0ktLyDgy
# f6gego3yJCaK4REoTqWST74WQab7gNuB3Apw/nxAfiMMuGRuXP+6TgRV+kKZFPdY
# Yxda/26pRJ2hCFL+1Y4BpxR3tcaqZJ9XELxAqMJStxHwji4FxQlC/fgRdKGCAyAw
# ggMcBgkqhkiG9w0BCQYxggMNMIIDCQIBATB3MGMxCzAJBgNVBAYTAlVTMRcwFQYD
# VQQKEw5EaWdpQ2VydCwgSW5jLjE7MDkGA1UEAxMyRGlnaUNlcnQgVHJ1c3RlZCBH
# NCBSU0E0MDk2IFNIQTI1NiBUaW1lU3RhbXBpbmcgQ0ECEAVEr/OUnQg5pr/bP1/l
# YRYwDQYJYIZIAWUDBAIBBQCgaTAYBgkqhkiG9w0BCQMxCwYJKoZIhvcNAQcBMBwG
# CSqGSIb3DQEJBTEPFw0yNDA3MjMwMjAzMzhaMC8GCSqGSIb3DQEJBDEiBCCueR1y
# RzRxinzTyffSl8T7v7xzmnUotK+p6Ozmsctj7zANBgkqhkiG9w0BAQEFAASCAgBY
# lezwX7DuFnnA+E7r2NmiOlXbZzMgNhMxgkKBev+4KyQMLTJTL4WgptXUW4soBPmq
# gZ8X2+M3qyJN1b9CeBHh68sxJByxyD0KJHVbEG+Yhx8MSG/mziM4//gi8t8/MSRe
# ri2ODz26sYhE+gvJonUsvcgensFuQ9WliWwWev82RgRXKASgSkwiGGPUEZya2q02
# gPIgN5MxTkS3pI8LebVsN07REDwMWqDg8q4zvrCIAE/Fa1IMKOV75iidGbKrKB4+
# CFMYNBGFLaQR8GkF1AnzA6stoDwZ6EJuuY95tpEbiqUBne5UQKzknyFF7jGLf/9f
# J9VEvXXXQ2IxIOhuSAlZjtsiNdJsH0YspQbjoL1+wg2ccePDlmDczS3kIqiJE64H
# DU3m2r8H+eV2TFZshzmNW/w4apCqm+SmY2CtIWH9k7AM5PotVoFvzz9ihtzz0bVJ
# YwSpSimuptQx70BcywKQHNDBgRPMtxS/NUW5uCGDD/DD0JTwd5ZyrdJsXvi0Hf3b
# xFj4t4mjf5Q+qYIzkz1JxxUl2dGfK9mLy1x5HHSIc0sbNyjSu7A8ZrIzTJJFt8FB
# /xLW2+wWkJe0vgR1qwCyEcuvL4X8CAQpp3n2VjDsy6A12OVAvZq6OOuqbl4WulEv
# ZxXq0ZMeMLpgW0MDEwEsENvlenTkasm55XnXDq5RGw==
# SIG # End signature block
