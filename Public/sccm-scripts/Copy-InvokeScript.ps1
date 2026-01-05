function Copy-InvokeScript {
    [CmdletBinding()]
    param (
        # SourcePath
        [Parameter(Mandatory)]
        [string]
        $SourcePath,
        # ComputerName
        [Parameter(Mandatory)]
        [string]
        $ComputerName
    )

    $ogLoc = Get-Location

    Set-Location "C:\"

    try {
        $remotePath = $SourcePath.Replace("C:\", "\\$ComputerName\c`$\")
        
        $destinationPaths = @(
            $remotePath
        )

        foreach ($destinationPath in $destinationPaths) {
            if (Test-Path $destinationPath) {
                Copy-Item -Path $SourcePath -Destination $destinationPath -Force
                Write-Host "Copied invoke-appdeploytookit.ps1 to $destinationPath" -ForegroundColor Green
            } else {
                Write-Host "Could not find path: $destinationPath" -ForegroundColor Red
            }
        }
    } catch {
        throw $_
    }

    Set-Location $ogLoc
}
