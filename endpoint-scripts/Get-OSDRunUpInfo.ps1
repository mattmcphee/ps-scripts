
function Get-OSDRunUpInfo {
    <#
    .SYNOPSIS
	    Retrieves information from a list of computers about their OSD run up status, installed software, and driver errors.
    .Description
	    From a list of supplied computer names, it will connect remotely and check for the status of certain features and also check to see if OSD software was installed. It will the display results to screen, or outgrid or save them to a csv.
	    It can get the computer names from user input, SCCM Collection, a file, or scan a certain subnet. Results displayed in red mean they are wrong or missing and results displayed in magenta mean there is a newer version available, anything
        in green is a-ok
    .PARAMETER InputPC
        This will take input in the form of a computer name, Once enabled you must enter a computer name or an array of names.
	    If enabled -ComputerName is required.
    .PARAMETER InputCollection
		This will take input in the form of a SCCM Collection, it will then get all machines in that collection and run.
		If enabled -$CollectionName is required.
	.PARAMETER InputFile
		This will take input in the form of a path to a file containing computer names
		If enabled -FilePath is required
	.PARAMETER AutoSearch
		If enabled it will ping the 10.97.152.XXX Network and run against active ip's
		It pings every address so it can take a few minutes
	.PARAMETER OutGrid
		If enabled it will display the results to a powershell outgrid view
	.PARAMETER OutCsv
		If enabled it will save the results to your desktop in a .csv format.
		File name is CheckOSDRunup-date-Results date is the day it was run on
    .Notes
        Version:        1.01
        Auther:         Victor Rodriguez
        Creation Date:  08/09/2021
        Changes:        Initial script development
                        30-06-2022 Victor Rodriguez: Modified office check, now handled the shared licence versions
                        01-07-2022 Victor Rodriguez: Slimed down the parameters and update example and parameter information, Removed edge from software results, Changed 7-Zip to version 22
                        13/07/2022 Victor Rodriguez: Reversed outscreen, now its OutScreenOff and will prevent the results from being displayed in the cli
                        28/06/2024 Victor Rodriguez: Updated the software checks
                        04/12/2024 Jared Haigh:      Updated software application versions
    .EXAMPLE
        Get results from 1 user specified pc (pcOne) and output csv file
        PS> Get-OSDRunUpInfo -ComputerName "pcOne" -OutCsv
    .EXAMPLE
        Get results from multiple user specified pc (pcOne, pcTwo, pcThree) and output to Screen, out-grid-view and csv file
        PS> Get-OSDRunUpInfo -ComputerName "pcOne", "pcTwo", "pcThree" -OutGrids -OutCsv
    .EXAMPLE
        Get results from computers in a SCCM collection (HP Compaq 8100 Elite) and save to csv.
        PS> Get-OSDRunUpInfo  -CollectionName "HPCompaq8100Elite" -OutCsv
    .EXAMPLE
        Get results from computer stored in a txt file and display to out-grid-view
        PS> Get-OSDRunUpInfo -FilePath "C:\VR-BMD\computerNameList.txt"-OutGrids
    .EXAMPLE
        Get results from computer on the run up network and displays to out-grid-view and save as csv but also stops display to cli
        PS> Get-OSDRunUpInfo -AutoSearch -OutScreenOff -OutGrids -OutCsv
    .EXAMPLE
        Disables the output Information from being displayed in the CLI
        PS> Get-OSDRunUpInfo -ComputerName "pcOne" -OutScreenOff
    .EXAMPLE
        Results will be displayed in Out Grid-View
        PS> Get-OSDRunUpInfo -ComputerName "pcOne" -OutGrids
    .EXAMPLE
        Will export information to a csv named CheckOSDRunup-Date-Results.csv on the users desktop
        PS> Get-OSDRunUpInfo -ComputerName "pcOne" -OutCsv
    .EXAMPLE
        Include the computer name in each row of the output hany for out-grid-view and save as csv
        PS> Get-OSDRunUpInfo -AutoSearch -Sortable -OutGrids -OutCsv

    #>
    [CmdletBinding(DefaultParameterSetName = "ByComputerName")]
    param(
        # ComputerName - the name of a computer
        [Parameter(Mandatory = $true, ParameterSetName = "ByComputerName")]
        [string[]]
        $ComputerName,
        # CollectionName - the name of an sccm device collection
        [Parameter(Mandatory = $true, ParameterSetName = "ByCollectionName")]
        [string]
        $CollectionName,
        # FilePath - path to a file containing a list of computer names
        [Parameter(Mandatory = $true, ParameterSetName = "ByFilePath")]
        [string]
        $FilePath,
        # AutoSearch - will search the runup subnet for reachable machines
        [Parameter(Mandatory = $true, ParameterSetName = "ByAutoSearch")]
        [switch]
        $AutoSearch,
        # OutGrid - will output to powershell grid format if present
        [Parameter(Mandatory = $false)]
        [switch]
        $OutGrid,
        # CsvPath - will output to a csv file if present
        [Parameter(Mandatory = $false)]
        [string]
        $CsvPath
    )

    begin {
        Import-MEMModule A00
        $initialWorkingDirectory = Get-Location

        #region Search-RunUpSubnet
        function Search-RunUpSubnet {
            $computerNameList = @()

            Write-Host "Scanning 10.97.152.# subnet for reachable machines..." -ForegroundColor Yellow

            1..254 | ForEach-Object {
                if (Test-Connection -ComputerName "10.97.152.$_" -Count 1 -Quiet -ErrorAction "SilentlyContinue") {
                    $ipAddress = "10.97.152.$_"
                    $hostPCName = [System.Net.Dns]::GetHostByAddress($ipAddress).Hostname
                    $computerNameList += $hostPCName
                }
            }

            # exclude the machines we don't want to check
            $computerNameList = $computerNameList | Where-Object { $_ -notmatch 'TASK|win10|win11|jamesc' }

            # trim off the bmd.com.au from the hostname
            $computerNameList = $computerNameList.Trim(".bmd.com.au")

            return $computerNameList
        }

        #region Get-PCInfo
        function Get-PCInfo {
            # computer info
            $pcInfoResults = @()
            try {
                $computerInfo = Get-ComputerInfo -ErrorAction Stop
                $pcInfoResults += "Bios Model: " + $computerInfo.CsModel
                $pcInfoResults += "Bios Serial Number: " + $computerInfo.BiosSeralNumber
                $pcInfoResults += "Bios Version: " + $computerInfo.BiosSMBIOSBIOSVersion
                $pcInfoResults += "Operating System SKU: " + $computerInfo.OsOperatingSystemSKU
                $pcInfoResults += "Operating System Version: " + $computerInfo.OsVersion
                $pcInfoResults += "Operating System Windows Version: " + $computerInfo.WindowsVersion
                $pcInfoResults += "Operating System Install Date: " + $computerInfo.OsInstallDate
            }
            catch {
                pcInfoResults = "An error occurred when running Get-ComputerInfo."
            }

            # bitlocker info
            try {
                $bitLockerStatus = Get-BitLockerVolume -MountPoint "C:" -ErrorAction Stop
                $pcInfoResults += $bitLockerStatus
            }
            catch {
                $pcInfoResults += "An error occurred when running Get-BitLockerVolume. This machine may not have BitLocker!"
            }

            # secureboot status
            try {
                $isSecureBootEnabled = Confirm-SecureBootUEFI -ErrorAction Stop
                if ($isSecureBootEnabled) {
                    $pcInfoResults += "Secure Boot Status: On"
                }
                else {
                    $pcInfoResults += "Secure Boot Status: Off"
                }
            }
            catch {
                $pcInfoResults += "An error occurred when running Confirm-SecureBootUEFI."
            }

            # computer certificate info
            $certInfo = Get-ChildItem -Path 'Cert:\LocalMachine\My' |
            Where-Object { $_.Subject -like "*$env:COMPUTERNAME*" }
            $pcInfoResults += "Cert: " + $certInfo.Subject
            $pcInfoResults += "Cert Validity Range: " + $certInfo.NotBefore + "to" + $certInfo.NotAfter

            # runup ts
            $osTaskSequence = Get-ItemProperty -Path "HKLM:\Software\BMD\CCMEXEC"
            $pcInfoResults += "RunUp TS: " + $osTaskSequence.'Task Sequence Name'
            $pcInfoResults += "Version: " + $osTaskSequence.'Task Sequence version'
            $pcInfoResults += "Date Installed: " + $osTaskSequence.'Installed Date'
            $pcInfoResults += "Media Type: " + $osTaskSequence.'Media Type'

            # Dynamic Driver TS
            try {
                $dynamicDriverTS = Get-ItemProperty -Path "HKLM:\Software\BMD\CCMEXEC_DRIVER" -ErrorAction Stop
                $pcInfoResults += "Dynamic Driver: " + $dynamicDriverTS.'Task Sequence Name'
                $pcInfoResults += "Date: " + $dynamicDriverTS.'Installed Date'
            }
            catch {
                $pcInfoResults += "CCMEXEC_DRIVER registry key not found."
                $pcInfoResults += "The Dynamic Driver task sequence has not run on this machine."
            }

            return $pcInfoResults
        }

        #region Get-InstalledApps
        function Get-InstalledApps {
            [CmdletBinding()]
            param(
                # ComputerName
                [Parameter(Mandatory = $false)]
                [string]
                $ComputerName,
                # ApplicationName
                [Parameter(Mandatory = $false)]
                [string]
                $ApplicationName
            )

            $getAppsScriptBlock = {
                $apps = @()

                $x64Apps = Get-ItemProperty "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall\*" |
                Select-Object *, @{ n = "RegistryKey"; e = { $_.PSPath.Substring(36) } }
                $apps += $x64Apps

                $x86Apps = Get-ItemProperty "HKLM:\SOFTWARE\Wow6432Node\Microsoft\Windows\CurrentVersion\Uninstall\*" |
                Select-Object *, @{ n = "RegistryKey"; e = { $_.PSPath.Substring(36) } }
                $apps += $x86Apps

                $officeRegistryKey = "SOFTWARE\Microsoft\Office\ClickToRun\Configuration"
                $officeVersion = (Get-ItemProperty -Path "HKLM:\$officeRegistryKey" | Select-Object VersionToReport).VersionToReport.Substring(5)
                $apps += [PSCustomObject]@{
                    "DisplayName"    = "Microsoft Office 365 Apps for Enterprise"
                    "DisplayVersion" = $officeVersion
                    "RegistryKey"    = "HKEY_LOCAL_MACHINE\$officeRegistryKey"
                }

                $bginfoRegistryKey = "SOFTWARE\BMD\BGInfo"
                $bginfoProps = Get-ItemProperty -Path "HKLM:\$bginfoRegistryKey"
                $apps += [PSCustomObject]@{
                    "DisplayName"    = $bginfoProps.PSChildName
                    "DisplayVersion" = $bginfoProps.Version
                    "RegistryKey"    = "HKEY_LOCAL_MACHINE\$bginfoRegistryKey"
                }

                $selectProperties = @(
                    'DisplayName',
                    'DisplayVersion',
                    'InstallLocation',
                    'UninstallString',
                    'QuietUninstallString',
                    'RegistryKey'
                )

                return $apps | Select-Object $selectProperties
            }

            if ($ComputerName) {
                $apps = Invoke-Command -ComputerName $ComputerName -ScriptBlock $getAppsScriptBlock
            }
            else {
                $apps = & $getAppsScriptBlock
            }

            if ($ApplicationName) {
                return $apps | Where-Object { $_.DisplayName -like $ApplicationName } | Sort-Object DisplayName
            }
            else {
                return $apps | Sort-Object DisplayName
            }
        }

        #region Get-InstalledSoftware
        function Get-InstalledSoftware {
            # I wasn't able to work out how to pull the currently installed software on a machine from
            # configuration manager so this function will only work if the machine is online

            # get the last created production task sequence
            $taskSequence = Get-CMTaskSequence -Fast | Where-Object {
                ($_.Description -eq "Production") -and ($_.Type -eq "2")
            } | Sort-Object -Property "SourceDate" -Descending | Select-Object -First 1

            # get the task sequence in xml format but we're going to keep it
            # as a string so we can do some regex to pull out the ts app info
            [string]$taskSequenceXml = (Get-CMTaskSequence -Name $taskSequence.Name).Sequence

            # find app details using regex and add it to an array of objects
            $tsApps = @()
            $pattern = 'property="AppInfo\d+DisplayName">([^<>]*)<\/variable><[^<>]*>([^<>]+)</variable>'
            $tsAppMatches = ($taskSequenceXml | Select-String -Pattern $pattern -AllMatches -CaseSensitive).Matches

            foreach ($tsAppMatch in $tsAppMatches) {
                $tsAppName = ($tsAppMatch.Groups | Where-Object { $_.Name -eq 1 } | Select-Object Value).Value
                $tsAppModelName = ($tsAppMatch.Groups | Where-Object { $_.Name -eq 2 } | Select-Object Value).Value
                $tsApps += [PSCustomObject]@{
                    "Name"      = $tsAppName
                    "ModelName" = $tsAppModelName
                }
            }

            # go through each app and retrieve the softwareversion using get-cmapplication
            # add the softwareversion as a new property on the $tsApp object
            foreach ($tsApp in $tsApps) {
                $cmApp = Get-CMApplication -Fast -ModelName $tsApp.ModelName
                $tsApp | Add-Member -MemberType NoteProperty -Name "SoftwareVersion" -Value $cmApp.SoftwareVersion
            }

            $tsApps | Select-Object Name, SoftwareVersion

            # now we have $tsApps which contains a list of objects with each object having a
            # name, modelname and version
            # the next step is to look in the registry on the machine for these apps
            $installedApps = Get-InstalledApps | Select-Object DisplayName, DisplayVersion
            $installedApps
        }

        #region Get-DriverErrors
        function Get-DriverErrors {
            $pnpErrors = Get-PnpDevice | Where-Object { $_.status -like "Error" }

            if ($null -ne $pnpErrors) {
                $pnpErrorList = @()
                foreach ($pnpError in $pnpErrors) {
                    $pnpErrorList += "Error: " + $pnpError.FriendlyName
                }
                return $pnpErrorList
            }
            else {
                return "No pnpErrors found."
            }
        }

        #region Get-SCCMWmiQueryResult
        function Get-SCCMWmiQueryResult {
            [CmdletBinding()]
            param (
                # ComputerName
                [Parameter(Mandatory)]
                [string[]]
                $ComputerName,
                # Class - wmi class to use in the query
                [Parameter(Mandatory)]
                [string]
                $Class
            )

            begin {
                $initialWorkingDirectory = Get-Location
                try {
                    Set-Location -Path "A00:"
                }
                catch {
                    Write-Host "Import the MEM Module using Import-MEMModule first!"
                    exit
                }
                $sccmComputerName = "bnesccm01"
                $sccmWmiNamespace = "root\SMS\site_A00"
            }

            process {
                foreach ($hostname in $ComputerName) {
                    $resId = (Get-CMDevice -Name $hostname -Fast).ResourceID
                    Get-WmiObject -ComputerName $sccmComputerName `
                        -Namespace $sccmWmiNamespace `
                        -Class $Class |
                    Where-Object { $_.ResourceID -eq $resId } |
                    Select-Object -First 1
                }
            }

            end {
                Set-Location $initialWorkingDirectory
            }
        }
    }

    process {
        $computerNameList = @()
        $osdRunUpResults = @()

        if ($ByComputerName) {
            if ($null -eq $ComputerName) {
                $computerNameList = Read-Host -Prompt 'Input your computer name(s)'
            }
            else {
                $computerNameList = $ComputerName
                Write-Host "Input PC selected, PC: $computerNameList"
            }
        }

        if ($ByCollectionName) {
            Write-Host "Input Collection selected, Collection name = $CollectionName"
            Set-Location A00:

            #Get collection and sort
            $CMCollectionMember = Get-CMCollectionMember -CollectionName $CollectionName
            [int]$CMCollectionMemberCount = $CMCollectionMember.Count

            Write-Host "Found $CMCollectionMemberCount in collection: $CollectionName `n`n"

            $computerNameList = $CMCollectionMember.Name
            Set-Location -Path $initialWorkingDirectory
        }

        if ($ByFilePath) {
            $computerNameList = Get-Content -Path $FilePath
            Write-Host "Working with $FilePath"
            Write-Host "Found these machines in $FilePath : $computerNameList"
        }

        if ($ByAutoSearch) {
            $computerNameList = Search-RunUpSubnet
        }

        $osdRunUpResults = @()

        foreach ($computer in $computerNameList) {
            #Test online status
            if (Test-Connection -Delay 1 -ComputerName $computer -Count 1 -ErrorAction SilentlyContinue) {
                Invoke-Command -ComputerName $computer -ScriptBlock ${Function:\Get-PCInfo} -ErrorAction Stop
                Invoke-Command -ComputerName $computer -ScriptBlock ${Function:\Get-InstalledSoftware} -ErrorAction Stop
                Invoke-Command -ComputerName $computer -ScriptBlock ${Function:\Get-DriverErrors} -ErrorAction Stop
            }
        }

        if ($machineOffline) {
            $computer = "5CD42935LM"
            $wmiPcBios = Get-SCCMWmiQueryResult -ComputerName $computer -Class "SMS_G_SYSTEM_PC_BIOS"
            $wmiComputerSystem = Get-SCCMWmiQueryResult -ComputerName $computer -Class "SMS_G_SYSTEM_COMPUTER_SYSTEM"

        }

        if ($OutGrid) {
            $osdRunUpResults | Out-GridView
        }

        if ($OutCsv) {
            $osdRunUpResults | Export-Csv -path $CsvPath -NoTypeInformation
        }
    }

    end {
        Pop-Location
    }
}
