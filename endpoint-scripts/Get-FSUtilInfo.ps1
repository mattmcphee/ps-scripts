function Get-FSUtilInfo {
    [CmdletBinding()]
    param (
        # Folder path
        [Parameter(Mandatory=$true)]
        [string]
        $FolderPath
    )
    # recursively get a list of files in the folder path
    $files = Get-ChildItem -Recurse -File -Path $FolderPath
    # for each file, run fsutil against it
    for ($i = 0; $i -lt $files.Count; $i++) {
        fsutil file queryea $files[$i].FullName
    }
}