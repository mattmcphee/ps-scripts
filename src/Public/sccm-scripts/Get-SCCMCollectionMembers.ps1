function Get-SCCMCollectionMembers {
    [CmdletBinding()]
    param (
        # CollectionName
        [Parameter(Mandatory)]
        [string]
        $CollectionName
    )

    $ogLoc = Get-Location

    Set-Location 'A00:'

    try {
        $collName = (Get-CMCollection -Name $CollectionName).Name
        if ($collectionName.Count -gt 1) {
            Set-Location $ogLoc
            throw "Found these collections when searching for '$CollectionName': $collName`n`n"
        }
        Get-CMCollectionMember -CollectionName $CollectionName | Select-Object Name,CurrentLogonUser
    } catch {
        throw $_
    }

    Set-Location $ogLoc
}
