function Get-ContentLocation {
    [CmdletBinding()]
    param (
        # ApplicationName
        [Parameter(Mandatory)]
        [string]
        $ApplicationName
    )
    
    $appDts = Get-CMDeploymentType -ApplicationName $ApplicationName

    $appDts | Select-Object LocalizedDisplayName, @{
        name = 'ContentLocation'
        expr = {
            ($_.SDMPackageXML | Select-String '<Location>(.*)</Location>').Matches.Groups[1].Value
        }
    }
}
