function Copy-InstallScripts {
    [Alias("cis")]
    param(
        # TestMachineName
        [Parameter(Mandatory)]
        [string]$TestMachineName,
        # Publisher
        [Parameter(Mandatory)]
        [string]$Publisher,
        # ApplicationName
        [Parameter(Mandatory)]
        [string]$ApplicationName
    )

    $scripts = Get-ChildItem -Path "C:\sources\repos\matmcp1-psadt-app-scripts\$ApplicationName" -Recurse -Include "*.ps1"
    $scriptDirectories = $scripts.FullName | Split-Path -Parent

    foreach ($dir in $scriptDirectories) {
        try {
            Write-Verbose "Copying: '$dir' to 'C:\sources\staging'"
            Copy-Item -Path $dir -Destination "C:\sources\staging" -Recurse -Force
            Write-Verbose "Copying: '$dir' to '\\$TestMachineName\c$\windows\imecache'"
            Copy-Item -Path $dir -Destination "\\$TestMachineName\c$\windows\imecache" -Recurse -Force
            Write-Verbose "Copying: '$dir' to '\\bmd\bmdapps\sccm_packages\software\$Publisher'"
            Copy-Item -Path $dir -Destination "\\bmd\bmdapps\sccm_packages\software\$Publisher" -Recurse -Force
        } catch {
            throw $_
        }
    }
}
