function New-AppScaffold {
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

    if(Test-Path -Path "$Path\$ApplicationName") {
        Write-Host "Folder already exists. Exiting..."
        return
    } else {
        New-Item -Path "$Path\$ApplicationName" -ItemType Directory
    }

    New-Item -Path "$Path\$ApplicationName" -Name "Install" -ItemType Directory
    New-Item -Path "$Path\$ApplicationName" -Name "Uninstall" -ItemType Directory

    Invoke-Expression -Command 'robocopy "C:\sources\staging\bmd-psadt" "$Path\$ApplicationName\Install" /e'
    Invoke-Expression -Command 'robocopy "C:\sources\staging\bmd-psadt" "$Path\$ApplicationName\Uninstall" /e'
}
