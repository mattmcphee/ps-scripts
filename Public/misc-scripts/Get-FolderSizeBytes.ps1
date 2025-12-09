function Get-FolderSizeBytes {
    [CmdletBinding()]
    param (
        # FolderPath
        [Parameter(Mandatory)]
        [string]
        $FolderPath
    )
    
    (Get-ChildItem -Path $FolderPath -File -Recurse | Measure-Object -Property Length -Sum).Sum
}