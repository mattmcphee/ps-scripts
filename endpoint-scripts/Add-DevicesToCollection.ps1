function Add-DevicesToCollection {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true,ValueFromPipeline)]
        [string[]]$ComputerName,

        [Parameter(Mandatory = $true)]
        [string]$CollectionName
    )

    begin {
        Import-MEMModule A00

        Write-Host "Starting to add devices from '$ComputerName' to collection '$CollectionName'"

        # Initialize counters for tracking operation results
        $SuccessCount = 0
        $ErrorCount = 0
    }

    process {
        try {
            # Process each device name individually
            foreach ($DeviceName in $ComputerName) {
                try {
                    Write-Host "Processing device: $DeviceName"

                    # Query SCCM for the device using its name
                    $Device = Get-CMDevice -Name $DeviceName -ErrorAction Stop

                    if ($Device) {
                        # Add the device to the specified collection using direct membership rule
                        try {
                            Add-CMDeviceCollectionDirectMembershipRule -CollectionName $CollectionName -ResourceID $Device.ResourceID -ErrorAction Stop
                            Write-Host "Successfully added $DeviceName to collection`n" -ForegroundColor Green
                            $SuccessCount++
                        } catch {
                            Write-Host "Failed to add $DeviceName to collection: $($_.Exception.Message)`n" -ForegroundColor Red
                            $ErrorCount++

                        }

                    } else {
                        Write-Host "Device not found in SCCM: $DeviceName`n" -ForegroundColor Magenta
                        $ErrorCount++
                    }
                } catch {
                    Write-Host "Failed to process device '$DeviceName': $($_.Exception.Message)`n" -ForegroundColor Red
                    $ErrorCount++
                }
            }
        } catch {
            Write-Host "Failed: $($_.Exception.Message)" -ForegroundColor Red
            throw
        }
    }

    end {
        # Display operation summary with success and error counts
        Write-Host "Operation completed. Successfully added: $SuccessCount devices, Errors: $ErrorCount devices" -ForegroundColor Cyan
    }
}
