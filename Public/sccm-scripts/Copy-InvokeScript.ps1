function Copy-InvokeScript {
    [CmdletBinding()]
    param (
        # SourcePath
        [Parameter(Mandatory)]
        [string]
        $SourcePath,
        # ApplicationName
        [Parameter(Mandatory)]
        [string]
        $ApplicationName,
        # Publisher
        [Parameter(Mandatory)]
        [string]
        $Publisher,
        # ComputerName
        [Parameter(Mandatory)]
        [string]
        $ComputerName
    )

    $ogLoc = Get-Location

    Set-Location "C:\"

    try {
        $localUninstallPath = $SourcePath.Replace("Install", "Uninstall")
        $shareInstallPath = "\\bmd\bmdapps\sccm_packages\software\$Publisher\$ApplicationName\Install\Invoke-AppDeployToolkit.ps1"
        $shareUninstallPath = $shareInstallPath.Replace("Install", "Uninstall")
        $remoteInstallPath = $SourcePath.Replace("C:\", "\\$ComputerName\c`$\")
        $remoteUninstallPath = $remoteInstallPath.Replace("Install", "Uninstall")
        
        $destinationPaths = @(
            $localUninstallPath,
            $shareInstallPath,
            $shareUninstallPath,
            $remoteInstallPath,
            $remoteUninstallPath
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