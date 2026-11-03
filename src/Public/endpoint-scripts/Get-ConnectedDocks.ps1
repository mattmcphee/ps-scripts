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

    foreach ($driver in $pnpSignedDrivers) {
        $installedDeviceID = "$($driver.DeviceID)"

        if ( ($installedDeviceID -match "HID\\VID_03F0") -or `
        ($installedDeviceID -match "USB\\VID_17E9") ) {
            switch -Wildcard ( $installedDeviceID ) {
                '*PID_0488*' { return 'HP Thunderbolt Dock G4' }
                '*PID_0667*' { return 'HP Thunderbolt Dock G2' }
                '*PID_484A*' { return 'HP USB-C Dock G4' }
                '*PID_046B*' { return 'HP USB-C Dock G5' }
                '*PID_600A*' { return 'HP USB-C Universal Dock' }
                '*PID_0A6B*' { return 'HP USB-C Universal Dock G2' }
                '*PID_056D*' { return 'HP E24d G4 FHD Docking Monitor' }
                '*PID_016E*' { return 'HP E27d G4 QHD Docking Monitor' }
                '*PID_379D*' { return 'HP USB-C G5 Essential Dock' }
                '*PID_04B7*' { return 'HP USB-C 100W G6 Dock' }
            }
        }
    }
}
