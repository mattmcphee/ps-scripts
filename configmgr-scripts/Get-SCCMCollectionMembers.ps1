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
        (Get-CMCollectionMember -CollectionName $CollectionName | Select-Object Name,CurrentLogonUser)
    } catch {
        throw $_
    }

    Set-Location $ogLoc
}
