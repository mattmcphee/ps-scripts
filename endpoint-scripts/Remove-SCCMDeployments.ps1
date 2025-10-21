function Remove-SCCMDeployments {
    [CmdletBinding()]
    param (
        # ApplicationName
        [Parameter(Mandatory = $true)]
        [string]
        $ApplicationName
    )
        
    try {
        $app = Get-CMApplication -Name "$ApplicationName" -Fast
        if ($app.Count -lt 1) {
            throw "Application '$ApplicationName' not found."
        } elseif ($app.Count -gt 1) {
            throw "Found more than one application when searching for '$ApplicationName'. Be more specific."
        }

        $app | Remove-CMApplicationDeployment -Force
        Write-Verbose "Successfully removed all deployments for application '$ApplicationName'."
    } catch {
        throw $_
    }
}