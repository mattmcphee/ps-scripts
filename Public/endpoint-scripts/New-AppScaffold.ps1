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

    if (Test-Path -Path "$Path\$ApplicationName") {
        throw "Folder already exists. Exiting..."
    } else {
        New-Item -Path "$Path\$ApplicationName" -ItemType Directory
    }

    Copy-Item -Path "C:\sources\staging\psadt_4.1.8\*" `
        -Destination "$Path\$ApplicationName" `
        -Recurse `
        -Force
}
