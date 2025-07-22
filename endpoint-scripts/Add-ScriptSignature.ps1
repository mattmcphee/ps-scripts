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

.EXAMPLE
PS> Add-ScriptSignature -Path "C:\sources\repos\example-script.ps1"

.EXAMPLE
PS> Add-ScriptSignature -Path "C:\sources\repos\WDAC" -Recurse

.EXAMPLE
PS> Add-ScriptSignature -Path "C:\sources\repos\example-script.ps1" -Thumbprint "abcdefg"

.NOTES
Author:     Matt McPhee
Version:    1.0
Created:    13/09/2025
Updated:    22/07/2025
#>
function Add-ScriptSignature {
    [CmdletBinding()]
    param (
        # Path - script or folder containing scripts you wish to sign
        [Parameter(Mandatory=$true,ValueFromPipeline=$true)]
        [ValidateScript({ Test-Path -Path $_ })]
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

    # get scripts
    if ($Recurse) {
        $scripts = Get-ChildItem -Path $Path -Filter '*.ps1' -Recurse -ErrorAction Stop
    } else {
        $scripts = Get-ChildItem -Path $Path -Filter '*.ps1' -ErrorAction Stop
    }

    # throw error if no scripts found
    if ($scripts.Count -eq 0) {
        throw "No script files found in $Path"
    }

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

    # throw error if no codesigning cert
    if ($cert.Count -eq 0) {
        throw "Unable to find CodeSigning certificate."
    }

    # loop through and sign each script found
    foreach ($script in $scripts) {
        try {
            Set-AuthenticodeSignature -Certificate $cert `
                -FilePath $script.FullName `
                -TimestampServer 'http://timestamp.digicert.com' `
                -ErrorAction 'Stop' | Out-Null
        } catch {
            Write-Error $_
        }
    }
}
