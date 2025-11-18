function Get-FolderSizesGroupObject {
    [CmdletBinding()]
    param (
        # FolderPath
        [Parameter(Mandatory)]
        [string]
        $FolderPath
    )
    try {
        Get-ChildItem -Path $FolderPath -Recurse -File |
        Where-Object { $_.Length -gt '1MB' } |
        Group-Object { $_.Directory.FullName } |
        Select-Object @{
            name = 'Folder'
            expr = { $_.Name }
        },
        @{
            name = 'SizeGB'
            expr = { [math]::Round(($_.Group | Measure-Object -Property Length -Sum).Sum / 1GB, 3) }
        } |
        Where-Object { $_.SizeGB -gt '0.01'}
    } catch {
        throw $_
    }
}
