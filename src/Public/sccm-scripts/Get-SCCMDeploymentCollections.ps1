function Get-SCCMDeploymentCollections {
    [CmdletBinding()]
    param (
        # ApplicationName
        [Parameter(Mandatory)]
        [string]
        $ApplicationName
    )

    try {
        $startLoc = Get-Location
        Set-Location A00:

        Get-CMApplicationDeployment -ApplicationName $ApplicationName |
        Select-Object ApplicationName, CollectionName, LastModificationTime, LastModifiedBy

        Set-Location $startLoc
    } catch {
        throw $_
    }
}
