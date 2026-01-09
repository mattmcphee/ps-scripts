function Deploy-IntuneAppAllDevices {
    [CmdletBinding()]
    param (
        # DisplayName
        [Parameter(Mandatory)]
        [string]$DisplayName
    )

    # deploy app to all devices
    try {
        $appID = Get-IntuneWin32App | Where-Object { $_.displayName -like $DisplayName } | Select-Object -ExpandProperty "ID"

        if ($appID.Count -lt 1) {
            throw "Found no applications with DisplayName: $DisplayName"
        } elseif ($appID.Count -gt 1) {
            throw "Found more than one application when searching using display name: $DisplayName. Be more specific."
        }

        Add-IntuneWin32AppAssignmentAllDevices `
            -ID $appID `
            -Intent "available" `
            -Notification "showAll" `
            -DeliveryOptimizationPriority "foreground"

    } catch {
        throw "Error encountered when deploying app: $_"
    }
}
