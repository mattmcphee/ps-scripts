<#
.SYNOPSIS
Removes a signature from a script or folder containing scripts.

.PARAMETER Path
Path to a script or a folder containing scripts.

.PARAMETER Recurse
Will recurse through folders when searching for scripts.

.INPUTS
[string]
File paths to a script or a folder containing scripts can be piped to this function.
[object]
An object with a FullName property (e.g. objects from Get-ChildItem) can be piped to this function.

.OUTPUTS
N/A

.EXAMPLE
PS> Remove-CodeSignature -Path "C:\sources\Example-Script.ps1"

.EXAMPLE
PS> Remove-CodeSignature -Path "C:\sources\repos\WDAC" -Recurse

.EXAMPLE
PS> Get-ChildItem -Path "C:\wdac" | Remove-CodeSignature

.NOTES
Author:     Matt McPhee
Version:    1.1
Created:    22-Jul-2025
Updated:    23-Jul-2025
#>
function Remove-CodeSignature {
    [CmdletBinding()]
    param (
        # Path - a filepath to a script file or folder containing script files
        [Parameter(Mandatory,ValueFromPipeline,ValueFromPipelineByPropertyName)]
        [ValidateScript({ Test-Path -Path $_ })]
        [Alias("FullName")]
        [string]
        $Path,
        # Recurse
        [Parameter(Mandatory=$false)]
        [switch]
        $Recurse
    )

    begin {
        # set up array to hold found scripts
        $allScripts = @()
    }

    process {
        # get scripts from each path that comes down the pipe
        if ($Recurse) {
            $scripts = Get-ChildItem -Path $Path -Include '*.ps1' -Recurse -ErrorAction Stop
        } else {
            $scripts = Get-ChildItem -Path $Path -Include '*.ps1' -ErrorAction Stop
        }

        $allScripts += $scripts
    }

    end {
        # check if we have found scripts
        if ($allScripts.Count -eq 0) {
            throw "No script files found in provided path(s)."
        }

        Write-Verbose "Found $($allScripts.Count) scripts to remove signature from."

        for ($i = 0; $i -lt $allScripts.Count; $i++) {
            Write-Progress -Activity "Removing signatures from scripts..." `
                -Status "Processing $($allScripts[$i].Name)" `
                -PercentComplete (($i / $allScripts.Count) * 100)

            $content = Get-Content -Path $allScripts[$i].FullName

            # caret is start of line
            $signatureLine = $content | Select-String '^# SIG # Begin signature block'

            # check if script contains signature block
            if ($null -eq $signatureLine) {
                Write-Verbose "No signature block found in $($allScripts[$i].FullName)"
                continue
            }

            # script content ends two lines before the script signature starts
            $lineNumber = $signatureLine.LineNumber - 2

            # new content is everything from the start up to the signature
            $newContent = $content[0..$lineNumber]

            # remove blank lines from end of file
            while ( ($newContent.Count -gt 0) -and ($newContent[-1].Trim() -eq "") ) {
                $newContent = $newContent[0..($newContent.Count - 2)]
            }

            # set content adds a new line after content
            Set-Content -Path $allScripts[$i].FullName -Value $newContent
        }
    }
}
