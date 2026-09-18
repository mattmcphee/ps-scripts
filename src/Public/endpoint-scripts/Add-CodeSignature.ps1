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
