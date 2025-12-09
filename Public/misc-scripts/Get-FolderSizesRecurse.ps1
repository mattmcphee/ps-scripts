function Get-FolderSizesRecurse {
    [CmdletBinding()]
    param (
        # FolderPath
        [Parameter(Mandatory)]
        [string]
        $FolderPath
    )
    try {
        Get-ChildItem -Path $FolderPath -Directory -Recurse | ForEach-Object {
            $size = (Get-ChildItem -Path $_.FullName -File -Recurse -ErrorAction SilentlyContinue |
                Measure-Object -Property Length -Sum).Sum
            [PSCustomObject]@{
                Folder = $_.FullName
                SizeGB = [math]::Round($size / 1GB, 2)
            }
        }
    } catch {
        throw $_
    }
}
