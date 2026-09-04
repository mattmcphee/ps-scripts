function Get-IntuneDevice {
    param(
        # DeviceName - filter results by device name; supports wildcards (* and ?)
        [Parameter(Mandatory=$false)]
        [string]$DeviceName,
        # AllProperties - will add every device property to the returned objects
        [Parameter(Mandatory=$false)]
        [switch]$AllProperties
    )

    $uri = "https://graph.microsoft.com/v1.0/deviceManagement/managedDevices"

    # only get the basic fields
    if (-not $AllProperties) {
        $uri += '?$select=id,deviceName,model'
    }

    $results = [System.Collections.Generic.List[PSCustomObject]]::new()

    while ($uri) {
        $response = Invoke-MgGraphRequest -Method GET -Uri $uri

        foreach ($device in $response.value) {
            if ($DeviceName -and $device.deviceName -notlike $DeviceName) {
                continue
            }

            if ($AllProperties) {
                $results.Add([PSCustomObject]$device)
            } else {
                $results.Add([PSCustomObject]@{
                    ID              = $device.id
                    DeviceName      = $device.deviceName
                    Model           = $device.model
                })
            }
        }

        # Move to next page if results exceed the default page size
        $uri = $response.'@odata.nextLink'
    }

    $results
}
