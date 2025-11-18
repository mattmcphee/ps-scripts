function Get-ContentLocation {
    [CmdletBinding()]
    param (
        # ApplicationName
        [Parameter(Mandatory)]
        [string]
        $ApplicationName
    )

    $ogLoc = Get-Location
    Set-Location 'A00:'
    
    $appDts = Get-CMDeploymentType -ApplicationName $ApplicationName

    $nameAndFolder = $appDts |
    Select-Object LocalizedDisplayName, @{
        name = 'ContentLocation'
        expr = {
            $location = ($_.SDMPackageXML | Select-String '<Location>(.*)</Location>').Matches.Groups[1].Value
            $location = $location.Substring(0, $location.Length - 1)
            $location
        }
    }

    Set-Location $env:WINDIR

    $nameAndFolder | Select-Object *, @{
        name = 'Size'
        expr = {
            "$((Get-ChildItem -Path $_.ContentLocation -File -Recurse | Measure-Object -Property Length -Sum).Sum) bytes"
        }
    }, @{
        name = 'LastWriteTime'
        expr = {
            (Get-Item -Path $_.ContentLocation).LastWriteTime.ToString('hh:mm:ss tt dd-MMM-yyyy')
        }
    } |
    Sort-Object { (Get-Item $_.ContentLocation).LastWriteTime }

    Set-Location $ogLoc
}
