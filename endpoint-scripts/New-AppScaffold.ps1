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

    Copy-Item -Path 'C:\sources\staging\bmd-psadt-4\*' `
        -Destination "$Path\$ApplicationName\Install" `
        -Recurse `
        -Force

    Copy-Item -Path 'C:\sources\staging\bmd-psadt-4\*' `
        -Destination "$Path\$ApplicationName\Uninstall" `
        -Recurse `
        -Force
}
