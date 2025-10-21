$profileValue = Get-ItemPropertyValue -Path HKLM:\Software\BMD\OpenVPN -Name "Profile" -ErrorAction SilentlyContinue
 
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

Write-Host $ovpnConfig