# --- Configuration ---
$sccmSiteCode = 'A00'
$sccmSiteServer = 'BNESCCM01.bmd.com.au'

# Replace 'YOUR_TARGET_MACHINE_NAME' with the actual computer name you want to query.
# Leave as '*' to get BIOS info for all devices in SCCM (this can be a lot of data!)
$TargetMachineName = '1CZ01405Q4'
# --- End Configuration ---

Write-Host "Attempting to retrieve BIOS information for machine(s): '$TargetMachineName'..."

# Construct the WMI namespace for the SCCM site
$Namespace = "root\SMS\site_$($sccmSiteCode)"

try {
    # Query the SMS_G_System_PC_BIOS WMI class
    # We need to first get the ResourceID of the device(s)
    $Devices = Get-CMDevice -Name $TargetMachineName -ErrorAction Stop

    if ($Devices) {
        $BiosInfo = @()
        foreach ($Device in $Devices) {
            Write-Host "  Querying BIOS for '$($Device.Name)' (Resource ID: $($Device.ResourceID))..."
            $DeviceBios = Get-WmiObject -ComputerName $sccmSiteServer `
                                        -Namespace $Namespace `
                                        -Class SMS_G_System_PC_BIOS `
                                        -Filter "ResourceID = $($Device.ResourceID)" `
                                        -ErrorAction SilentlyContinue

            if ($DeviceBios) {
                # Select specific properties for clarity
                $BiosInfo += [PSCustomObject]@{
                    ComputerName = $Device.Name
                    SMBIOSBIOSVersion = $DeviceBios.SMBIOSBIOSVersion # The main BIOS version string
                    BIOSVersion = $DeviceBios.Version              # Often similar to SMBIOSBIOSVersion
                    Manufacturer = $DeviceBios.Manufacturer
                    ReleaseDate = $DeviceBios.ReleaseDate
                    SerialNumber = $DeviceBios.SerialNumber
                    Caption = $DeviceBios.Caption
                }
            } else {
                Write-Warning "  No BIOS inventory found for '$($Device.Name)'. Ensure hardware inventory is running and includes PC BIOS class."
            }
        }

        if ($BiosInfo.Count -gt 0) {
            Write-Host "`n--- BIOS Information ---"
            $BiosInfo | Format-Table -AutoSize
            # Optional: Export to CSV
            # $BiosInfo | Export-Csv "C:\Temp\SCCM_BIOS_Info.csv" -NoTypeInformation
            # Write-Host "`nBIOS information exported to C:\Temp\SCCM_BIOS_Info.csv"
        } else {
            Write-Host "`nNo BIOS information retrieved for the specified machine(s)."
        }
    } else {
        Write-Warning "No devices found matching '$TargetMachineName' in Configuration Manager."
    }
} catch {
    Write-Error "An error occurred during WMI query: $($_.Exception.Message)"
}
