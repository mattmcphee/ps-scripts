function Get-ActiveCIPolicies {
    param (
        # ComputerName
        [Parameter(Mandatory=$false)]
        [string]
        $ComputerName = $env:COMPUTERNAME,
        # only show policies being enforced
        [Parameter(Mandatory=$false)]
        [switch]
        $EnforcedOnly
    )
    if ($EnforcedOnly) {
        Invoke-Command -ComputerName $ComputerName -ScriptBlock {
            (citool --list-policies -json | ConvertFrom-Json).Policies |
            Where-Object {$_.IsEnforced -eq "True"} |
            Select-Object PolicyID,BasePolicyID,FriendlyName, `
                IsSystemPolicy,IsOnDisk,IsEnforced,IsAuthorized
        }
    } else {
        Invoke-Command -ComputerName $ComputerName -ScriptBlock {
            (citool --list-policies -json | ConvertFrom-Json).Policies |
            Select-Object PolicyID,BasePolicyID,FriendlyName, `
                IsSystemPolicy,IsOnDisk,IsEnforced,IsAuthorized
        }
    }
}

# SIG # Begin signature block
# MIIl0QYJKoZIhvcNAQcCoIIlwjCCJb4CAQExDzANBglghkgBZQMEAgEFADB5Bgor
# BgEEAYI3AgEEoGswaTA0BgorBgEEAYI3AgEeMCYCAwEAAAQQH8w7YFlLCE63JNLG
# KX7zUQIBAAIBAAIBAAIBAAIBADAxMA0GCWCGSAFlAwQCAQUABCB/Z12J+O2bE4wS
# nb3D9+dA0W9NW3fo4C+DzNRUQSvp2aCCH94wggWNMIIEdaADAgECAhAOmxiO+dAt
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
# twGpn1eqXijiuZQwggXnMIIDz6ADAgECAhMgAAAE1i6W03+xSRfaAAAAAATWMA0G
# CSqGSIb3DQEBCwUAMFwxEjAQBgoJkiaJk/IsZAEZFgJhdTETMBEGCgmSJomT8ixk
# ARkWA2NvbTETMBEGCgmSJomT8ixkARkWA2JtZDEcMBoGA1UEAxMTQk1EIElzc3Vp
# bmcgQ0EgMSBHNDAeFw0yNDExMDQwMDM3NTJaFw0yNzExMDQwMDM3NTJaMBwxGjAY
# BgNVBAMTEU1hdHRoZXcgTWNQaGVlIFNVMIIBIjANBgkqhkiG9w0BAQEFAAOCAQ8A
# MIIBCgKCAQEA7jMvdKlLsjpvIQd1tO/RRNiEMZHXKNaPXmsPLZMTVFLhU9yeGgIp
# Do8UUdmgh18F2ND7Tf1Z+603iYU80TzOwOr/ko1J4B37OVOVGC6BO4VWmVj/nzbk
# ZL4U2/QP5tg35wHYTo3D/Dv/yN/m+e1JuWTdMF5XN0S730vTLfHUyMsYVzoilBfn
# RfolT4ygwDUb1aRx4ueUx7b3N0yyNeiPX5fYvATPzNcYjIXl7QtYFrg8ad5DKpyR
# 2yMBDd8YbdPRIh+7xy1kYV9zwZK2gmVfjXxRIK9gUMP/H7I5Mel7q+acLgk+vMAj
# q5/89Q1uHmyE7PLFcCYXsg4Obbfh8TeEGQIDAQABo4IB4DCCAdwwOwYJKwYBBAGC
# NxUHBC4wLAYkKwYBBAGCNxUIn7s/hPCFSPWNB4G5wyiG3u99gQqB7JtY8L49AgFk
# AgEDMBMGA1UdJQQMMAoGCCsGAQUFBwMDMAsGA1UdDwQEAwIHgDAbBgkrBgEEAYI3
# FQoEDjAMMAoGCCsGAQUFBwMDMB0GA1UdDgQWBBQ0i9+kqKewO4r4lw0nSj3aE6Dj
# 7TAfBgNVHSMEGDAWgBTN0yUMxwnCtpXIbxeaoir2yfeRNjBKBgNVHR8EQzBBMD+g
# PaA7hjlodHRwOi8vcGtpLmJtZC5jb20uYXUvcGtpL0JNRCUyMElzc3VpbmclMjBD
# QSUyMDElMjBHNC5jcmwwVQYIKwYBBQUHAQEESTBHMEUGCCsGAQUFBzAChjlodHRw
# Oi8vcGtpLmJtZC5jb20uYXUvcGtpL0JNRCUyMElzc3VpbmclMjBDQSUyMDElMjBH
# NC5jcnQwKwYDVR0RBCQwIqAgBgorBgEEAYI3FAIDoBIMEG1tLnN1QGJtZC5jb20u
# YXUwTgYJKwYBBAGCNxkCBEEwP6A9BgorBgEEAYI3GQIBoC8ELVMtMS01LTIxLTM2
# NDY4ODYzLTExMTEyMzk1NDUtMTIzMjgyODQzNi02NzQwMzANBgkqhkiG9w0BAQsF
# AAOCAgEAhr8cCjjz52eS7B0MXSVz2JrPqEmwFSCF0HYuaG5gxheSKbOyna+Syi7N
# xQCRftWFyQXOROFU7QpcH4tw5Ml7D/ihmTV9sM8piJCsxe7cJ9nl0WIBSwPRmJ/o
# 76zm062bljTYqCv7enmyyRkasSk1uTdTn37aAIVp9U/JyJ2rt3nzzE1i9k53qzd7
# ax+02vwI2/3RkRnQp6CTpOWfbxVklkCMfpKbo56MlHtVlY17V5vZnBN3/GAXc4Lf
# kJgsf38w7iY5VFEGFT47rI070Nomb+Clh965bjyE1tWGQ/rCpaSRfQx9iUOJ3gsn
# Znd8v493ReEDT86KTo8VGtA6Igs7y9fu32SWjXsQ/sugNsBJ0KGQgFmWL/uOig6V
# TEMET/RS+KdN+zmyM+D0qb7YM346T/SQdQ0cS/t74KeQvMJuuccik836cc5wZPvY
# Dk97wi/mUxHnimou5pm+tKe0Yy5eZPHpCdIREEfyBxdFutK8yqO9T2s/JHPfg/Ur
# 9q5oBSuJROYdlIpPOvvCmcdGQgvNM54u37iEaFyNLoGcuX8pri9DKbLDSDhIw8/z
# Eu8F3wSS3lqjOfzXBD3TMxo6sl2W2RKySHch3btaMIywIuj59WsN7YlIpa3wDjSM
# RW3l/AAtQrvFFEK8hgqGdgQGE0cOAusLapmGujjQqGZ6xEDLS6cwggauMIIElqAD
# AgECAhAHNje3JFR82Ees/ShmKl5bMA0GCSqGSIb3DQEBCwUAMGIxCzAJBgNVBAYT
# AlVTMRUwEwYDVQQKEwxEaWdpQ2VydCBJbmMxGTAXBgNVBAsTEHd3dy5kaWdpY2Vy
# dC5jb20xITAfBgNVBAMTGERpZ2lDZXJ0IFRydXN0ZWQgUm9vdCBHNDAeFw0yMjAz
# MjMwMDAwMDBaFw0zNzAzMjIyMzU5NTlaMGMxCzAJBgNVBAYTAlVTMRcwFQYDVQQK
# Ew5EaWdpQ2VydCwgSW5jLjE7MDkGA1UEAxMyRGlnaUNlcnQgVHJ1c3RlZCBHNCBS
# U0E0MDk2IFNIQTI1NiBUaW1lU3RhbXBpbmcgQ0EwggIiMA0GCSqGSIb3DQEBAQUA
# A4ICDwAwggIKAoICAQDGhjUGSbPBPXJJUVXHJQPE8pE3qZdRodbSg9GeTKJtoLDM
# g/la9hGhRBVCX6SI82j6ffOciQt/nR+eDzMfUBMLJnOWbfhXqAJ9/UO0hNoR8XOx
# s+4rgISKIhjf69o9xBd/qxkrPkLcZ47qUT3w1lbU5ygt69OxtXXnHwZljZQp09ns
# ad/ZkIdGAHvbREGJ3HxqV3rwN3mfXazL6IRktFLydkf3YYMZ3V+0VAshaG43IbtA
# rF+y3kp9zvU5EmfvDqVjbOSmxR3NNg1c1eYbqMFkdECnwHLFuk4fsbVYTXn+149z
# k6wsOeKlSNbwsDETqVcplicu9Yemj052FVUmcJgmf6AaRyBD40NjgHt1biclkJg6
# OBGz9vae5jtb7IHeIhTZgirHkr+g3uM+onP65x9abJTyUpURK1h0QCirc0PO30qh
# HGs4xSnzyqqWc0Jon7ZGs506o9UD4L/wojzKQtwYSH8UNM/STKvvmz3+DrhkKvp1
# KCRB7UK/BZxmSVJQ9FHzNklNiyDSLFc1eSuo80VgvCONWPfcYd6T/jnA+bIwpUzX
# 6ZhKWD7TA4j+s4/TXkt2ElGTyYwMO1uKIqjBJgj5FBASA31fI7tk42PgpuE+9sJ0
# sj8eCXbsq11GdeJgo1gJASgADoRU7s7pXcheMBK9Rp6103a50g5rmQzSM7TNsQID
# AQABo4IBXTCCAVkwEgYDVR0TAQH/BAgwBgEB/wIBADAdBgNVHQ4EFgQUuhbZbU2F
# L3MpdpovdYxqII+eyG8wHwYDVR0jBBgwFoAU7NfjgtJxXWRM3y5nP+e6mK4cD08w
# DgYDVR0PAQH/BAQDAgGGMBMGA1UdJQQMMAoGCCsGAQUFBwMIMHcGCCsGAQUFBwEB
# BGswaTAkBggrBgEFBQcwAYYYaHR0cDovL29jc3AuZGlnaWNlcnQuY29tMEEGCCsG
# AQUFBzAChjVodHRwOi8vY2FjZXJ0cy5kaWdpY2VydC5jb20vRGlnaUNlcnRUcnVz
# dGVkUm9vdEc0LmNydDBDBgNVHR8EPDA6MDigNqA0hjJodHRwOi8vY3JsMy5kaWdp
# Y2VydC5jb20vRGlnaUNlcnRUcnVzdGVkUm9vdEc0LmNybDAgBgNVHSAEGTAXMAgG
# BmeBDAEEAjALBglghkgBhv1sBwEwDQYJKoZIhvcNAQELBQADggIBAH1ZjsCTtm+Y
# qUQiAX5m1tghQuGwGC4QTRPPMFPOvxj7x1Bd4ksp+3CKDaopafxpwc8dB+k+YMjY
# C+VcW9dth/qEICU0MWfNthKWb8RQTGIdDAiCqBa9qVbPFXONASIlzpVpP0d3+3J0
# FNf/q0+KLHqrhc1DX+1gtqpPkWaeLJ7giqzl/Yy8ZCaHbJK9nXzQcAp876i8dU+6
# WvepELJd6f8oVInw1YpxdmXazPByoyP6wCeCRK6ZJxurJB4mwbfeKuv2nrF5mYGj
# VoarCkXJ38SNoOeY+/umnXKvxMfBwWpx2cYTgAnEtp/Nh4cku0+jSbl3ZpHxcpzp
# SwJSpzd+k1OsOx0ISQ+UzTl63f8lY5knLD0/a6fxZsNBzU+2QJshIUDQtxMkzdwd
# eDrknq3lNHGS1yZr5Dhzq6YBT70/O3itTK37xJV77QpfMzmHQXh6OOmc4d0j/R0o
# 08f56PGYX/sr2H7yRp11LB4nLCbbbxV7HhmLNriT1ObyF5lZynDwN7+YAN8gFk8n
# +2BnFqFmut1VwDophrCYoCvtlUG3OtUVmDG0YgkPCr2B2RP+v6TR81fZvAT6gt4y
# 3wSJ8ADNXcL50CN/AAvkdgIm2fBldkKmKYcJRyvmfxqkhQ/8mJb2VVQrH4D6wPIO
# K+XW+6kvRBVK5xMOHds3OBqhK/bt1nz8MIIGvDCCBKSgAwIBAgIQC65mvFq6f5WH
# xvnpBOMzBDANBgkqhkiG9w0BAQsFADBjMQswCQYDVQQGEwJVUzEXMBUGA1UEChMO
# RGlnaUNlcnQsIEluYy4xOzA5BgNVBAMTMkRpZ2lDZXJ0IFRydXN0ZWQgRzQgUlNB
# NDA5NiBTSEEyNTYgVGltZVN0YW1waW5nIENBMB4XDTI0MDkyNjAwMDAwMFoXDTM1
# MTEyNTIzNTk1OVowQjELMAkGA1UEBhMCVVMxETAPBgNVBAoTCERpZ2lDZXJ0MSAw
# HgYDVQQDExdEaWdpQ2VydCBUaW1lc3RhbXAgMjAyNDCCAiIwDQYJKoZIhvcNAQEB
# BQADggIPADCCAgoCggIBAL5qc5/2lSGrljC6W23mWaO16P2RHxjEiDtqmeOlwf0K
# MCBDEr4IxHRGd7+L660x5XltSVhhK64zi9CeC9B6lUdXM0s71EOcRe8+CEJp+3R2
# O8oo76EO7o5tLuslxdr9Qq82aKcpA9O//X6QE+AcaU/byaCagLD/GLoUb35SfWHh
# 43rOH3bpLEx7pZ7avVnpUVmPvkxT8c2a2yC0WMp8hMu60tZR0ChaV76Nhnj37DEY
# TX9ReNZ8hIOYe4jl7/r419CvEYVIrH6sN00yx49boUuumF9i2T8UuKGn9966fR5X
# 6kgXj3o5WHhHVO+NBikDO0mlUh902wS/Eeh8F/UFaRp1z5SnROHwSJ+QQRZ1fisD
# 8UTVDSupWJNstVkiqLq+ISTdEjJKGjVfIcsgA4l9cbk8Smlzddh4EfvFrpVNnes4
# c16Jidj5XiPVdsn5n10jxmGpxoMc6iPkoaDhi6JjHd5ibfdp5uzIXp4P0wXkgNs+
# CO/CacBqU0R4k+8h6gYldp4FCMgrXdKWfM4N0u25OEAuEa3JyidxW48jwBqIJqIm
# d93NRxvd1aepSeNeREXAu2xUDEW8aqzFQDYmr9ZONuc2MhTMizchNULpUEoA6Vva
# 7b1XCB+1rxvbKmLqfY/M/SdV6mwWTyeVy5Z/JkvMFpnQy5wR14GJcv6dQ4aEKOX5
# AgMBAAGjggGLMIIBhzAOBgNVHQ8BAf8EBAMCB4AwDAYDVR0TAQH/BAIwADAWBgNV
# HSUBAf8EDDAKBggrBgEFBQcDCDAgBgNVHSAEGTAXMAgGBmeBDAEEAjALBglghkgB
# hv1sBwEwHwYDVR0jBBgwFoAUuhbZbU2FL3MpdpovdYxqII+eyG8wHQYDVR0OBBYE
# FJ9XLAN3DigVkGalY17uT5IfdqBbMFoGA1UdHwRTMFEwT6BNoEuGSWh0dHA6Ly9j
# cmwzLmRpZ2ljZXJ0LmNvbS9EaWdpQ2VydFRydXN0ZWRHNFJTQTQwOTZTSEEyNTZU
# aW1lU3RhbXBpbmdDQS5jcmwwgZAGCCsGAQUFBwEBBIGDMIGAMCQGCCsGAQUFBzAB
# hhhodHRwOi8vb2NzcC5kaWdpY2VydC5jb20wWAYIKwYBBQUHMAKGTGh0dHA6Ly9j
# YWNlcnRzLmRpZ2ljZXJ0LmNvbS9EaWdpQ2VydFRydXN0ZWRHNFJTQTQwOTZTSEEy
# NTZUaW1lU3RhbXBpbmdDQS5jcnQwDQYJKoZIhvcNAQELBQADggIBAD2tHh92mVvj
# OIQSR9lDkfYR25tOCB3RKE/P09x7gUsmXqt40ouRl3lj+8QioVYq3igpwrPvBmZd
# rlWBb0HvqT00nFSXgmUrDKNSQqGTdpjHsPy+LaalTW0qVjvUBhcHzBMutB6Hzele
# dbDCzFzUy34VarPnvIWrqVogK0qM8gJhh/+qDEAIdO/KkYesLyTVOoJ4eTq7gj9U
# FAL1UruJKlTnCVaM2UeUUW/8z3fvjxhN6hdT98Vr2FYlCS7Mbb4Hv5swO+aAXxWU
# m3WpByXtgVQxiBlTVYzqfLDbe9PpBKDBfk+rabTFDZXoUke7zPgtd7/fvWTlCs30
# VAGEsshJmLbJ6ZbQ/xll/HjO9JbNVekBv2Tgem+mLptR7yIrpaidRJXrI+UzB6vA
# lk/8a1u7cIqV0yef4uaZFORNekUgQHTqddmsPCEIYQP7xGxZBIhdmm4bhYsVA6G2
# WgNFYagLDBzpmk9104WQzYuVNsxyoVLObhx3RugaEGru+SojW4dHPoWrUhftNpFC
# 5H7QEY7MhKRyrBe7ucykW7eaCuWBsBb4HOKRFVDcrZgdwaSIqMDiCLg4D+TPVgKx
# 2EgEdeoHNHT9l3ZDBD+XgbF+23/zBjeCtxz+dL/9NWR6P2eZRi7zcEO1xwcdcqJs
# yz/JceENc2Sg8h3KeFUCS7tpFk7CrDqkMIIG7DCCBNSgAwIBAgITNQAAAALQZkt+
# ZnXzywAAAAAAAjANBgkqhkiG9w0BAQsFADBXMRIwEAYKCZImiZPyLGQBGRYCYXUx
# EzARBgoJkiaJk/IsZAEZFgNjb20xEzARBgoJkiaJk/IsZAEZFgNibWQxFzAVBgNV
# BAMTDkJNRCBSb290IENBIEc0MB4XDTIzMDYxMTIzMDgyNFoXDTMzMDYxMTIzMTgy
# NFowXDESMBAGCgmSJomT8ixkARkWAmF1MRMwEQYKCZImiZPyLGQBGRYDY29tMRMw
# EQYKCZImiZPyLGQBGRYDYm1kMRwwGgYDVQQDExNCTUQgSXNzdWluZyBDQSAxIEc0
# MIICIjANBgkqhkiG9w0BAQEFAAOCAg8AMIICCgKCAgEAz8x/9sgDhYPEIfxgruf/
# qdWngrJq3rMif2LPSj8rZ+btT9Gy9S+M+8E3sy2R7SzYqVE3QU7DOifIAJ6e0/NZ
# f/iz4kKCgGBhOhw+z06OoN6u4q+Kr7e0iLzoWHgEAi0Q8FqPvjFiIZdZLmY+e4+x
# mY2Zvp6aWzedaN2qeFVX2Ygq5cLy22WwUyJAYW4vbUEC/hiLAcYjf0pxPvoAzvb9
# l/Zh8yaEk1v7hIvtKt3okHImeWDk2frSRko0MB/xaIL3dww0d+q9RWMu2IIQ4+9v
# LUeYQCwjtxuakuMLdq83eRMGJXQeCexo/S411LB/UsHpy8PdSX2CB4kCdQgV7+gt
# KiFm1DFDRhdbLBocC6tLxz8qUBokUFzVdP7Zc3OJvj0savWgK9tFQZwTnUMBGvwh
# zWFBccGf2HDYFLwIKxReZQWKgEo+frtSoAQ6OYiuwqWeujIg2c28SHLuy1PsmHFx
# 11T1mWPItn0EtVxwAgAmTPLSG+BMLVyGtQcHGwKE0wN4nB0YDUQYwmzLp0Brp9Mk
# xUBdK1qQDLI8tFGTXkdJnElAhzqMSurXTM/E5W7341x7qpXSt1EsawyK9u0fkuoS
# dyLxzkQtCVsfjFRstjSXnJ7memCejpxCnQehik0xnZU91VGqMi7V3ChfDdcXAx4O
# xU28s9IDyX819Y43q4RE3aECAwEAAaOCAaowggGmMBAGCSsGAQQBgjcVAQQDAgEA
# MB0GA1UdDgQWBBTN0yUMxwnCtpXIbxeaoir2yfeRNjCBgwYDVR0gBHwwejB4Bggq
# AwSLL0NZBTBsMDoGCCsGAQUFBwICMC4eLABMAGUAZwBhAGwAIABQAG8AbABpAGMA
# eQAgAFMAdABhAHQAZQBtAGUAbgB0MC4GCCsGAQUFBwIBFiJodHRwOi8vcGtpLmJt
# ZC5jb20uYXUvcGtpL2Nwcy5odG1sMBkGCSsGAQQBgjcUAgQMHgoAUwB1AGIAQwBB
# MAsGA1UdDwQEAwIBhjAPBgNVHRMBAf8EBTADAQH/MB8GA1UdIwQYMBaAFPYnl2aA
# 7inf9Q3I6drjUTr3ksg0MEMGA1UdHwQ8MDowOKA2oDSGMmh0dHA6Ly9wa2kuYm1k
# LmNvbS5hdS9wa2kvQk1EJTIwUm9vdCUyMENBJTIwRzQuY3JsME4GCCsGAQUFBwEB
# BEIwQDA+BggrBgEFBQcwAoYyaHR0cDovL3BraS5ibWQuY29tLmF1L3BraS9CTUQl
# MjBSb290JTIwQ0ElMjBHNC5jcnQwDQYJKoZIhvcNAQELBQADggIBACLP3NoCk2HY
# RG2qqJurCda7Fyz19BWlaCG8eTovb3PxyTR42lGmq86vMY5cfDJVAFsN85qb4+CM
# XxhEGpwkXVywXX7oyWr4vFAbG10A+s0+Ow/5s3+Dffa+aG8TpsPdw/xQ0mRZWTgF
# 1Nipu846nUJi/K0gXdEZVBXaguMKH0N5CzCsyR538NsQLjYILYwwm67R1VuZN0rB
# EPcC5ohFpDOYFuiYwMCik7TCdkktOpfJQRyKO0GUsmXCD8CIiJ4GtNZtaRmje7ld
# AlVe5PEni8G9Tx4Lj4KN+W3hswCKvezUllVnNIXGe7Mv86DfBIwMoiLnYTv4ScQH
# 7IRgLkkwALZsnst7rDW/xqLGxS4VIvILz6L5G5oXCVGKJpFlXwoVF8OzArf/Zd5t
# nTeB8oO72JsjZfM3P2qdFfhei9G3c7CJF0+gwRA3FvbvKMEY6NsoNYkMU2s5iLj8
# MO039EFD1Rc+oJ5FpefIoTt5OOXt8t5vuT3BMIptYTrhi9MY05bE/EamtpcSvlb3
# qH1tH3P3K832i8APMrmzzDmwmMbO0b5tA2K09uBk3XSRvbvWwa0DxbJ8jgJrkUtV
# OzBhC1Y7NqjsYixoRMUb4WEt932PdySlyiZaZ6NMC1y730PPHR7Lm+zEp2PFX4LT
# fukm+EjhGM4078bHsoSVuINSm78vDX2eMYIFSTCCBUUCAQEwczBcMRIwEAYKCZIm
# iZPyLGQBGRYCYXUxEzARBgoJkiaJk/IsZAEZFgNjb20xEzARBgoJkiaJk/IsZAEZ
# FgNibWQxHDAaBgNVBAMTE0JNRCBJc3N1aW5nIENBIDEgRzQCEyAAAATWLpbTf7FJ
# F9oAAAAABNYwDQYJYIZIAWUDBAIBBQCggYQwGAYKKwYBBAGCNwIBDDEKMAigAoAA
# oQKAADAZBgkqhkiG9w0BCQMxDAYKKwYBBAGCNwIBBDAcBgorBgEEAYI3AgELMQ4w
# DAYKKwYBBAGCNwIBFTAvBgkqhkiG9w0BCQQxIgQgrjNLkBTYl30Akckn0OFAxT+v
# 4fKtFk+E5/eg8yi25PIwDQYJKoZIhvcNAQEBBQAEggEAQ7lDhFisVEnSnMFPqgTw
# ciuxdr5JYBqiengQ1rn3oRSp0pl7Xlet3zwK5SLSppX6VL5Z5cPddXx646MNyHwt
# M6FhkOfz8rCr1D/sEE4fBdhZRlcfXkicHG7/emVH0puE5ee3+TY3C1lKPojkWsGD
# eahldp53SF3f43G1xEGpoDi0mB705yeSM8ZgFGDvC7G9YenU6Zp+sXCHFGilMUnD
# dSxLiTkTZj8U/JWG2+pL0ubfUT05rJAgd2yQy20OdEynIEUeshL0xOiJhO/3o9eH
# apFQpua6qUoppbzHzqoYYjX5lQa7StxLuq1xxJ3fFU4oWiHQlLdwqiNFRpUddOFF
# MaGCAyAwggMcBgkqhkiG9w0BCQYxggMNMIIDCQIBATB3MGMxCzAJBgNVBAYTAlVT
# MRcwFQYDVQQKEw5EaWdpQ2VydCwgSW5jLjE7MDkGA1UEAxMyRGlnaUNlcnQgVHJ1
# c3RlZCBHNCBSU0E0MDk2IFNIQTI1NiBUaW1lU3RhbXBpbmcgQ0ECEAuuZrxaun+V
# h8b56QTjMwQwDQYJYIZIAWUDBAIBBQCgaTAYBgkqhkiG9w0BCQMxCwYJKoZIhvcN
# AQcBMBwGCSqGSIb3DQEJBTEPFw0yNDExMTUwMjE3MDZaMC8GCSqGSIb3DQEJBDEi
# BCA39Nrkm6smmXGrXwxznBGCd3yA1jf2elp/UaVy2kmdETANBgkqhkiG9w0BAQEF
# AASCAgAhBXfvTozFFV/SACGU3Y68yxzrQPj54D9/6QWP4OV/8ZLRRFT/MrSyTML2
# FEtYhHSbUxuPLd+cr7vINgwsycq3gjA2jFjn9BDcChYotkFxqW/sDLoeVYwXcEKp
# A5HLIsx/9shnXtuNWYrsyx2TFgbgHF8+kSJspnImNb2O0hBypKaAjQaGheWh9anx
# QO0YpX5RzzaP0I+UA1NBP3zoJmVyNNFMPbNSBJQpZepFMUznHXBfM1mc1Y1sHkA+
# p4C+PzKGS5BL+fhLEX9gWzAQCFo5ynSfx+fDY2eQ/WBeFpohI37CUEdUaF2EpM9D
# A8CISmNs/LELsnuxbEB2N2ziwP3t4eEOHyzoOOIel6542YxZUUTPYKktiHyxT3qK
# DEkD9RvcaVV7X3+NC9kkRe1UDz9oX3RuzcRIKHm8L2q0URZLzDosJ5MdJNt/rpcP
# JMbn0Af6pT5alkElsK/egX5TAWsTUp3ZUmhKl6QBre4Dsj9IMHiU79T301AcHJHF
# i7dJZq+62n5sXUNYNzCEnqk7iKfQ+HqAI9D0Yuik5/uPJLLInR0YeQc16UuYAP/K
# pEBf/zINwztDDgh0x+EPMhNayjc83DG9dZ+rdn5q5wm/yhdQ7r7Z/e5Dw9jmANjP
# 1sa0bFQyPVmTj8ZQtmyO3jrjcG05mGojZytRZ2mgKKUP9sihmQ==
# SIG # End signature block
