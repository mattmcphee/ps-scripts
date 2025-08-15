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

    if (Test-Path -Path "$Path\$ApplicationName") {
        throw "Folder already exists. Exiting..."
    } else {
        New-Item -Path "$Path\$ApplicationName" -ItemType Directory
    }

    New-Item -Path "$Path\$ApplicationName" -Name "Install" -ItemType Directory

    Copy-Item -Path "C:\sources\staging\PSAppDeployToolkit_v4.1.0\*" `
        -Destination "$Path\$ApplicationName\Install" `
        -Recurse `
        -Force
}
