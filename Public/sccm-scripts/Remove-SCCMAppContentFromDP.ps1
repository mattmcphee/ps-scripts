function Remove-SCCMAppContentFromDP {
    param (
        # ApplicationName
        [Parameter(Mandatory)]
        [string]$ApplicationName
    )

    $ogLoc = Get-Location
    Set-Location "A00:"

    try {
        $apps = Get-CMApplication -Fast -Name $ApplicationName |
        Sort-Object DateCreated |
        Select-Object -SkipLast 2
    } catch {
        Set-Location $ogLoc
        throw $_
    }

    if ($apps.Count -lt 1) {
        Set-Location $ogLoc
        throw "Could not find any applications when searching for '$ApplicationName'"
    }

    try {
        $dpGroups = Get-CMDistributionPointGroup
    } catch {
        Set-Location $ogLoc
        throw $_
    }

    try {
        $dps = Get-CMDistributionPoint
    } catch {
        Set-Location $ogLoc
        throw $_
    }

    foreach ($app in $apps) {
        Write-Verbose "Starting content removal from DPs for: '$($app.LocalizedDisplayName)'"

        # remove content from all dp groups
        foreach ($group in $dpGroups) {
            Write-Verbose "Attempting removal from DP Group: $($group.Name)"
            $removeCMContentDistributionDPGroupsArgs = @{
                ApplicationName             = $app.LocalizedDisplayName
                DistributionPointGroupName  = $group.Name
                Force                       = $true
                ErrorAction                 = "SilentlyContinue"
            }
            Remove-CMContentDistribution @removeCMContentDistributionDPGroupsArgs
        }

        # remove content from individual DPs
        foreach ($dp in $dps) {
            Write-Verbose "Attempting removal from DP: $($dp.SiteSystemServerName)"
            $removeCMContentDistributionDPPointArgs = @{
                ApplicationName             = $app.LocalizedDisplayName
                DistributionPointName       = $dp.SiteSystemServerName
                Force                       = $true
                ErrorAction                 = "SilentlyContinue"
            }
            Remove-CMContentDistribution @removeCMContentDistributionDPPointArgs
        }
    }

    Write-Verbose "Content removal complete."

    Set-Location $ogLoc
}
