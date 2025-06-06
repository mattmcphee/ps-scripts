<#
.SYNOPSIS
Gets scripts using Get-ChildItem to get files with ps1 extension in a specified
folder then signs scripts using a codesigning certificate.
.NOTES
Author:     Matt McPhee
Created:    13/09/2025
Updated:    06/05/2025
#>
function Add-CodeSigningCert {
    [CmdletBinding()]
    param (
        # Path to a script or folder containing scripts you wish to sign
        [Parameter(Mandatory=$true)]
        [ValidateScript({ Test-Path -Path $_ })]
        [string]
        $Path
    )
    $scripts = Get-ChildItem -Path $Path -Filter '*.ps1'
    foreach ($script in $scripts) {
        $certPath = 'Cert:\CurrentUser\My\3B05E6E33027E0B2AB333BB23668A300BE1A43B9'
        $cert = (Get-ChildItem -Path $certPath -CodeSigningCert)
        try {
            Set-AuthenticodeSignature -Certificate $cert `
                -FilePath $script.FullName `
                -HashAlgorithm "SHA256" `
                -IncludeChain notroot `
                -TimestampServer 'http://timestamp.digicert.com' `
                -ErrorAction 'Stop'
            Write-Host "Signed: $($script.FullName)"
        } catch {
            Write-Host "Encountered error!"
            Write-Host "$_"
        }
    }
}
