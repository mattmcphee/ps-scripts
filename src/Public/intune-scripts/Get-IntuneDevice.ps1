function Get-IntuneDevice {
    param(
        # DeviceName - filter results by device name; supports wildcards (* and ?)
        [Parameter(Mandatory=$false)]
        [string]$DeviceName,

        # AllProperties - will add every device property to the returned objects
        [Parameter(Mandatory=$false)]
        [switch]$AllProperties
    )

    $query = @('$top=1000')

    # only get the basic fields
    if (-not $AllProperties) {
        $query += '$select=id,deviceName,model,userPrincipalName,userDisplayName'
    }

    $needsClientFilter = $false

    if ($DeviceName) {
        $wildcardIndex = $DeviceName.IndexOfAny([char[]]'*?')
        if ($wildcardIndex -lt 0) {
            $query += "`$filter=deviceName eq '$($DeviceName.Replace("'", "''"))'"
        } elseif ($wildcardIndex -gt 0) {
            $prefix = $DeviceName.Substring(0, $wildcardIndex).Replace("'", "''")
            $query += "`$filter=startswith(deviceName,'$prefix')"
            # Only "PREFIX*" is fully handled by Graph; anything else needs a -like check
            $needsClientFilter = $DeviceName -ne ($DeviceName.Substring(0, $wildcardIndex) + '*')
        } else {
            $needsClientFilter = $true  # leading wildcard: Graph can't filter this
        }
    }

    $uri = 'https://graph.microsoft.com/v1.0/deviceManagement/managedDevices?' + ($query -join '&')

    while ($uri) {
        $response = Invoke-MgGraphRequest -Method GET -Uri $uri

        foreach ($device in $response.value) {
            if ($needsClientFilter -and $device.deviceName -notlike $DeviceName) { continue }

            if ($AllProperties) {
                [PSCustomObject]$device
            } else {
                [PSCustomObject]@{
                    ID                  = $device.id
                    DeviceName          = $device.deviceName
                    Model               = $device.model
                    UserPrincipalName   = $device.userPrincipalName
                    UserDisplayName     = $device.userDisplayName
                }
            }
        }

        # Move to next page if results exceed the default page size
        $uri = $response.'@odata.nextLink'
    }
}
