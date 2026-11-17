function Get-IntunePrimaryUser {
    [CmdletBinding()]
    param (
        # ComputerName
        [Parameter(Mandatory)]
        [string]$ComputerName
    )

    $intuneDevice = @(Get-IntuneDevice -DeviceName $ComputerName)

    if ($intuneDevice.Count -lt 1) {
        Write-Warning "Could not find device with name '$ComputerName'."
        return
    } elseif ($intuneDevice.Count -gt 1) {
        Write-Warning "Found more than 1 device when searching for '$ComputerName'. Skipping..."
        return
    }

    $deviceId = $intuneDevice[0].ID

    $uri = "https://graph.microsoft.com/v1.0/deviceManagement/managedDevices/$deviceId/users"

    $result = (Invoke-MgGraphRequest -Method GET -Uri $uri).value

    [PSCustomObject]@{
        DeviceID                    = $deviceId
        ComputerName                = $ComputerName
        PrimaryUserID                      = $result.id
        PrimaryUserPrincipalName    = $result.userPrincipalName
        PrimaryUserDisplayName      = $result.displayName
        PrimaryUserEmailAddress     = $result.mail
        PrimaryUserJobTitle         = $result.jobTitle
    }
}
