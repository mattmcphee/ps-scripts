function Get-EntraStaleMobileDeviceReport {
    [CmdletBinding()]
    param (
        # ExportPath
        [Parameter(Mandatory=$false)]
        [string]$ExportPath
    )

    $cutoff = (Get-Date).AddDays(-180)

    $entraUri = 'https://graph.microsoft.com/v1.0/devices?'
    $entraUriQuery = @(
        '$select=id'
        'deviceId'
        'displayName'
        'operatingSystem'
        'registrationDateTime'
        'approximateLastSignInDateTime'
        'accountEnabled'
        'createdDateTime'
        'isManaged'
        'trustType'
    ) -join ","

    $uri = $entraUri + $entraUriQuery

    $entraDevices = while ($uri) {
        $response = Invoke-MgGraphRequest -Method 'GET' -Uri $uri

        foreach ($device in $response.value) {
            if ($device.operatingSystem -match '^(Android|iOS|iPadOS)') {
                $device
            }
        }

        # Move to next page if results exceed the default page size
        $uri = $response.'@odata.nextLink'
    }

    $intuneUri = 'https://graph.microsoft.com/v1.0/deviceManagement/managedDevices'

    $intuneDevices = while ($intuneUri) {
        $response = Invoke-MgGraphRequest -Method 'GET' -Uri $intuneUri

        $response.value

        $intuneUri = $response.'@odata.nextLink'
    }

    # index intune devices by entra device id
    $intuneByDeviceId = @{}

    foreach ($device in $intuneDevices) {
        if ($device.azureAdDeviceId) {
            $key = $device.azureAdDeviceId.ToLowerInvariant()
            $intuneByDeviceId[$key] = $device
        }
    }

    $report = foreach ($device in $entraDevices) {
        $key = $device.deviceId.ToLowerInvariant()
        $managed = $intuneByDeviceId[$key]

        $entraStale = $device.approximateLastSignInDateTime -and ($device.approximateLastSignInDateTime -lt $cutoff)
        $intuneStale = $managed -and $managed.LastSyncDateTime -and ($managed.LastSyncDateTime -lt $cutoff)

        $classification = if ($managed -and $entraStale -and $intuneStale) {
            'Matching Intune record found. Entra and Intune last contact was over 180 days ago.'
        } elseif (-not $managed -and $entraStale) {
            'No matching Intune record found. Entra last contact was over 180 days ago.'
        } elseif ($managed -and $intuneStale) {
            'Matching Intune record found. Intune last contact was over 180 days ago.'
        } elseif (-not $device.approximateLastSignInDateTime) {
            'No Entra activity.'
        } else {
            'No signs of staleness.'
        }

        [PSCustomObject]@{
            DeviceName      = $device.DisplayName
            SerialNumber    = $managed.serialNumber
            OS              = $device.OperatingSystem
            EntraDeviceId   = $device.DeviceId
            EntraLastSignIn = $device.ApproximateLastSignInDateTime
            IntuneLastSync  = $managed.LastSyncDateTime
            IntunePresent   = [bool]$managed
            Ownership       = $managed.ManagedDeviceOwnerType
            EntraManaged    = $device.IsManaged
            AccountEnabled  = $device.AccountEnabled
            Classification  = $classification
        }
    }

    if ($ExportPath) {
        $report | Export-Csv $ExportPath -NoTypeInformation -Force
    }

    $report | Group-Object Classification | Select-Object Name, Count
}
