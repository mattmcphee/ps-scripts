function Get-DepCol {
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

        Get-CMApplicationDeployment -ApplicationName $ApplicationName | Select-Object CollectionName | Format-Table -AutoSize

        Set-Location $startLoc
    } catch {
        throw $_
    }
}
