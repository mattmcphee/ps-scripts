function Get-FolderSizes {
    param (
        # Path
        [Parameter(Mandatory)]
        [string]
        $Path
    )

    $folders = Get-ChildItem -Path $Path -Directory -Recurse

    $folderSizes = foreach ($folder in $folders) {
        $size = (Get-ChildItem -Path ($folder.FullName) -File -Recurse | Measure-Object -Property Length -Sum).Sum
        $sizeInGB = $size / 1GB

        # collect data
        [PSCustomObject]@{
            FolderName = $folder.FullName
            SizeInGB = [Math]::Round($sizeInGB,2)
        }
    }

    $folderSizes
}
