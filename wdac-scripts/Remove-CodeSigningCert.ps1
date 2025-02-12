function Remove-CodeSigningCert {
    [CmdletBinding()]
    param (
        # file or folder path
        [Parameter(Mandatory=$true)]
        [ValidateScript({ Test-Path -Path $_ })]
        [string]
        $Path
    )

    $scripts = Get-ChildItem -Path $Path -Filter '*.ps1'

    foreach ($script in $scripts) {
        $fileContent = Get-Content $script
        $sigLine = $fileContent | Select-String "SIG # Begin signature block"

        if ($null -eq $sigLine) {
            Write-Host "No signature found in file: $script"
            continue
        }

        $lastLineOfScript = $sigLine.LineNumber - 2
        $newContent = $fileContent[0..$lastLineOfScript]
        $newContent | Set-Content $script
    }
}
