<#
.SYNOPSIS
Gets scripts using Get-ChildItem to get files with ps1 extension in a specified
folder then signs scripts using a codesigning certificate.

.PARAMETER Path
The path to a .ps1 script or folder containing .ps1 scripts.

.PARAMETER Thumbprint
The thumbprint of the codesigning certificate to use to sign the script(s).

.PARAMETER Recurse
This switch will recursively search folders when looking for scripts to sign.

.INPUTS
[string]
File paths to a script file or a folder containing scripts can be piped to this function.
[object]
An object with a FullName property (e.g. objects from Get-ChildItem) can be piped to this function.

.OUTPUTS
N/A

.EXAMPLE
PS> Add-CodeSignature -Path "C:\sources\repos\example-script.ps1"

.EXAMPLE
PS> Add-CodeSignature -Path "C:\sources\repos\WDAC" -Recurse

.EXAMPLE
PS> Add-CodeSignature -Path "C:\sources\repos\example-script.ps1" -Thumbprint "abcdefg"

.EXAMPLE
PS> Get-ChildItem -Path "C:\wdac\Example-Scripts.ps1" | Add-CodeSignature

.NOTES
Author:     Matt McPhee
Version:    1.1
Created:    13/09/2025
Updated:    23/07/2025
#>
function Add-CodeSignature {
    [CmdletBinding()]
    param (
        # Path - script or folder containing scripts you wish to sign
        [Parameter(Mandatory,ValueFromPipeline,ValueFromPipelineByPropertyName)]
        [ValidateScript({ Test-Path -Path $_ })]
        [Alias("FullName")]
        [string]
        $Path,
        # Thumbprint - thumbprint of a certificate
        [Parameter(Mandatory=$false)]
        [string]
        $Thumbprint,
        # Recurse - recurse through folders when looking for scripts to sign
        [Parameter(Mandatory=$false)]
        [switch]
        $Recurse
    )

    begin {
        # retrieve codesigning cert
        # we select the certificate based on the extension format starting with desired template name
        # then if we find multiple certs, sort based on expiry date and select the one with latest expiry
        if ($Thumbprint) {
            $cert = Get-ChildItem -Path "Cert:\" -Recurse | Where-Object { $_.Thumbprint -eq $Thumbprint }
        } else {
            $cert = Get-ChildItem -Path "Cert:\CurrentUser\My" |
                Where-Object { $_.Extensions.Format(0)[0].StartsWith("Template=Code Signing - 3 Year Validity") } |
                Sort-Object -Property NotAfter -Descending |
                Select-Object -First 1
        }

        # throw error if no codesigning cert found
        if ($cert.Count -eq 0) {
            throw "Unable to find CodeSigning certificate."
        }

        # set up empty array to hold found scripts
        $allScripts = @()
    }

    process {
        # get scripts for each path that comes down the pipe
        if ($Recurse) {
            $scripts = Get-ChildItem -Path $Path -Include '*.ps1' -Recurse -ErrorAction Stop
        } else {
            $scripts = Get-ChildItem -Path $Path -Include '*.ps1' -ErrorAction Stop
        }

        # add scripts to array
        $allScripts += $scripts
    }

    end {
        # throw error if no scripts found
        if ($allScripts.Count -eq 0) {
            throw "No script files found in provided path(s)."
        }

        Write-Verbose "Found $($allScripts.Count) scripts to sign."

        # loop through and sign each script found
        # use multithreading if ps7+
        if ($PSVersionTable.PSVersion.Major -ge 7) {
            $allScripts | ForEach-Object -Parallel {
                $cert = $using:cert

                try {
                    Set-AuthenticodeSignature -Certificate $cert `
                        -FilePath $_.FullName `
                        -TimestampServer 'http://timestamp.digicert.com' `
                        -ErrorAction 'Stop'

                    Write-Verbose "Successfully signed: $($_.Name)"
                } catch {
                    Write-Error "Failed to sign $($_.Name): $_"
                }
            }
        } else {
            for ($i = 0; $i -lt $allScripts.Count; $i++) {
                Write-Progress -Activity "Signing scripts..." `
                    -Status "Processing $($allScripts[$i].Name)" `
                    -PercentComplete (($i / $allScripts.Count) * 100)

                try {
                    Set-AuthenticodeSignature -Certificate $cert `
                        -FilePath $allScripts[$i].FullName `
                        -TimestampServer 'http://timestamp.digicert.com' `
                        -ErrorAction 'Stop'

                    Write-Verbose "Successfully signed: $($allScripts[$i].Name)"
                } catch {
                    Write-Error "Failed to sign $($allScripts[$i].Name): $_"
                }
            }
        }
    }
}

# SIG # Begin signature block
# MIIl6QYJKoZIhvcNAQcCoIIl2jCCJdYCAQExCzAJBgUrDgMCGgUAMGkGCisGAQQB
# gjcCAQSgWzBZMDQGCisGAQQBgjcCAR4wJgIDAQAABBAfzDtgWUsITrck0sYpfvNR
# AgEAAgEAAgEAAgEAAgEAMCEwCQYFKw4DAhoFAAQUGdDVKHvPRUUoC1BCEVa24QMC
# 5GCggiAVMIIFjTCCBHWgAwIBAgIQDpsYjvnQLefv21DiCEAYWjANBgkqhkiG9w0B
# AQwFADBlMQswCQYDVQQGEwJVUzEVMBMGA1UEChMMRGlnaUNlcnQgSW5jMRkwFwYD
# VQQLExB3d3cuZGlnaWNlcnQuY29tMSQwIgYDVQQDExtEaWdpQ2VydCBBc3N1cmVk
# IElEIFJvb3QgQ0EwHhcNMjIwODAxMDAwMDAwWhcNMzExMTA5MjM1OTU5WjBiMQsw
# CQYDVQQGEwJVUzEVMBMGA1UEChMMRGlnaUNlcnQgSW5jMRkwFwYDVQQLExB3d3cu
# ZGlnaWNlcnQuY29tMSEwHwYDVQQDExhEaWdpQ2VydCBUcnVzdGVkIFJvb3QgRzQw
# ggIiMA0GCSqGSIb3DQEBAQUAA4ICDwAwggIKAoICAQC/5pBzaN675F1KPDAiMGkz
# 7MKnJS7JIT3yithZwuEppz1Yq3aaza57G4QNxDAf8xukOBbrVsaXbR2rsnnyyhHS
# 5F/WBTxSD1Ifxp4VpX6+n6lXFllVcq9ok3DCsrp1mWpzMpTREEQQLt+C8weE5nQ7
# bXHiLQwb7iDVySAdYyktzuxeTsiT+CFhmzTrBcZe7FsavOvJz82sNEBfsXpm7nfI
# SKhmV1efVFiODCu3T6cw2Vbuyntd463JT17lNecxy9qTXtyOj4DatpGYQJB5w3jH
# trHEtWoYOAMQjdjUN6QuBX2I9YI+EJFwq1WCQTLX2wRzKm6RAXwhTNS8rhsDdV14
# Ztk6MUSaM0C/CNdaSaTC5qmgZ92kJ7yhTzm1EVgX9yRcRo9k98FpiHaYdj1ZXUJ2
# h4mXaXpI8OCiEhtmmnTK3kse5w5jrubU75KSOp493ADkRSWJtppEGSt+wJS00mFt
# 6zPZxd9LBADMfRyVw4/3IbKyEbe7f/LVjHAsQWCqsWMYRJUadmJ+9oCw++hkpjPR
# iQfhvbfmQ6QYuKZ3AeEPlAwhHbJUKSWJbOUOUlFHdL4mrLZBdd56rF+NP8m800ER
# ElvlEFDrMcXKchYiCd98THU/Y+whX8QgUWtvsauGi0/C1kVfnSD8oR7FwI+isX4K
# Jpn15GkvmB0t9dmpsh3lGwIDAQABo4IBOjCCATYwDwYDVR0TAQH/BAUwAwEB/zAd
# BgNVHQ4EFgQU7NfjgtJxXWRM3y5nP+e6mK4cD08wHwYDVR0jBBgwFoAUReuir/SS
# y4IxLVGLp6chnfNtyA8wDgYDVR0PAQH/BAQDAgGGMHkGCCsGAQUFBwEBBG0wazAk
# BggrBgEFBQcwAYYYaHR0cDovL29jc3AuZGlnaWNlcnQuY29tMEMGCCsGAQUFBzAC
# hjdodHRwOi8vY2FjZXJ0cy5kaWdpY2VydC5jb20vRGlnaUNlcnRBc3N1cmVkSURS
# b290Q0EuY3J0MEUGA1UdHwQ+MDwwOqA4oDaGNGh0dHA6Ly9jcmwzLmRpZ2ljZXJ0
# LmNvbS9EaWdpQ2VydEFzc3VyZWRJRFJvb3RDQS5jcmwwEQYDVR0gBAowCDAGBgRV
# HSAAMA0GCSqGSIb3DQEBDAUAA4IBAQBwoL9DXFXnOF+go3QbPbYW1/e/Vwe9mqyh
# hyzshV6pGrsi+IcaaVQi7aSId229GhT0E0p6Ly23OO/0/4C5+KH38nLeJLxSA8hO
# 0Cre+i1Wz/n096wwepqLsl7Uz9FDRJtDIeuWcqFItJnLnU+nBgMTdydE1Od/6Fmo
# 8L8vC6bp8jQ87PcDx4eo0kxAGTVGamlUsLihVo7spNU96LHc/RzY9HdaXFSMb++h
# UD38dglohJ9vytsgjTVgHAIDyyCwrFigDkBjxZgiwbJZ9VVrzyerbHbObyMt9H5x
# aiNrIv8SuFQtJ37YOtnwtoeW/VvRXKwYw02fc7cBqZ9Xql4o4rmUMIIF5zCCA8+g
# AwIBAgITIAAABxjiKPgwXr2KWgAAAAAHGDANBgkqhkiG9w0BAQsFADBcMRIwEAYK
# CZImiZPyLGQBGRYCYXUxEzARBgoJkiaJk/IsZAEZFgNjb20xEzARBgoJkiaJk/Is
# ZAEZFgNibWQxHDAaBgNVBAMTE0JNRCBJc3N1aW5nIENBIDEgRzQwHhcNMjUwNzIx
# MjMyNDM3WhcNMjgwNzIwMjMyNDM3WjAcMRowGAYDVQQDExFNYXR0aGV3IE1jUGhl
# ZSBTVTCCASIwDQYJKoZIhvcNAQEBBQADggEPADCCAQoCggEBANZdYy4F/H/cMaVb
# ldTEXkurbDKARk7dUru06IQ2AwMBNGME6ChWx8dkMq2+7L01GKgQIy5buZu3poyi
# 9BZw0rS574RDLa74cGiBEGMVXY4uWzi4XDe0KGy9tJRl1CEdk918YCdXh/5NUKvy
# i6A/UkqgeDZ7xGEulJE4zSLpoD6A2ATjC8EEm+jd84EhT6Ni47rMrguvikCrtuX3
# 6r58p9iKIvjtiy6bp/g0XUdUdw5vuXv8IvQdjPVYJw1EWUmUbBASRPYNfXaEXpum
# PsNkzp4o6cXNHEHt8/asYU7vhM17A8JSmbpWP9vBvxm3v9bsiv7+lG08ybNSQjH9
# Kq4hEo0CAwEAAaOCAeAwggHcMDsGCSsGAQQBgjcVBwQuMCwGJCsGAQQBgjcVCJ+7
# P4TwhUj1jQeBucMoht7vfYEKgeybWPC+PQIBZAIBAzATBgNVHSUEDDAKBggrBgEF
# BQcDAzALBgNVHQ8EBAMCB4AwGwYJKwYBBAGCNxUKBA4wDDAKBggrBgEFBQcDAzAd
# BgNVHQ4EFgQU0WUOo1vGBO9VpuSP8Uge4qeJJPUwHwYDVR0jBBgwFoAUzdMlDMcJ
# wraVyG8XmqIq9sn3kTYwSgYDVR0fBEMwQTA/oD2gO4Y5aHR0cDovL3BraS5ibWQu
# Y29tLmF1L3BraS9CTUQlMjBJc3N1aW5nJTIwQ0ElMjAxJTIwRzQuY3JsMFUGCCsG
# AQUFBwEBBEkwRzBFBggrBgEFBQcwAoY5aHR0cDovL3BraS5ibWQuY29tLmF1L3Br
# aS9CTUQlMjBJc3N1aW5nJTIwQ0ElMjAxJTIwRzQuY3J0MCsGA1UdEQQkMCKgIAYK
# KwYBBAGCNxQCA6ASDBBtbS5zdUBibWQuY29tLmF1ME4GCSsGAQQBgjcZAgRBMD+g
# PQYKKwYBBAGCNxkCAaAvBC1TLTEtNS0yMS0zNjQ2ODg2My0xMTExMjM5NTQ1LTEy
# MzI4Mjg0MzYtNjc0MDMwDQYJKoZIhvcNAQELBQADggIBAKlmOM2QXTNB2sHEBPHE
# 5NZXVlTNdatHwfuIqyewXSbsbimQDvM4VmsXVeONsPGkiLIVi559r79Vu/vNdcaV
# 1Ds5uNCGjYNTWw8HHE7w8AaSSD7iJgYH+Zbd/OQKzjKKZ9N4fZ8xZZT7lLrRvIh7
# xbCedFlVCOcvB76hznspJddDK7G+zQc7LcZVnEcafG8yP9RfO0vY8hnNJw2MIKfR
# 7Q/L9+m3eFSVktUKn8MuvNP1AgwV2kuWHQtKMLkadXpJGuOIwItP0Cw/fu29WtOc
# 7vpAvfJYtBPRW2ZkZ7Nnb1WA3ihGhNM7B9/HBBL+tF7BqeAThxNGBzO7ypk2fMug
# IrOKPa+l8kRG5RCAg4/SGqxDI+AHYKczI8RKMBqwulJ3cGl4XBvm0clMEwrNhyEk
# MClNCSmCma+mQkn4Bc6k6eYh6M7FMuhENgc0lZJ0WtAwi49PG6khtH862cWhJkpF
# 1+5TYVemIg6MdDRe0DiYpaZTaBvTjojknFOcWRv+mWGkTHXejlTwgX579DrGVCl2
# IEO7XamFh11kb+0i3XScXChpivvsuhhMlpEsfCYMRoE35Ap0iu0pQLNYmPzT0rab
# 8fEHJy6/AmrsQSeHmnFjEYZPnDq/rNZBkiWwybigG5fgQIT5lN0REZ5oo0EHInYB
# LI2Bco8rmvf6EiVD2I7zozZDMIIGtDCCBJygAwIBAgIQDcesVwX/IZkuQEMiDDpJ
# hjANBgkqhkiG9w0BAQsFADBiMQswCQYDVQQGEwJVUzEVMBMGA1UEChMMRGlnaUNl
# cnQgSW5jMRkwFwYDVQQLExB3d3cuZGlnaWNlcnQuY29tMSEwHwYDVQQDExhEaWdp
# Q2VydCBUcnVzdGVkIFJvb3QgRzQwHhcNMjUwNTA3MDAwMDAwWhcNMzgwMTE0MjM1
# OTU5WjBpMQswCQYDVQQGEwJVUzEXMBUGA1UEChMORGlnaUNlcnQsIEluYy4xQTA/
# BgNVBAMTOERpZ2lDZXJ0IFRydXN0ZWQgRzQgVGltZVN0YW1waW5nIFJTQTQwOTYg
# U0hBMjU2IDIwMjUgQ0ExMIICIjANBgkqhkiG9w0BAQEFAAOCAg8AMIICCgKCAgEA
# tHgx0wqYQXK+PEbAHKx126NGaHS0URedTa2NDZS1mZaDLFTtQ2oRjzUXMmxCqvkb
# sDpz4aH+qbxeLho8I6jY3xL1IusLopuW2qftJYJaDNs1+JH7Z+QdSKWM06qchUP+
# AbdJgMQB3h2DZ0Mal5kYp77jYMVQXSZH++0trj6Ao+xh/AS7sQRuQL37QXbDhAkt
# VJMQbzIBHYJBYgzWIjk8eDrYhXDEpKk7RdoX0M980EpLtlrNyHw0Xm+nt5pnYJU3
# Gmq6bNMI1I7Gb5IBZK4ivbVCiZv7PNBYqHEpNVWC2ZQ8BbfnFRQVESYOszFI2Wv8
# 2wnJRfN20VRS3hpLgIR4hjzL0hpoYGk81coWJ+KdPvMvaB0WkE/2qHxJ0ucS638Z
# xqU14lDnki7CcoKCz6eum5A19WZQHkqUJfdkDjHkccpL6uoG8pbF0LJAQQZxst7V
# vwDDjAmSFTUms+wV/FbWBqi7fTJnjq3hj0XbQcd8hjj/q8d6ylgxCZSKi17yVp2N
# L+cnT6Toy+rN+nM8M7LnLqCrO2JP3oW//1sfuZDKiDEb1AQ8es9Xr/u6bDTnYCTK
# IsDq1BtmXUqEG1NqzJKS4kOmxkYp2WyODi7vQTCBZtVFJfVZ3j7OgWmnhFr4yUoz
# ZtqgPrHRVHhGNKlYzyjlroPxul+bgIspzOwbtmsgY1MCAwEAAaOCAV0wggFZMBIG
# A1UdEwEB/wQIMAYBAf8CAQAwHQYDVR0OBBYEFO9vU0rp5AZ8esrikFb2L9RJ7MtO
# MB8GA1UdIwQYMBaAFOzX44LScV1kTN8uZz/nupiuHA9PMA4GA1UdDwEB/wQEAwIB
# hjATBgNVHSUEDDAKBggrBgEFBQcDCDB3BggrBgEFBQcBAQRrMGkwJAYIKwYBBQUH
# MAGGGGh0dHA6Ly9vY3NwLmRpZ2ljZXJ0LmNvbTBBBggrBgEFBQcwAoY1aHR0cDov
# L2NhY2VydHMuZGlnaWNlcnQuY29tL0RpZ2lDZXJ0VHJ1c3RlZFJvb3RHNC5jcnQw
# QwYDVR0fBDwwOjA4oDagNIYyaHR0cDovL2NybDMuZGlnaWNlcnQuY29tL0RpZ2lD
# ZXJ0VHJ1c3RlZFJvb3RHNC5jcmwwIAYDVR0gBBkwFzAIBgZngQwBBAIwCwYJYIZI
# AYb9bAcBMA0GCSqGSIb3DQEBCwUAA4ICAQAXzvsWgBz+Bz0RdnEwvb4LyLU0pn/N
# 0IfFiBowf0/Dm1wGc/Do7oVMY2mhXZXjDNJQa8j00DNqhCT3t+s8G0iP5kvN2n7J
# d2E4/iEIUBO41P5F448rSYJ59Ib61eoalhnd6ywFLerycvZTAz40y8S4F3/a+Z1j
# EMK/DMm/axFSgoR8n6c3nuZB9BfBwAQYK9FHaoq2e26MHvVY9gCDA/JYsq7pGdog
# P8HRtrYfctSLANEBfHU16r3J05qX3kId+ZOczgj5kjatVB+NdADVZKON/gnZruMv
# NYY2o1f4MXRJDMdTSlOLh0HCn2cQLwQCqjFbqrXuvTPSegOOzr4EWj7PtspIHBld
# NE2K9i697cvaiIo2p61Ed2p8xMJb82Yosn0z4y25xUbI7GIN/TpVfHIqQ6Ku/qjT
# Y6hc3hsXMrS+U0yy+GWqAXam4ToWd2UQ1KYT70kZjE4YtL8Pbzg0c1ugMZyZZd/B
# dHLiRu7hAWE6bTEm4XYRkA6Tl4KSFLFk43esaUeqGkH/wyW4N7OigizwJWeukcyI
# PbAvjSabnf7+Pu0VrFgoiovRDiyx3zEdmcif/sYQsfch28bZeUz2rtY/9TCA6TD8
# dC3JE3rYkrhLULy7Dc90G6e8BlqmyIjlgp2+VqsS9/wQD7yFylIz0scmbKvFoW2j
# NrbM1pD2T7m3XDCCBuwwggTUoAMCAQICEzUAAAAC0GZLfmZ188sAAAAAAAIwDQYJ
# KoZIhvcNAQELBQAwVzESMBAGCgmSJomT8ixkARkWAmF1MRMwEQYKCZImiZPyLGQB
# GRYDY29tMRMwEQYKCZImiZPyLGQBGRYDYm1kMRcwFQYDVQQDEw5CTUQgUm9vdCBD
# QSBHNDAeFw0yMzA2MTEyMzA4MjRaFw0zMzA2MTEyMzE4MjRaMFwxEjAQBgoJkiaJ
# k/IsZAEZFgJhdTETMBEGCgmSJomT8ixkARkWA2NvbTETMBEGCgmSJomT8ixkARkW
# A2JtZDEcMBoGA1UEAxMTQk1EIElzc3VpbmcgQ0EgMSBHNDCCAiIwDQYJKoZIhvcN
# AQEBBQADggIPADCCAgoCggIBAM/Mf/bIA4WDxCH8YK7n/6nVp4Kyat6zIn9iz0o/
# K2fm7U/RsvUvjPvBN7Mtke0s2KlRN0FOwzonyACentPzWX/4s+JCgoBgYTocPs9O
# jqDeruKviq+3tIi86Fh4BAItEPBaj74xYiGXWS5mPnuPsZmNmb6emls3nWjdqnhV
# V9mIKuXC8ttlsFMiQGFuL21BAv4YiwHGI39KcT76AM72/Zf2YfMmhJNb+4SL7Srd
# 6JByJnlg5Nn60kZKNDAf8WiC93cMNHfqvUVjLtiCEOPvby1HmEAsI7cbmpLjC3av
# N3kTBiV0HgnsaP0uNdSwf1LB6cvD3Ul9ggeJAnUIFe/oLSohZtQxQ0YXWywaHAur
# S8c/KlAaJFBc1XT+2XNzib49LGr1oCvbRUGcE51DARr8Ic1hQXHBn9hw2BS8CCsU
# XmUFioBKPn67UqAEOjmIrsKlnroyINnNvEhy7stT7JhxcddU9ZljyLZ9BLVccAIA
# Jkzy0hvgTC1chrUHBxsChNMDeJwdGA1EGMJsy6dAa6fTJMVAXStakAyyPLRRk15H
# SZxJQIc6jErq10zPxOVu9+Nce6qV0rdRLGsMivbtH5LqEnci8c5ELQlbH4xUbLY0
# l5ye5npgno6cQp0HoYpNMZ2VPdVRqjIu1dwoXw3XFwMeDsVNvLPSA8l/NfWON6uE
# RN2hAgMBAAGjggGqMIIBpjAQBgkrBgEEAYI3FQEEAwIBADAdBgNVHQ4EFgQUzdMl
# DMcJwraVyG8XmqIq9sn3kTYwgYMGA1UdIAR8MHoweAYIKgMEiy9DWQUwbDA6Bggr
# BgEFBQcCAjAuHiwATABlAGcAYQBsACAAUABvAGwAaQBjAHkAIABTAHQAYQB0AGUA
# bQBlAG4AdDAuBggrBgEFBQcCARYiaHR0cDovL3BraS5ibWQuY29tLmF1L3BraS9j
# cHMuaHRtbDAZBgkrBgEEAYI3FAIEDB4KAFMAdQBiAEMAQTALBgNVHQ8EBAMCAYYw
# DwYDVR0TAQH/BAUwAwEB/zAfBgNVHSMEGDAWgBT2J5dmgO4p3/UNyOna41E695LI
# NDBDBgNVHR8EPDA6MDigNqA0hjJodHRwOi8vcGtpLmJtZC5jb20uYXUvcGtpL0JN
# RCUyMFJvb3QlMjBDQSUyMEc0LmNybDBOBggrBgEFBQcBAQRCMEAwPgYIKwYBBQUH
# MAKGMmh0dHA6Ly9wa2kuYm1kLmNvbS5hdS9wa2kvQk1EJTIwUm9vdCUyMENBJTIw
# RzQuY3J0MA0GCSqGSIb3DQEBCwUAA4ICAQAiz9zaApNh2ERtqqibqwnWuxcs9fQV
# pWghvHk6L29z8ck0eNpRpqvOrzGOXHwyVQBbDfOam+PgjF8YRBqcJF1csF1+6Mlq
# +LxQGxtdAPrNPjsP+bN/g332vmhvE6bD3cP8UNJkWVk4BdTYqbvOOp1CYvytIF3R
# GVQV2oLjCh9DeQswrMked/DbEC42CC2MMJuu0dVbmTdKwRD3AuaIRaQzmBbomMDA
# opO0wnZJLTqXyUEcijtBlLJlwg/AiIieBrTWbWkZo3u5XQJVXuTxJ4vBvU8eC4+C
# jflt4bMAir3s1JZVZzSFxnuzL/Og3wSMDKIi52E7+EnEB+yEYC5JMAC2bJ7Le6w1
# v8aixsUuFSLyC8+i+RuaFwlRiiaRZV8KFRfDswK3/2XebZ03gfKDu9ibI2XzNz9q
# nRX4XovRt3OwiRdPoMEQNxb27yjBGOjbKDWJDFNrOYi4/DDtN/RBQ9UXPqCeRaXn
# yKE7eTjl7fLeb7k9wTCKbWE64YvTGNOWxPxGpraXEr5W96h9bR9z9yvN9ovADzK5
# s8w5sJjGztG+bQNitPbgZN10kb271sGtA8WyfI4Ca5FLVTswYQtWOzao7GIsaETF
# G+FhLfd9j3ckpcomWmejTAtcu99Dzx0ey5vsxKdjxV+C037pJvhI4RjONO/Gx7KE
# lbiDUpu/Lw19njCCBu0wggTVoAMCAQICEAqA7xhLjfEFgtHEdqeVdGgwDQYJKoZI
# hvcNAQELBQAwaTELMAkGA1UEBhMCVVMxFzAVBgNVBAoTDkRpZ2lDZXJ0LCBJbmMu
# MUEwPwYDVQQDEzhEaWdpQ2VydCBUcnVzdGVkIEc0IFRpbWVTdGFtcGluZyBSU0E0
# MDk2IFNIQTI1NiAyMDI1IENBMTAeFw0yNTA2MDQwMDAwMDBaFw0zNjA5MDMyMzU5
# NTlaMGMxCzAJBgNVBAYTAlVTMRcwFQYDVQQKEw5EaWdpQ2VydCwgSW5jLjE7MDkG
# A1UEAxMyRGlnaUNlcnQgU0hBMjU2IFJTQTQwOTYgVGltZXN0YW1wIFJlc3BvbmRl
# ciAyMDI1IDEwggIiMA0GCSqGSIb3DQEBAQUAA4ICDwAwggIKAoICAQDQRqwtEsae
# 0OquYFazK1e6b1H/hnAKAd/KN8wZQjBjMqiZ3xTWcfsLwOvRxUwXcGx8AUjni6bz
# 52fGTfr6PHRNv6T7zsf1Y/E3IU8kgNkeECqVQ+3bzWYesFtkepErvUSbf+EIYLkr
# LKd6qJnuzK8Vcn0DvbDMemQFoxQ2Dsw4vEjoT1FpS54dNApZfKY61HAldytxNM89
# PZXUP/5wWWURK+IfxiOg8W9lKMqzdIo7VA1R0V3Zp3DjjANwqAf4lEkTlCDQ0/fK
# JLKLkzGBTpx6EYevvOi7XOc4zyh1uSqgr6UnbksIcFJqLbkIXIPbcNmA98Oskkkr
# vt6lPAw/p4oDSRZreiwB7x9ykrjS6GS3NR39iTTFS+ENTqW8m6THuOmHHjQNC3zb
# J6nJ6SXiLSvw4Smz8U07hqF+8CTXaETkVWz0dVVZw7knh1WZXOLHgDvundrAtuvz
# 0D3T+dYaNcwafsVCGZKUhQPL1naFKBy1p6llN3QgshRta6Eq4B40h5avMcpi54wm
# 0i2ePZD5pPIssoszQyF4//3DoK2O65Uck5Wggn8O2klETsJ7u8xEehGifgJYi+6I
# 03UuT1j7FnrqVrOzaQoVJOeeStPeldYRNMmSF3voIgMFtNGh86w3ISHNm0IaadCK
# CkUe2LnwJKa8TIlwCUNVwppwn4D3/Pt5pwIDAQABo4IBlTCCAZEwDAYDVR0TAQH/
# BAIwADAdBgNVHQ4EFgQU5Dv88jHt/f3X85FxYxlQQ89hjOgwHwYDVR0jBBgwFoAU
# 729TSunkBnx6yuKQVvYv1Ensy04wDgYDVR0PAQH/BAQDAgeAMBYGA1UdJQEB/wQM
# MAoGCCsGAQUFBwMIMIGVBggrBgEFBQcBAQSBiDCBhTAkBggrBgEFBQcwAYYYaHR0
# cDovL29jc3AuZGlnaWNlcnQuY29tMF0GCCsGAQUFBzAChlFodHRwOi8vY2FjZXJ0
# cy5kaWdpY2VydC5jb20vRGlnaUNlcnRUcnVzdGVkRzRUaW1lU3RhbXBpbmdSU0E0
# MDk2U0hBMjU2MjAyNUNBMS5jcnQwXwYDVR0fBFgwVjBUoFKgUIZOaHR0cDovL2Ny
# bDMuZGlnaWNlcnQuY29tL0RpZ2lDZXJ0VHJ1c3RlZEc0VGltZVN0YW1waW5nUlNB
# NDA5NlNIQTI1NjIwMjVDQTEuY3JsMCAGA1UdIAQZMBcwCAYGZ4EMAQQCMAsGCWCG
# SAGG/WwHATANBgkqhkiG9w0BAQsFAAOCAgEAZSqt8RwnBLmuYEHs0QhEnmNAciH4
# 5PYiT9s1i6UKtW+FERp8FgXRGQ/YAavXzWjZhY+hIfP2JkQ38U+wtJPBVBajYfrb
# IYG+Dui4I4PCvHpQuPqFgqp1PzC/ZRX4pvP/ciZmUnthfAEP1HShTrY+2DE5qjzv
# Zs7JIIgt0GCFD9ktx0LxxtRQ7vllKluHWiKk6FxRPyUPxAAYH2Vy1lNM4kzekd8o
# EARzFAWgeW3az2xejEWLNN4eKGxDJ8WDl/FQUSntbjZ80FU3i54tpx5F/0Kr15zW
# /mJAxZMVBrTE2oi0fcI8VMbtoRAmaaslNXdCG1+lqvP4FbrQ6IwSBXkZagHLhFU9
# HCrG/syTRLLhAezu/3Lr00GrJzPQFnCEH1Y58678IgmfORBPC1JKkYaEt2OdDh4G
# mO0/5cHelAK2/gTlQJINqDr6JfwyYHXSd+V08X1JUPvB4ILfJdmL+66Gp3CSBXG6
# IwXMZUXBhtCyIaehr0XkBoDIGMUG1dUtwq1qmcwbdUfcSYCn+OwncVUXf53VJUNO
# aMWMts0VlRYxe5nK+At+DI96HAlXHAL5SlfYxJ7La54i71McVWRP66bW+yERNpbJ
# CjyCYG2j+bdpxo/1Cy4uPcU3AWVPGrbn5PhDBf3Froguzzhk++ami+r3Qrx5bIbY
# 3TVzgiFI7Gq3zWcxggU+MIIFOgIBATBzMFwxEjAQBgoJkiaJk/IsZAEZFgJhdTET
# MBEGCgmSJomT8ixkARkWA2NvbTETMBEGCgmSJomT8ixkARkWA2JtZDEcMBoGA1UE
# AxMTQk1EIElzc3VpbmcgQ0EgMSBHNAITIAAABxjiKPgwXr2KWgAAAAAHGDAJBgUr
# DgMCGgUAoHgwGAYKKwYBBAGCNwIBDDEKMAigAoAAoQKAADAZBgkqhkiG9w0BCQMx
# DAYKKwYBBAGCNwIBBDAcBgorBgEEAYI3AgELMQ4wDAYKKwYBBAGCNwIBFTAjBgkq
# hkiG9w0BCQQxFgQUxL8msn4IWi3Yv26vlx4KB/+JubswDQYJKoZIhvcNAQEBBQAE
# ggEAIolubCjc5mOGEPBNfn8qdrS25TiwW1xjDA1wZOsnt94dKtJBlalNwgzCiRk8
# xDSsRVSu6C8QcnTuUbqH/ElcJ+GluBLD4tG5birXP2LlyiDky+Kf67mJNryDBhrp
# cEQaCI5Bf6fP9CrPE9ukY18AwAen09cMLxJ/tx1mzQO9WTVV/sYTrkuT1ywtjZK9
# r/v27q9MgI9qnPYpz2IAy4ZpHI1Wlnf+j8mEs1PHWdWF/9vnrLGUtmnLH8sPHbXN
# 30p4utP6XvZMi10BccxFqfjJsyE+8FUHqpaMR3Xp918DgeS2sNzgbrZTfh0rhZCn
# 1tELI2vyPs09mqaS6ypbF4RUJKGCAyYwggMiBgkqhkiG9w0BCQYxggMTMIIDDwIB
# ATB9MGkxCzAJBgNVBAYTAlVTMRcwFQYDVQQKEw5EaWdpQ2VydCwgSW5jLjFBMD8G
# A1UEAxM4RGlnaUNlcnQgVHJ1c3RlZCBHNCBUaW1lU3RhbXBpbmcgUlNBNDA5NiBT
# SEEyNTYgMjAyNSBDQTECEAqA7xhLjfEFgtHEdqeVdGgwDQYJYIZIAWUDBAIBBQCg
# aTAYBgkqhkiG9w0BCQMxCwYJKoZIhvcNAQcBMBwGCSqGSIb3DQEJBTEPFw0yNTA3
# MjMwMDE2MTBaMC8GCSqGSIb3DQEJBDEiBCDvwcIYGilxNXkn305c1Qkfxo2+/gxo
# 2Oq/2FGfL3y1KDANBgkqhkiG9w0BAQEFAASCAgDMKkXkkh/F5+HyjTAEfg5iDHzG
# SIk4+3EHkRgAFVDnABHP6oJZP+ksurhvxoeysfIRX9Y7t44PnCvnUOE98ztlIef9
# bQDR8QOUvA7CgteFdZtprBMJuc+kv4UrLHhrouhLxmwRzbwpuI9Tz3RjvaTroMOu
# tBPVIxB5IpLTMomY+UMWObjFfY+PBtHB+R49CYyQgy+6PUJzT0e52Gnc/xZhlnbd
# rfW/N/WYFKLQ6509ntefojq+tEbY7sfxY4fiZECL0FXMySINp6GP4L4SmO1vQpwh
# 9Rbw+zU6eH602OHzK98PouA1OF7sDOZtiEpwBYUVleh54wZswNqIRHzT728OGk00
# vo+yJEGigj0oAYeYV/SUcyT/INLbALTw5ZaElIjx+86YY7whCAHQfbUfOD8ILxst
# 3bP1C8tIIcwfA0dAhcR2GsakuoSLW4OEgrRkxpkdqsckKgCSRUivcfNGBUCyO0Oe
# 9mQWRYwOrt/BLUI6e+ZhBX42g4HcXT4E25x9EiScDIjcWY8oWu4RmcpA2u9piaAI
# m7fKRXe70k1h71PgmJPEqr6110uXOSHjcV7+aDdEafsIe+x4uKfXRpAD5D2/4K1z
# yInWS174pFkEKTc2+gsh/uBhfysxCM6BZ/PuUupbMIw1g1bZ2l7cZ9k8LzO46TZm
# LOeAsmMILVpVqEsSOA==
# SIG # End signature block
