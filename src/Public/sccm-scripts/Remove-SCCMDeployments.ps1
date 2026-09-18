function Remove-SCCMDeployments {
    [CmdletBinding()]
    param (
        # ApplicationName
        [Parameter(Mandatory = $true)]
        [string[]]
        $ApplicationName
    )

    $ogLoc = Get-Location

    Set-Location 'A00:'

    try {
        foreach ($name in $ApplicationName) {
            $app = Get-CMApplication -Name "$name" -Fast
            if ($app.Count -lt 1) {
                throw "Application '$name' not found."
            } elseif ($app.Count -gt 1) {
                throw "Found more than one application when searching for '$name'. Be more specific."
            }

            $app | Remove-CMApplicationDeployment -Force
            Write-Verbose "Successfully removed all deployments for application '$name'."
        }
    } catch {
        Write-Warning "Could not remove deployments for application '$name' - no deployments found."
        Set-Location $ogLoc
    }

    Set-Location $ogLoc
}
