function Remove-SCCMAppContent {
    param (
        # Name - name of app to remove all distributed content for
        [Parameter(Mandatory)]
        [string]$Name
    )

    $ogLoc = Get-Location
    Set-Location 'A00:\'

    try {
        $app = Get-CMApplication -Name $Name -Fast
        if (-not $app) {
            Write-Warning "Application '$Name' was not found."
            return
        }

        $appName = $app.LocalizedDisplayName
        $allDps = (Get-CMDistributionPoint).NetworkOSPath.Replace('\\', '')
        $allDpGroups = (Get-CMDistributionPointGroup).Name

        # Remove content from each distribution point group individually so that a
        # destination without the content does not abort removal from the others.
        foreach ($dpGroup in $allDpGroups) {
            try {
                Remove-CMContentDistribution -ApplicationName $appName -DistributionPointGroupName $dpGroup -Force -ErrorAction Stop
                Write-Verbose "Removed content for '$appName' from distribution point group '$dpGroup'."
            }
            catch {
                Write-Verbose "Skipping distribution point group '$dpGroup': $($_.Exception.Message)"
            }
        }

        # Remove content from each distribution point individually for the same reason.
        foreach ($dp in $allDps) {
            try {
                Remove-CMContentDistribution -ApplicationName $appName -DistributionPointName $dp -Force -ErrorAction Stop
                Write-Verbose "Removed content for '$appName' from distribution point '$dp'."
            }
            catch {
                Write-Verbose "Skipping distribution point '$dp': $($_.Exception.Message)"
            }
        }
    }
    finally {
        Set-Location $ogLoc
    }
}
