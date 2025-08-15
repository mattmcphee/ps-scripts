function Remove-DevicesFromCollection {
    [CmdletBinding(DefaultParameterSetName = 'ByName')]
    param(
        [Parameter(Mandatory = $true, ValueFromPipeline, ParameterSetName = 'ByName')]
        [string[]]$ComputerName,

        [Parameter(Mandatory = $true)]
        [string]$CollectionName,

        [Parameter(Mandatory = $false, ParameterSetName = 'Interactive')]
        [switch]$Interactive
    )

    begin {
        Import-MEMModule A00

        # Initialize counters for tracking operation results
        $SuccessCount = 0
        $ErrorCount = 0
    }

    process {
        if ($Interactive) {
            Write-Host "Getting devices from collection '$CollectionName'..." -ForegroundColor Cyan

            try {
                # Get all devices in the collection
                $CollectionDevices = Get-CMCollectionMember -CollectionName $CollectionName -ErrorAction Stop

                if ($CollectionDevices) {
                    # Create objects for grid view with relevant information
                    $GridViewData = $CollectionDevices | Select-Object Name,
                    @{Name='LastLogonUser'; Expression= { $_.LastLogonUserName } },
                    @{Name='LastActiveTime'; Expression= { $_.LastActiveTime } },
                    @{Name='OperatingSystem'; Expression= { $_.DeviceOS } },
                    ResourceID

                    # Show grid view for device selection
                    $SelectedDevices = $GridViewData | Out-GridView -Title "Select devices to remove from collection '$CollectionName'" -PassThru

                    if ($SelectedDevices) {
                        Write-Host "Starting to remove $($SelectedDevices.Count) selected devices from collection '$CollectionName'" -ForegroundColor Yellow

                        # Process selected devices
                        foreach ($Device in $SelectedDevices) {
                            try {
                                Write-Host "Processing device: $($Device.Name)"

                                # Remove the device from the collection using ResourceID
                                Remove-CMDeviceCollectionDirectMembershipRule -CollectionName $CollectionName -ResourceId $Device.ResourceID -Force -ErrorAction Stop
                                Write-Host "Successfully removed $($Device.Name) from collection`n" -ForegroundColor Green
                                $SuccessCount++
                            } catch {
                                Write-Host "Failed to remove $($Device.Name) from collection: $($_.Exception.Message)`n" -ForegroundColor Red
                                $ErrorCount++
                            }
                        }
                    } else {
                        Write-Host "No devices selected for removal." -ForegroundColor Yellow
                    }
                } else {
                    Write-Host "No devices found in collection '$CollectionName'" -ForegroundColor Yellow
                }
            } catch {
                Write-Host "Failed to get collection members: $($_.Exception.Message)" -ForegroundColor Red
                throw
            }
        } else {
            Write-Host "Starting to remove devices from '$ComputerName' from collection '$CollectionName'"

            try {
                # Process each device name individually (original functionality)
                foreach ($DeviceName in $ComputerName) {
                    try {
                        Write-Host "Processing device: $DeviceName"

                        # Query SCCM for the device using its name
                        $Device = Get-CMDevice -Name $DeviceName -ErrorAction Stop

                        if ($Device) {
                            # Remove the device from the specified collection using direct membership rule
                            try {
                                Remove-CMDeviceCollectionDirectMembershipRule -CollectionName $CollectionName -ResourceId $Device.ResourceID -Force -ErrorAction Stop
                                Write-Host "Successfully removed $DeviceName from collection`n" -ForegroundColor Green
                                $SuccessCount++
                            } catch {
                                Write-Host "Failed to remove $DeviceName from collection: $($_.Exception.Message)`n" -ForegroundColor Red
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
    }

    end {
        # Display operation summary with success and error counts
        Write-Host "Operation completed. Successfully removed: $SuccessCount devices, Errors: $ErrorCount devices" -ForegroundColor Cyan
    }
}
