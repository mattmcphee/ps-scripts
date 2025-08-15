function Get-OSDRunUpOffline {
    [CmdletBinding()]
    param (
        # ComputerName
        [Parameter(Mandatory)]
        [string[]]
        $ComputerName
    )

    begin {
        Write-Host "`nWARNING: This cmdlet can take a long time, especially when specifying multiple computers!`n" -ForegroundColor DarkRed
        $initialWorkingDirectory = Get-Location
        $results = @()
        try {
            Import-MEMModule -SiteCode "A00"
        } catch {
            "Error: $_"
            exit
        }

        #region Functions
        function Get-SCCMWmiQueryResult {
            [CmdletBinding()]
            param (
                # ComputerName
                [Parameter(Mandatory)]
                [string]
                $ComputerName,
                # Class - wmi class to use in the query
                [Parameter(Mandatory)]
                [string]
                $Class
            )

            $sccmComputerName = "bnesccm01"
            $sccmWmiNamespace = "root\SMS\site_A00"
            $resId = (Get-CMDevice -Name $ComputerName -Fast).ResourceID

            Get-WmiObject -ComputerName $sccmComputerName `
                -Namespace $sccmWmiNamespace `
                -Class $Class |
                Where-Object { $_.ResourceID -eq $resId } |
                Select-Object -First 1
        }

        function Convert-WmiDateTime {
            param (
                # WmiDateTime string
                [Parameter(Mandatory)]
                [string]
                $WmiDateTime
            )
            # 20250402133057.000000+***
            $dotIndex = $WmiDateTime.IndexOf(".")
            $WmiDateTime = $WmiDateTime.Substring(0, $dotIndex)
            $year = $WmiDateTime.Substring(0, 4)
            $month = $WmiDateTime.Substring(4, 2)
            $day = $WmiDateTime.Substring(6, 2)
            $hour = $WmiDateTime.Substring(8, 2)
            $minute = $WmiDateTime.Substring(10, 2)
            $second = $WmiDateTime.Substring(12, 2)

            return "$year/$month/$day $($hour):$($minute):$($second)"
        }
    }

    process {
        Write-Host
        Write-Host "Gathering facts about these computers:"
        foreach ($computer in $ComputerName) {
            Write-Host $computer
        }
        Write-Host

        foreach ($computer in $ComputerName) {
            Write-Verbose "***$computer***"
            $cmDevice = Get-CMDevice -Name $computer -Fast

            # use helper function to retrieve wmi data from sccm database
            Write-Verbose "Querying the SMS_G_System_PC_BIOS class... "
            $wmiPcBios = Get-SCCMWmiQueryResult -ComputerName $computer -Class "SMS_G_System_PC_BIOS"
            Write-Verbose "Completed."

            Write-Verbose "Querying the SMS_G_System_COMPUTER_SYSTEM class... "
            $wmiComputerSystem = Get-SCCMWmiQueryResult -ComputerName $computer -Class "SMS_G_System_COMPUTER_SYSTEM"
            Write-Verbose "Completed."

            Write-Verbose "Querying the SMS_G_System_OPERATING_SYSTEM class... "
            $wmiOperatingSystem = Get-SCCMWmiQueryResult -ComputerName $computer -Class "SMS_G_System_OPERATING_SYSTEM"
            Write-Verbose "Completed."

            Write-Verbose "Querying the SMS_G_System_ENCRYPTABLE_VOLUME class... "
            $wmiBitLocker = Get-SCCMWmiQueryResult -ComputerName $computer -Class "SMS_G_System_ENCRYPTABLE_VOLUME"
            Write-Verbose "Completed."

            Write-Verbose "Querying the SMS_G_System_TPM class... "
            $wmiSecureBoot = Get-SCCMWmiQueryResult -ComputerName $computer -Class "SMS_G_System_TPM"
            Write-Verbose "Completed."

            Write-Verbose "Querying the SMS_R_System class... "
            $wmiRSystem = Get-SCCMWmiQueryResult -ComputerName $computer -Class "SMS_R_System"
            Write-Verbose "Completed."
            Write-Host

            # make bitlocker status more descriptive
            switch ($wmiBitLocker.ProtectionStatus) {
                0 { $blStatus = "Off" }
                1 { $blStatus = "On" }
                default { $blStatus = "Unknown" }
            }

            # make secureboot status more descriptive
            switch ($wmiSecureBoot.IsEnabled_InitialValue) {
                0 { $secureBootStatus = "Disabled" }
                1 { $secureBootStatus = "Enabled" }
                default { $secureBootStatus = "Unknown" }
            }

            # add all gathered info into a big ol' object ball
            $results += [PSCustomObject]@{
                "ComputerName"               = $wmiComputerSystem.Name
                "Model"                      = $wmiComputerSystem.Model
                "PrimaryUser"                = $cmDevice.PrimaryUser
                "CurrentlyLoggedOnUser"      = $cmDevice.CurrentLogOnUser
                "LastLogonUserName"          = $wmiRSystem.LastLogonUserName
                "LastActiveTime"             = $cmDevice.LastActiveTime
                "LastKnownIPAddresses"       = $wmiRSystem.IPAddresses
                "MACAddresses"               = $wmiRSystem.MACAddresses
                "OperatingSystemInstallDate" = Convert-WmiDateTime $wmiOperatingSystem.InstallDate
                "CreationDate"               = Convert-WmiDateTime $wmiRSystem.CreationDate
                "SCCMClientVersion"          = $cmDevice.ClientVersion
                "BIOSVersion"                = $wmiPcBios.BIOSVersion
                "BIOSName"                   = $wmiPcBios.Name
                "OperatingSystemVersion"     = $wmiOperatingSystem.Version
                "BitLockerProtectionStatus"  = $blStatus
                "SecureBootStatus"           = $secureBootStatus
                "SID"                        = $wmiRSystem.SID
                "SMBIOSGUID"                 = $wmiRSystem.SMBIOSGUID
                "AADDeviceID"                = $wmiRSystem.AADDeviceID
                "SerialNumber"               = $wmiComputerSystem.Name
                "ResourceID"                 = $cmDevice.ResourceID
            }
        }
    }

    end {
        Set-Location $initialWorkingDirectory

        return $results
    }
}
