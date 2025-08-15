<##
.SYNOPSIS
Configures OpenVPN client on the machine based on a registry key set by group policy. Runs after
OpenVPN client installs from Software Center.

.PARAMETER Type
Specifies whether to install or uninstall. Type can be install or uninstall.

.NOTES
Author:     Unknown
Created:    Unknown
Updated:    31/07/2025
Version:    1.0.1
#>

param (
    [string]$Type
)

# Get hostname for use with config file
$HostName = $env:COMPUTERNAME.ToUpper()
# Get value of profile registry key set by group policy
$profileValue = Get-ItemPropertyValue -Path HKLM:\Software\BMD\OpenVPN -Name "Profile" -ErrorAction SilentlyContinue

switch ($Type) {
    Install {
        # Set config file contents based on profile registry key
        switch ($profileValue) {
            "MasterIT-UDP" {
                $ovpnConfig = @"
#Version MasterIT-UDP-v1.3
client
dev tun
proto udp
remote npv01.bmd.com.au 23786
remote npv02.bmd.com.au 23786
remote npv03.bmd.com.au 23786
route-method exe
tls-timeout 10
route-delay 2
script-security 2
ca "C:\\Program Files\\OpenVPN\\config-auto\\ca.cer"
cryptoapicert `"SUBJ:$HostName`"
connect-retry 5 60
redirect-gateway def1
block-outside-dns
"@
            }

            "MasterTCP 1.1" {
                $ovpnConfig = @"
#Version MasterTCP-v1.3
client
dev tun
proto tcp
remote npv01.bmd.com.au 443
remote npv02.bmd.com.au 443
remote npv03.bmd.com.au 443
route-method exe
tls-timeout 10
route-delay 2
script-security 2
ca "C:\\Program Files\\OpenVPN\\config-auto\\ca.cer"
cryptoapicert `"SUBJ:$HostName`"
connect-retry 5 60
redirect-gateway def1
block-outside-dns
"@
            }

            default {
                $ovpnConfig = @"
#Version MasterUDP-v1.3
client
dev tun
proto udp
remote npv01.bmd.com.au 443
remote npv02.bmd.com.au 443
remote npv03.bmd.com.au 443
route-method exe
tls-timeout 10
route-delay 2
script-security 2
ca "C:\\Program Files\\OpenVPN\\config-auto\\ca.cer"
cryptoapicert `"SUBJ:$HostName`"
connect-retry 5 60
redirect-gateway def1
block-outside-dns
"@
            }
        }

        # Write contents to config file
        $ovpnConfig | Out-File -FilePath "$env:ProgramFiles\OpenVPN\config-auto\$HostName.ovpn" -Encoding "UTF8"
        # Copy ca.cer file
        Copy-Item -Path "$PSScriptRoot\ca.cer" -Destination "$env:ProgramFiles\OpenVPN\config-auto\ca.cer" -Force
        # Set permissions on config-auto folder - Remove Users group
        cacls "$env:ProgramFiles\OpenVPN\config-auto" /T /E /R Users
        # Remove start menu shortcut
        Remove-Item -Path "$env:ProgramData\Microsoft\Windows\Start Menu\Programs\OpenVPN" -Recurse
        # Restart services
        Start-Sleep -Seconds 15
        Restart-Service -Name OpenVPNService,OpenVPNServiceInteractive
    }

    Uninstall {
        # Remove left over folders and files
        if (Test-Path "$env:ProgramFiles\OpenVPN") {
            Remove-Item "$env:ProgramFiles\OpenVPN" -Recurse -Force
        }
    }
}
