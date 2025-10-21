function Add-DeviceToCollection {
    [CmdletBinding()]
    param(
        # ComputerName
        [Parameter(Mandatory)]
        [string]
        $ComputerName,
        # MACAddress
        [Parameter(Mandatory)]
        [string]
        $MACAddress,
        # CollectionName
        [Parameter(Mandatory)]
        [string]
        $CollectionName
    )

    try {
        # check if machine name already exists
        try {
            $cmDevice = Get-CMDevice -Name $ComputerName -ErrorAction Stop
        } catch {
            $cmDevice = $null
        }

        if ($cmDevice) {
            throw "A device named $ComputerName already exists."
        }

        # check if mac address already taken
        $cmDeviceMac = Get-CMDevice -Fast | Where-Object { $_.MACAddress -like $MACAddress } | Select-Object -First 1
        if ($cmDeviceMac) {
            throw "A device with MAC address $MACAddress already exists."
        }

        Write-Host "Creating computer '$ComputerName' with MAC address '$MacAddress'"

        $device = Import-CMComputerInformation -ComputerName $ComputerName `
            -MacAddress $MACAddress `
            -ErrorAction Stop

        Write-Host "Import complete. Waiting for ResourceID..."

        $resourceID = $null
        $maxAttempts = 60
        $currAttempt = 0
        $waitSecs = 20

        while ($currAttempt -lt $maxAttempts) {
            $device = $null
            $currAttempt++
            Write-Host "This is wait $currAttempt of $maxAttempts with $waitSecs seconds between attempts."
            Start-Sleep -Seconds $waitSecs
            $device = Get-CMDevice -Name $ComputerName -ErrorAction SilentlyContinue

            if ($device) {
                $resourceID = $device.ResourceID
                break
            }
        }

        if (-not $resourceID) {
            throw "Failed to retrieve device resource ID after '$maxAttempts' attempts. Aborting..."
        }

        Write-Host "Resource ID found: '$resourceID'"
        Write-Host "Adding '$($device.Name)' to collection '$CollectionName' using a direct membership rule..."

        Add-CMDeviceCollectionDirectMembershipRule -CollectionName $CollectionName `
            -ResourceId $resourceID

        Write-Host "Successfully added $ComputerName to $CollectionName"
    } catch {
        throw $_
    }
}
