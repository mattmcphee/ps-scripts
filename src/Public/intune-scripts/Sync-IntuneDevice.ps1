function Sync-IntuneDevice {
    [CmdletBinding()]
    param (
        # ComputeerName
        [Parameter(Mandatory)]
        [string[]]$ComputerName
    )

    foreach ($computer in $ComputerName) {
        try {
            $name = $computer.Replace("'", "''")

            $intuneDevice = Get-IntuneDevice -DeviceName $name

            if ($intuneDevice.Count -lt 1) {
                Write-Warning "Could not find device with name '$name'."
                continue
            } elseif ($intuneDevice.Count -gt 1) {
                Write-Warning "Found more than 1 device when searching for '$name'. Skipping..."
                continue
            }

            $deviceId = $intuneDevice[0].id

            $uri = "https://graph.microsoft.com/v1.0/deviceManagement/managedDevices/$deviceId/syncDevice"

            Invoke-MgGraphRequest -Method POST -Uri $uri -ErrorAction Stop | Out-Null

            [PSCustomObject]@{
                ComputerName = $name
                DeviceId     = $deviceId
                Status       = 'Sync requested'
            }
        }
        catch {
            Write-Error "Failed to sync ${computer}: $($_.Exception.Message)"
        }
    }
}
