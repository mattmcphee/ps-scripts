function Remove-ScriptSignature {
    [CmdletBinding()]
    param (
        # Path - a filepath to a script file or folder containing script files
        [Parameter(Mandatory)]
        [ValidateScript({ Test-Path -Path $_ })]
        [string]
        $Path,
        # Recurse
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

    # check if we have found scripts
    if ($scripts.Count -eq 0) {
        throw "No script files found in $Path"
    }

    foreach ($script in $scripts) {
        $content = Get-Content -Path $script.FullName

        $signatureLine = $content | Select-String "SIG # Begin signature block"

        # check if script contains signature block
        if ($null -eq $signatureLine) {
            Write-Output "No signature block found in $($script.FullName)"
            continue
        }

        # script content ends two lines before the script signature starts
        $lineNumber = $signatureLine.LineNumber - 2
        # decrement linenumber here to ensure only one blank newline after script content
        $newContent = $content[0..$lineNumber]

        Set-Content -Path $script.FullName -Value $newContent
    }
}
