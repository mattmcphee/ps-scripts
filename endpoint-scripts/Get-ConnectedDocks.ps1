function Get-ConnectedDocks {
    param (
        # ComputerName
        [Parameter(Mandatory=$true)]
        [string]
        $ComputerName
    )
    
    $pnpSignedDrivers = Get-CimInstance `
                            -ClassName Win32_PnPSignedDriver `
                            -ComputerName $ComputerName
    $connectedDocks = @()
    
    foreach ($driver in $pnpSignedDrivers) {
        $installedDeviceID = "$($driver.DeviceID)"

        if ( ($installedDeviceID -match "HID\\VID_03F0") -or `
        ($installedDeviceID -match "USB\\VID_17E9") ) {
            switch -Wildcard ( $installedDeviceID ) {
                '*PID_0488*' { $connectedDocks += 'HP Thunderbolt Dock G4' }
                '*PID_0667*' { $connectedDocks += 'HP Thunderbolt Dock G2' }
                '*PID_484A*' { $connectedDocks += 'HP USB-C Dock G4' }
                '*PID_046B*' { $connectedDocks += 'HP USB-C Dock G5' }
                '*PID_600A*' { $connectedDocks += 'HP USB-C Universal Dock' }
                '*PID_0A6B*' { $connectedDocks += 'HP USB-C Universal Dock G2' }
                '*PID_056D*' { $connectedDocks += 'HP E24d G4 FHD Docking Monitor' }
                '*PID_016E*' { $connectedDocks += 'HP E27d G4 QHD Docking Monitor' }
                '*PID_379D*' { $connectedDocks += 'HP USB-C G5 Essential Dock' }
            } #switch
        } #if
    } #foreach

    $connectedDocks
} #function