function Remove-SCCMAppContent {
    param (
        # Name - name of app to remove all distributed content for
        [Parameter(Mandatory)]
        [string]$Name
    )

    $ogLoc = Get-Location
    Set-Location 'A00:\'

    $app = Get-CMApplication -Name $Name -Fast
    $allDps = (Get-CMDistributionPoint).NetworkOSPath.Replace('\\', '')
    $allDpGroups = (Get-CMDistributionPointGroup).Name

    Remove-CMContentDistribution -ApplicationName $app.LocalizedDisplayName -DistributionPointGroupName $allDpGroups -Force -ErrorAction SilentlyContinue
    Remove-CMContentDistribution -ApplicationName $app.LocalizedDisplayName -DistributionPointName $allDps -Force -ErrorAction SilentlyContinue

    Set-Location $ogLoc
}
