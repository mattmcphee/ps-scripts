function Get-EntraStaleWindowsDeviceReport {
    <#
    .SYNOPSIS
        Reports Windows devices in Entra ID that are stale (180+ days inactive),
        including matching Intune and Active Directory records.
    .DESCRIPTION
        Intune devices are matched on azureAdDeviceId. AD computers are matched on
        objectGUID (equal to the Entra deviceId for hybrid joined devices), falling
        back to computer name. A device is considered stale when Entra has had no
        activity for 180+ days and any matching Intune/AD record is also inactive
        for 180+ days.
        Requires Connect-MgGraph (Device.Read.All, DeviceManagementManagedDevices.Read.All)
        and the ActiveDirectory module.
    .EXAMPLE
        Get-EntraStaleWindowsDevice -ExportPath C:\temp\StaleWindowsDevices.csv
    #>
    [CmdletBinding()]
    param (
        # ExportPath
        [Parameter(Mandatory=$false)]
        [string]$ExportPath
    )

    $cutoff = (Get-Date).AddDays(-180)

    $entraUri = 'https://graph.microsoft.com/v1.0/devices?$top=999&'
    $entraUriQuery = @(
        '$select=id'
        'deviceId'
        'displayName'
        'operatingSystem'
        'operatingSystemVersion'
        'approximateLastSignInDateTime'
        'accountEnabled'
        'isManaged'
        'trustType'
    ) -join ","

    $uri = $entraUri + $entraUriQuery

    $entraDevices = while ($uri) {
        $response = Invoke-MgGraphRequest -Method 'GET' -Uri $uri

        foreach ($device in $response.value) {
            if ($device.operatingSystem -match '^Windows') {
                $device
            }
        }

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
            $intuneByDeviceId[$device.azureAdDeviceId.ToLowerInvariant()] = $device
        }
    }

    $adComputers = Get-ADComputer -Filter "OperatingSystem -like 'Windows*'" -Properties LastLogonDate, OperatingSystem

    # index AD computers by objectGUID and name
    $adByGuid = @{}
    $adByName = @{}

    foreach ($computer in $adComputers) {
        $adByGuid[$computer.ObjectGUID.ToString().ToLowerInvariant()] = $computer
        $adByName[$computer.Name.ToUpperInvariant()] = $computer
    }

    $report = foreach ($device in $entraDevices) {
        $key = $device.deviceId.ToLowerInvariant()
        $managed = $intuneByDeviceId[$key]

        $adMatchType = $null
        $ad = $adByGuid[$key]
        if ($ad) {
            $adMatchType = 'ObjectGUID'
        } elseif ($device.displayName) {
            $ad = $adByName[$device.displayName.ToUpperInvariant()]
            if ($ad) { $adMatchType = 'Name' }
        }

        $entraLastSignIn = $device.approximateLastSignInDateTime
        $hasEntraLastSignIn = [bool]$device.approximateLastSignInDateTime
        $entraStale = -not $entraLastSignIn -or ($entraLastSignIn -lt $cutoff)
        $intuneStale = $managed -and (-not $managed.lastSyncDateTime -or ($managed.lastSyncDateTime -lt $cutoff))
        $adStale = $ad -and (-not $ad.LastLogonDate -or ($ad.LastLogonDate -lt $cutoff))

        $stale = $entraStale -and (-not $managed -or $intuneStale) -and (-not $ad -or $adStale)

        $classification = if (-not $hasEntraLastSignIn) {
            'No last sign in found.'
        } elseif (-not $entraStale) {
            'Entra active within 180 days.'
        } elseif ($managed -and -not $intuneStale) {
            'Entra stale, but Intune active within 180 days.'
        } elseif ($ad -and -not $adStale) {
            'Entra stale, but AD active within 180 days.'
        } elseif ($managed -and $ad) {
            'Stale. Entra, Intune and AD all inactive over 180 days.'
        } elseif ($managed) {
            'Stale. Entra and Intune inactive over 180 days. No AD record.'
        } elseif ($ad) {
            'Stale. Entra and AD inactive over 180 days. No Intune record.'
        } else {
            'Stale. Entra inactive over 180 days. No Intune or AD record.'
        }

        [PSCustomObject]@{
            DeviceName          = $device.displayName
            OS                  = $device.operatingSystem
            OSVersion           = $device.operatingSystemVersion
            TrustType           = $device.trustType
            EntraObjectId       = $device.id
            EntraDeviceId       = $device.deviceId
            EntraAccountEnabled = $device.accountEnabled
            EntraManaged        = $device.isManaged
            EntraLastSignIn     = $entraLastSignIn
            IntunePresent       = [bool]$managed
            IntuneLastSync      = $managed.lastSyncDateTime
            SerialNumber        = $managed.serialNumber
            Ownership           = $managed.managedDeviceOwnerType
            ADPresent           = [bool]$ad
            ADMatchType         = $adMatchType
            ADEnabled           = $ad.Enabled
            ADLastLogon         = $ad.LastLogonDate
            ADDistinguishedName = $ad.DistinguishedName
            Stale               = [bool]$stale
            Classification      = $classification
        }
    }

    if ($ExportPath) {
        $report | Export-Csv $ExportPath -NoTypeInformation -Force
    }

    $report | Group-Object Classification | Select-Object Name, Count
}
