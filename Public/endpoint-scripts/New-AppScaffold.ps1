function New-AppScaffold {
    [CmdletBinding(SupportsShouldProcess)]
    param(
        # ApplicationName
        [Parameter(Mandatory)]
        [string]
        $ApplicationName,
        # Path
        [Parameter(Mandatory)]
        [string]
        $Path
    )

    $psadtSourcePath = "C:\sources\staging\psadt_4.1.8\*"
    $stagingDestinationPath = "$Path\$ApplicationName"
    $appScriptPath = "$stagingDestinationPath\Invoke-AppDeployToolkit.ps1"
    $appScriptDestinationPath = "C:\sources\repos\matmcp1-psadt-app-scripts\$ApplicationName\Invoke-AppDeployToolkit.ps1"

    if (Test-Path -Path $stagingDestinationPath) {
        throw "Folder already exists. Exiting..."
    } else {
        New-Item -Path $stagingDestinationPath -ItemType Directory -Force
    }

    Copy-Item -Path $psadtSourcePath `
        -Destination $stagingDestinationPath `
        -Recurse `
        -Force

    # copy invoke-appdeploytoolkit.ps1 to matmcp1-app-scripts
    $appScriptFolderPath = "C:\sources\repos\matmcp1-psadt-app-scripts\$ApplicationName"
    if (-not (Test-Path -Path $appScriptFolderPath)) {
        New-Item -Path $appScriptFolderPath -ItemType Directory -Force
    }
    Copy-Item -Path $appScriptPath -Destination $appScriptDestinationPath -Force
}
