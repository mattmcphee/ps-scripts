<#
.SYNOPSIS
    Uninstall software based on the DisplayName of said software in the registry
.DESCRIPTION
    This script is useful if you need to uninstall software before installing or updating other software. 

    Typically best used as a pre-script in most situations.

    One example use case of this script with Patch My PC's Publisher is if you have previously re-packaged software installed
    on your devices and you need to uninstall the repackaged software, and install using the vendor's native install media 
    (provided by the Patch My PC catalogue).

    The script searches the registry for installed software, matching the supplied DisplayName value in the -DisplayName parameter
    with that of the DisplayName in the registry. If one match is found, it uninstalls the software using the QuietUninstallString or UninstallString.
    
    You can supply additional arguments to the uninstaller using the -AdditionalArguments, -AdditionalMSIArguments, or -AdditionalEXEArguments parameters.

    You cannot use -AdditionalArguments with -AdditionalMSIArguments or -AdditionalEXEArguments.

    If a product code is not in the UninstallString, QuietUninstallString or UninstallString are used. QuietUninstallString is preferred if it exists.

    If more than one matches of the DisplayName occurs, uninstall is not possible unless you use the -UninstallAll switch.

    If QuietUninstallString and UninstallString is not present or null, uninstall is not possible.

    A log file is created in the temp directory with the name "Uninstall-Software-<DisplayName>.log" which contains the verbose output of the script.

    An .msi log file is created in the temp directory with the name "<DisplayName>_<DisplayVersion>.msi.log" which contains the verbose output of the msiexec.exe process.
.PARAMETER DisplayName
    The name of the software you wish to uninstall as it appears in the registry as its DisplayName value. * wildcard supported.
.PARAMETER Architecture
    Choose which registry key path to search in while looking for installed software. Acceptable values are:

    - "x86" will search in SOFTWARE\WOW6432Node\Microsoft\Windows\CurrentVersion\Uninstall on a 64-bit system.
    - "x64" will search in SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall.
    - "Both" will search in both key paths.
.PARAMETER HivesToSearch
    Choose which registry hive to search in while looking for installed software. Acceptable values are:

    - "HKLM" will search in hive HKEY_LOCAL_MACHINE which is typically where system-wide installed software is registered.
    - "HKCU" will search in hive HKEY_CURRENT_USER which is typically where user-based installed software is registered.
.PARAMETER WindowsInstaller
    Specify a value between 1 and 0 to use as an additional criteria when trying to find installed software.

    If WindowsInstaller registry value has a data of 1, it generally means software was installed from MSI.

    Omitting the parameter entirely or specify a value of 0 generally means software was installed from EXE

    This is useful to be more specific about software titles you want to uninstall.

    Specifying a value of 0 will look for software where WindowsInstaller is equal to 0, or not present at all.
.PARAMETER SystemComponent
    Specify a value between 1 and 0 to use as an additional criteria when trying to find installed software.

    Specifying a value of 0 will look for software where SystemComponent is equal to 0, or not present at all.
.PARAMETER VersionLessThan
    Specify a version number to use as an additional criteria when trying to find installed software.

    This parameter can be used in conjuction with -VersionEqualTo and -VersionGreaterThan.
.PARAMETER VersionEqualTo
    Specify a version number to use as an additional criteria when trying to find installed software.

    This parameter can be used in conjuction with -VersionLessThan and -VersionGreaterThan.
.PARAMETER VersionGreaterThan
    Specify a version number to use as an additional criteria when trying to find installed software.

    This parameter can be used in conjuction with -VersionLessThan and -VersionEqualTo.
.PARAMETER EnforcedArguments
    A string which includes the arguments you would like passed to the uninstaller.

    Cannot be used with -AdditionalArguments, -AdditionalMSIArguments, or -AdditionalEXEArguments.

    This will not be used for .msi based software uninstalls.
.PARAMETER AdditionalArguments
    A string which includes the additional parameters you would like passed to the uninstaller.

    Cannot be used with -AdditionalMSIArguments or -AdditionalEXEArguments.
.PARAMETER AdditionalMSIArguments
    A string which includes the additional parameters you would like passed to the MSI uninstaller. 
    
    This is useful if you use this, and (or not at all) -AdditionalEXEArguments, in conjuction with -UninstallAll to apply different parameters for MSI based uninstalls.

    Cannot be used with -AdditionalArguments.
.PARAMETER AdditionalEXEArguments
    A string which includes the additional parameters you would like passed to the EXE uninstaller.

    This is useful if you use this, and (or not at all) -AdditionalMSIArguments, in conjuction with -UninstallAll to apply different parameters for EXE based uninstalls.

    Cannot be used with -AdditionalArguments.
.PARAMETER UninstallAll
    This switch will uninstall all software matching the search criteria of -DisplayName, -WindowsInstaller, and -SystemComponent.

    -DisplayName allows wildcards, and if there are multiple matches based on the wild card, this switch will uninstall matching software.

    Without this parameter, the script will do nothing if there are multiple matches found.
.PARAMETER Force
    This switch will instruct the script to attempt to uninstall an MSI even if it is not installed (either per-system or for the current user).
    This may produce a 1605 error code if the MSI is installed for another user, so this switch will also suppress this exit code.
.PARAMETER ProcessName
    Wait for this process to finish after the uninstallation has started.
    
    If the process is already running before the uninstallation has even started, the script will quit with an error.

    This is useful for some software which spawn a seperate process to do the uninstallation, and the main process exits before the uninstallation is finished.

    The .exe extension is not required, and the process name is case-insensitive.
.PARAMETER RemovePath
    Supply a list of files and folders to be removed after the uninstallations have been processed. Use with -Force if all items are to be removed even if there is no software found to be uninstalled or if errors are encountered during uninstallation.
.EXAMPLE
    PS C:\> Uninstall-Software.ps1 -DisplayName "Greenshot"
    
    Uninstalls Greenshot if "Greenshot" is detected as the DisplayName in a key under either of the registry key paths:

    - SOFTWARE\WOW6432Node\Microsoft\Windows\CurrentVersion\Uninstall
    - SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall 
.EXAMPLE
    PS C:\> Uninstall-Software.ps1 -DisplayName "Mozilla*"

    Uninstalls any products where DisplayName starts with "Mozilla"
.EXAMPLE
    PS C:\> Uninstall-Software.ps1 -DisplayName "*SomeSoftware*" -AdditionalMSIArguments "/quiet /norestart" -AdditionalEXEArguments "/S" -UninstallAll

    Uninstalls all software where DisplayName contains "SomeSoftware". 
    
    For any software found in the registry matching the search criteria and are MSI-based (WindowsInstaller = 1), "/quiet /norestart" will be supplied to the uninstaller.
    
    For any software found in the registry matching the search criteria and  are EXE-based (WindowsInstaller = 0 or non-existent), "/S" will be supplied to the uninstaller.
.EXAMPLE
    PS C:\> Uninstall-Software.ps1 -DisplayName "KiCad*" -ProcessName "Un_A"

    Uninstalls KiCad and waits for the process "Un_A" to finish after the uninstallation has started.
.EXAMPLE
    PS C:\> Uninstall-Software.ps1 -DisplayName "SomeSoftware" -VersionGreaterThan 1.0.0

    Uninstalls SomeSoftware if the version is greater than 1.0.0
.EXAMPLE
    PS C:\> Uninstall-Software.ps1 -DisplayName "AnyDesk" -EnforcedArguments "--remove --silent"

    Uninstalls AnyDesk with the enforced arguments "--remove --silent", instead of using the default parameters in the UninstallString.
#>
[CmdletBinding(DefaultParameterSetName = 'AdditionalArguments')]
param (
    [Parameter(Mandatory)]
    [String]$DisplayName,

    [Parameter()]
    [ValidateSet('Both', 'x86', 'x64')]
    [String]$Architecture = 'Both',

    [Parameter()]
    [ValidateSet('HKLM', 'HKCU')]
    [String[]]$HivesToSearch = 'HKLM',

    [Parameter()]
    [ValidateSet(1, 0)]
    [Int]$WindowsInstaller,

    [Parameter()]
    [ValidateSet(1, 0)]
    [Int]$SystemComponent,

    [Parameter()]
    [String]$VersionLessThan,

    [Parameter()]
    [String]$VersionEqualTo,

    [Parameter()]
    [String]$VersionGreaterThan,

    [Parameter(ParameterSetName = 'EnforcedArguments')]
    [String]$EnforcedArguments,

    [Parameter(ParameterSetName = 'AdditionalArguments')]
    [String]$AdditionalArguments,

    [Parameter(ParameterSetName = 'AdditionalEXEorMSIArguments')]
    [String]$AdditionalMSIArguments,
    
    [Parameter(ParameterSetName = 'AdditionalEXEorMSIArguments')]
    [String]$AdditionalEXEArguments,

    [Parameter()]
    [Switch]$UninstallAll,

    [Parameter()]
    [Switch]$Force,

    [Parameter()]
    [String]$ProcessName,

    [Parameter()]
    [String[]]$RemovePath
)

function Get-InstalledSoftware {
    param(
        [Parameter(Mandatory)]
        [String]$DisplayName,

        [Parameter()]
        [ValidateSet('Both', 'x86', 'x64')]
        [String]$Architecture = 'Both',

        [Parameter()]
        [ValidateSet('HKLM', 'HKCU')]
        [String[]]$HivesToSearch = 'HKLM',

        [Parameter()]
        [ValidateSet(1, 0)]
        [Int]$WindowsInstaller,
    
        [Parameter()]
        [ValidateSet(1, 0)]
        [Int]$SystemComponent,
    
        [Parameter()]
        [String]$VersionLessThan,
    
        [Parameter()]
        [String]$VersionEqualTo,
    
        [Parameter()]
        [String]$VersionGreaterThan
    )

    $PathsToSearch = if ([IntPtr]::Size -eq 4) {
        # IntPtr will be 4 on a 32 bit system, where there is only one place to look
        'Software\Microsoft\Windows\CurrentVersion\Uninstall\*'
    }
    else {
        switch -regex ($Architecture) {
            'Both|x86' {
                # If we are searching for a 32 bit application then we will only search under Wow6432Node
                'Software\Wow6432Node\Microsoft\Windows\CurrentVersion\Uninstall\*'
            }
            'Both|x64' {
                # If we are searching for a 64 bit application then we will only search the 64-bit registry
                'Software\Microsoft\Windows\CurrentVersion\Uninstall\*'
            }
        }
    }

    $FullPaths = foreach ($PathFragment in $PathsToSearch) {
        switch ($HivesToSearch) {
            'HKLM' {
                [string]::Format('registry::HKEY_LOCAL_MACHINE\{0}', $PathFragment)
            }
            'HKCU' {
                [string]::Format('registry::HKEY_CURRENT_USER\{0}', $PathFragment)
            }
        }
    }

    Write-Verbose "Will search the following registry paths based on [Architecture = $Architecture] [HivesToSearch = $HivesToSearch]"
    foreach ($RegPath in $FullPaths) {
        Write-Verbose $RegPath
    }

    $PropertyNames = 'DisplayName', 'DisplayVersion', 'PSChildName', 'Publisher', 'InstallDate', 'QuietUninstallString', 'UninstallString', 'WindowsInstaller', 'SystemComponent'

    $AllFoundObjects = Get-ItemProperty -Path $FullPaths -Name $propertyNames -ErrorAction SilentlyContinue

    foreach ($Result in $AllFoundObjects) {
        try {
            if ($Result.DisplayName -notlike $DisplayName) {
                #Write-Verbose ('Skipping {0} as name does not match {1}' -f $Result.DisplayName, $DisplayName)
                continue
            }
            # Casting to [bool] will return $false if the registry property is 0 or not present, and can also cast integers 0/1 to $false/$true.
            # Function accepts integers however, as supplying 1 for an expected bool works within powershell, but not on a powershell.exe command line.
            if ($PSBoundParameters.ContainsKey('WindowsInstaller') -and [bool]$Result.WindowsInstaller -ne [bool]$WindowsInstaller) {
                Write-Verbose ('Skipping {0} as WindowsInstaller value {1} does not match {2}' -f $Result.DisplayName, $Result.WindowsInstaller, $WindowsInstaller)
                continue
            }
            if ($PSBoundParameters.ContainsKey('SystemComponent') -and [bool]$Result.SystemComponent -ne [bool]$SystemComponent) {
                Write-Verbose ('Skipping {0} as SystemComponent value {1} does not match {2}' -f $Result.DisplayName, $Result.SystemComponent, $SystemComponent)
                continue
            }
            if ($PSBoundParameters.ContainsKey('VersionEqualTo') -and (ConvertTo-Version $Result.DisplayVersion) -ne (ConvertTo-Version $VersionEqualTo)) {
                Write-Verbose ('Skipping {0} as version {1} is not equal to {2}' -f $Result.DisplayName, $Result.DisplayVersion, $VersionEqualTo)
                continue
            }
            if ($PSBoundParameters.ContainsKey('VersionLessThan') -and (ConvertTo-Version $Result.DisplayVersion) -ge (ConvertTo-Version $VersionLessThan)) {
                Write-Verbose ('Skipping {0} as version {1} is not less than {2}' -f $Result.DisplayName, $Result.DisplayVersion, $VersionLessThan)
                continue
            }
            if ($PSBoundParameters.ContainsKey('VersionGreaterThan') -and (ConvertTo-Version $Result.DisplayVersion) -le (ConvertTo-Version $VersionGreaterThan)) {
                Write-Verbose ('Skipping {0} as version {1} is not greater than {2}' -f $Result.DisplayName, $Result.DisplayVersion, $VersionGreaterThan)
                continue
            }
            # If we get here, then all criteria have been met
            Write-Verbose ('Found matching application {0} {1}' -f $Result.DisplayName, $Result.DisplayVersion)
            $Result | Select-Object -Property $PropertyNames
        }
        catch {
            # ConvertTo-Version will throw an error if it can't convert the version string to a [version] object
            Write-Warning "Error processing $($Result.DisplayName): $_"
            continue
        }

    }
}

function ConvertTo-Version {
    param (
        [Parameter(ValueFromPipeline = $true, Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [String]$VersionString
    )

    #Delete any backslashes
    $FormattedVersion = $VersionString.Replace('\', '')

    #Replace build or _build with a .
    $FormattedVersion = $FormattedVersion -replace '(_|\s)build', '.'

    #Replace any underscore, dash. plus, or open bracket surrounded by digits with a .
    $FormattedVersion = $FormattedVersion -replace '(?<=\d)(_|-|\+|\()(?=\d)', '.'

    # If Version ends in a trailing ., delete it
    $FormattedVersion = $FormattedVersion -replace '\.$', ''

    # Delete anything that isn't a decimal or a dot
    $FormattedVersion = $FormattedVersion -replace '[^\d.]', ''

    # Delete any random instances of a-z followed by digits, such as b1, ac3, beta5
    $FormattedVersion = $FormattedVersion -replace '[a-z]+\d+', ''

    # Trim any version numbers with 5 or more parts down to 4
    $FormattedVersion = $FormattedVersion -replace '^((\d+\.){3}\d+).*', '$1'

    # Add a .0 to any single integers
    $FormattedVersion = $FormattedVersion -replace '^(\d+)$', '$1.0'

    # Pad the version number out to contain 4 parts before casting to [version]
    $PeriodCount = $FormattedVersion.ToCharArray().Where{ $_ -eq '.' }.Count
    switch ($PeriodCount) {
        1 { $PaddedVersion = $FormattedVersion + '.0.0' }    # One period, so it's a two-part version number
        2 { $PaddedVersion = $FormattedVersion + '.0' }      # Two periods, so it's a three-part version number
        default { $PaddedVersion = $FormattedVersion }
    }

    try {
        [System.Version]::Parse($PaddedVersion)
    }
    catch {
        throw "'$VersionString' was formatted to '$FormattedVersion' which failed to be cast as [System.Version]: $_"
    }

}

function Split-UninstallString {
    param(
        [Parameter(Mandatory)]
        [String]$UninstallString
    )

    if ($UninstallString.StartsWith('"')) {
        [Int]$EndOfFilePath = [String]::Join('', $UninstallString[1..$UninstallString.Length]).IndexOf('"')
        [String]$FilePath = [String]::Join('', $UninstallString[0..$EndOfFilePath]).Trim(' ', '"')

        [Int]$StartOfArguments = $EndOfFilePath + 2
        [String]$Arguments = [String]::Join('', $UninstallString[$StartOfArguments..$UninstallString.Length]).Trim()
    }
    else {
        for ($i = 0; $i -lt $UninstallString.Length - 3; $i++) {
            if ($UninstallString.Substring($i, 4) -eq '.exe') {
                # If the character after .exe is null or whitespace, then with reasoanbly high confidence we have found the end of the file path
                if ([String]::IsNullOrWhiteSpace($UninstallString[$i + 4])) {
                    $EndOfFilePath = $i + 4
                    break
                }
            }
        }

        $FilePath = [String]::Join('', $UninstallString[0..$EndOfFilePath]).Trim(' ', '"')
        $Arguments = [String]::Join('', $UninstallString[$EndOfFilePath..$UninstallString.Length]).Trim()
    }

    return $FilePath, $Arguments
}

function Get-ProductState {
    param(
        [Parameter(Mandatory)]
        [String]$ProductCode
    )

    # TODO: Query the registry, instead of WindowsInstaller COM object, to determine if the product is installed for the current user, so we can log the username who has the software installed

    $WindowsInstaller = New-Object -ComObject WindowsInstaller.Installer
    $ProductState = $WindowsInstaller.ProductState($ProductCode)
    [Runtime.Interopservices.Marshal]::ReleaseComObject($WindowsInstaller) | Out-Null

    return $ProductState
}

function Uninstall-Software {
    # Specifically written to take an input object made by Get-InstalledSoftware in this same script file
    [CmdletBinding()]
    param (
        [Parameter(Mandatory)]
        [PSCustomObject]$Software,

        [Parameter()]
        [String]$EnforcedArguments,

        [Parameter()]
        [String]$AdditionalArguments,

        [Parameter()]
        [String]$AdditionalMSIArguments,

        [Parameter()]
        [String]$AdditionalEXEArguments,

        [Parameter()]
        [String]$UninstallProcessName,

        [Parameter()]
        [Switch]$Force
    )

    Write-Verbose ('Found "{0}":' -f $Software.DisplayName)
    Write-Verbose ($Software | ConvertTo-Json)

    if ([String]::IsNullOrWhiteSpace($Software.UninstallString) -And [String]::IsNullOrWhiteSpace($Software.QuietUninstallString)) {
        Write-Verbose ('Can not uninstall software as UninstallString and QuietUninstallString are both empty for "{0}"' -f $Software.DisplayName)
    }
    else {
        $ProductCode = [Regex]::Match($Software.UninstallString, "^msiexec.+(\{.+\})", 'IgnoreCase').Groups[1].Value

        if ($ProductCode) { 

            $ProductState = Get-ProductState -ProductCode $ProductCode

            if ($ProductState -eq 5) {
                Write-Verbose ('Product code "{0}" is installed.' -f $ProductCode)
            }
            elseif ($ProductState -eq 1) {
                Write-Verbose ('Product code "{0}" is advertised.' -f $ProductCode)
            }
            else {
                if ($ProductState -eq 2) {
                    Write-Verbose ('Product code "{0}" is installed for another user.' -f $ProductCode)
                }
                else {
                    Write-Verbose ('Product code "{0}" is not installed.' -f $ProductCode)
                }

                if ($Force.IsPresent) {
                    Write-Verbose 'Uninstall will be attempted anyway as -Force was specfied.'
                }
                else {
                    Write-Verbose 'Will not attempt to uninstall.'
                    return
                }
            }

            $MsiLog = '{0}\{1}_{2}.msi.log' -f 
                $env:temp, 
                [String]::Join('', $Software.DisplayName.Replace(' ', '_').Split([System.IO.Path]::GetInvalidFileNameChars())), 
                [String]::Join('', $Software.DisplayVersion.Split([System.IO.Path]::GetInvalidFileNameChars()))

            $StartProcessSplat = @{
                FilePath     = 'msiexec.exe'
                ArgumentList = '/x', $ProductCode, '/qn', 'REBOOT=ReallySuppress', ('/l*v {0}' -f $MsiLog)
                Wait         = $true
                PassThru     = $true
                ErrorAction  = $ErrorActionPreference
            }

            if (-not [String]::IsNullOrWhiteSpace($AdditionalArguments)) {
                Write-Verbose ('Adding additional arguments "{0}" to uninstall string' -f $AdditionalArguments)
                $StartProcessSplat['ArgumentList'] = $StartProcessSplat['ArgumentList'] += $AdditionalArguments
            }
            elseif (-not [String]::IsNullOrWhiteSpace($AdditionalMSIArguments)) {
                Write-Verbose ('Adding additional MSI arguments "{0}" to uninstall string' -f $AdditionalMSIArguments)
                $StartProcessSplat['ArgumentList'] = $StartProcessSplat['ArgumentList'] += $AdditionalMSIArguments
            }

            $Message = 'Trying uninstall with "msiexec.exe {0}"' -f [String]$StartProcessSplat['ArgumentList']
        } 
        else { 
            Write-Verbose ('Could not parse product code from "{0}"' -f $Software.UninstallString)

            if (-not [String]::IsNullOrWhiteSpace($Software.QuietUninstallString)) {
                $UninstallString = $Software.QuietUninstallString
                Write-Verbose ('Found QuietUninstallString "{0}"' -f $Software.QuietUninstallString)
            }
            else {
                $UninstallString = $Software.UninstallString
                Write-Verbose ('Found UninstallString "{0}"' -f $Software.UninstallString)
            }

            $FilePath, $Arguments = Split-UninstallString $UninstallString

            $StartProcessSplat = @{
                FilePath    = $FilePath
                Wait        = $true
                PassThru    = $true
                ErrorAction = $ErrorActionPreference
            }

            if (-not [String]::IsNullOrWhiteSpace($AdditionalArguments)) {
                Write-Verbose ('Adding additional arguments "{0}" to UninstallString' -f $AdditionalArguments)
                $Arguments = "{0} {1}" -f $Arguments, $AdditionalArguments
            }
            elseif (-not [String]::IsNullOrWhiteSpace($AdditionalEXEArguments)) {
                Write-Verbose ('Adding additional EXE arguments "{0}" to UninstallString' -f $AdditionalEXEArguments)
                $Arguments = "{0} {1}" -f $Arguments, $AdditionalEXEArguments
            }
            elseif (-not [String]::IsNullOrWhiteSpace($EnforcedArguments)) {
                Write-Verbose ('Using enforced arguments "{0}" instead of those in UninstallString' -f $EnforcedArguments)
                $Arguments = $EnforcedArguments
            }

            if (-not [String]::IsNullOrWhiteSpace($Arguments)) {
                $StartProcessSplat['ArgumentList'] = $Arguments.Trim()
                $Message = 'Trying uninstall with "{0} {1}"' -f $FilePath, $StartProcessSplat['ArgumentList']
            }
            else {
                $Message = 'Trying uninstall with "{0}"' -f $FilePath
            }
        }

        Write-Verbose $Message

        $Process = Start-Process @StartProcessSplat
        $Duration = $Process.ExitTime - $Process.StartTime
        Write-Verbose ('Exit code "{0}", duration "{1}"' -f $Process.ExitCode, $Duration)

        if ($PSBoundParameters.ContainsKey('UninstallProcessName')) {
            Start-Sleep -Seconds 5
            try {
                Write-Verbose ('Waiting for process "{0}" to finish' -f $UninstallProcessName)
                Wait-Process -Name $UninstallProcessName -Timeout 1800 -ErrorAction 'Stop'
            }
            catch {
                if ($_.FullyQualifiedErrorId -match 'NoProcessFoundForGivenName') {
                    Write-Verbose 'Process not found, continuing'
                }
                else {
                    throw
                }
            }

        }

        if ($Process.ExitCode -eq 1605 -and $Force.IsPresent) {
            Write-Verbose 'Exit code 1605 detected (product not installed) will be ignored since -Force was specified.'
            return 0
        }
        else {
            return $Process.ExitCode
        }
    
    }
}

function Remove-Paths {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true, Position = 0, ValueFromPipeline = $true)]
        [string[]]$Path
    )

    process {
        foreach ($eachPath in $Path) {
            if (Test-Path $eachPath) {
                Write-Verbose "Removing $eachPath"
                try {
                    Remove-Item -Path $eachPath -Recurse -Force
                }
                catch {
                    Write-Warning "Failed to remove $eachPath`: $_"
                }
            }
            else {
                Write-Verbose "Path $eachPath does not exist"
            }
        }
    }
}

$log = '{0}\Uninstall-Software-{1}.log' -f $env:temp, $DisplayName.Replace(' ', '_').Replace('*', '')
$null = Start-Transcript -Path $log -Append -NoClobber -Force

$VerbosePreference = 'Continue'

$UninstallSoftwareSplat = @{
    EnforcedArguments      = $EnforcedArguments
    AdditionalArguments    = $AdditionalArguments
    AdditionalMSIArguments = $AdditionalMSIArguments
    AdditionalEXEArguments = $AdditionalEXEArguments
    ErrorAction            = $ErrorActionPreference
    Force                  = $Force.IsPresent
}

if ($PSBoundParameters.ContainsKey('ProcessName')) {
    $Processes = Get-Process

    if ($Processes.Name -contains $ProcessName) {
        $Message = "Process '{0}' is already running before the uninstallation has even started, quitting" -f $ProcessName
        $Exception = [System.InvalidOperationException]::new($Message)
        $ErrorRecord = [System.Management.Automation.ErrorRecord]::new(
            $Exception, 
            'ProcessAlreadyRunning', 
            [System.Management.Automation.ErrorCategory]::InvalidOperation, 
            $ProcessName
        )
        Write-Error $ErrorRecord
        $null = Stop-Transcript
        $PSCmdlet.ThrowTerminatingError($ErrorRecord)
    }

    $UninstallSoftwareSplat['UninstallProcessName'] = $ProcessName -replace '\.exe$'
}

$GetInstalledSoftwareSplat = @{
    DisplayName   = $DisplayName
    Architecture  = $Architecture
    HivesToSearch = $HivesToSearch
}

switch ($PSBoundParameters.Keys) {
    'WindowsInstaller'   { $GetInstalledSoftwareSplat['WindowsInstaller'] = $WindowsInstaller }
    'SystemComponent'    { $GetInstalledSoftwareSplat['SystemComponent'] = $SystemComponent }
    'VersionLessThan'    { $GetInstalledSoftwareSplat['VersionLessThan'] = $VersionLessThan }
    'VersionEqualTo'     { $GetInstalledSoftwareSplat['VersionEqualTo'] = $VersionEqualTo }
    'VersionGreaterThan' { $GetInstalledSoftwareSplat['VersionGreaterThan'] = $VersionGreaterThan }
}

[array]$InstalledSoftware = Get-InstalledSoftware @GetInstalledSoftwareSplat

if ($InstalledSoftware.Count -eq 0) {
    Write-Verbose ('Software "{0}" not installed or version does not match criteria' -f $DisplayName)
    if ($RemovePath -and $Force) {
        Write-Verbose 'Force removing path(s) even though no software was found to uninstall.'
        Remove-Paths -Path $RemovePath
    }
}
elseif ($InstalledSoftware.Count -gt 1 -and !$UninstallAll) {
    Write-Verbose ('Found more than one instance of software "{0}". Quitting because not sure which UninstallString to execute. Consider using -UninstallAll switch if necessary.' -f $DisplayName)
}
else {
    if ($InstalledSoftware.Count -gt 1) {
        Write-Verbose ('Found more than one instance of software "{0}". Uninstalling all instances.' -f $DisplayName)
    }
    $errorCount = 0
    foreach ($Software in $InstalledSoftware) {
        Uninstall-Software -Software $Software @UninstallSoftwareSplat -ErrorVariable 'UninstallError'
        $errorCount += $UninstallError.Count
    }
    if ($RemovePath) {
        if ($errorCount -gt 0 -and !$Force) {
            Write-Verbose ('Not removing path(s) ({0}) as errors were encountered during uninstall.' -f ($RemovePath -join ','))
        }
        else {
            if ($errorCount -gt 0) {
                Write-Verbose 'Force removing path(s) even though errors were encountered during uninstall.'
            }
            Remove-Paths -Path $RemovePath
        }
    }
}

$null = Stop-Transcript

# SIG # Begin signature block
# MIIogQYJKoZIhvcNAQcCoIIocjCCKG4CAQExDzANBglghkgBZQMEAgEFADB5Bgor
# BgEEAYI3AgEEoGswaTA0BgorBgEEAYI3AgEeMCYCAwEAAAQQH8w7YFlLCE63JNLG
# KX7zUQIBAAIBAAIBAAIBAAIBADAxMA0GCWCGSAFlAwQCAQUABCAJn99zETLsCJ2D
# rPq/ksFaQkz4yjq0bUrcirF7EhKEvaCCIYQwggWNMIIEdaADAgECAhAOmxiO+dAt
# 5+/bUOIIQBhaMA0GCSqGSIb3DQEBDAUAMGUxCzAJBgNVBAYTAlVTMRUwEwYDVQQK
# EwxEaWdpQ2VydCBJbmMxGTAXBgNVBAsTEHd3dy5kaWdpY2VydC5jb20xJDAiBgNV
# BAMTG0RpZ2lDZXJ0IEFzc3VyZWQgSUQgUm9vdCBDQTAeFw0yMjA4MDEwMDAwMDBa
# Fw0zMTExMDkyMzU5NTlaMGIxCzAJBgNVBAYTAlVTMRUwEwYDVQQKEwxEaWdpQ2Vy
# dCBJbmMxGTAXBgNVBAsTEHd3dy5kaWdpY2VydC5jb20xITAfBgNVBAMTGERpZ2lD
# ZXJ0IFRydXN0ZWQgUm9vdCBHNDCCAiIwDQYJKoZIhvcNAQEBBQADggIPADCCAgoC
# ggIBAL/mkHNo3rvkXUo8MCIwaTPswqclLskhPfKK2FnC4SmnPVirdprNrnsbhA3E
# MB/zG6Q4FutWxpdtHauyefLKEdLkX9YFPFIPUh/GnhWlfr6fqVcWWVVyr2iTcMKy
# unWZanMylNEQRBAu34LzB4TmdDttceItDBvuINXJIB1jKS3O7F5OyJP4IWGbNOsF
# xl7sWxq868nPzaw0QF+xembud8hIqGZXV59UWI4MK7dPpzDZVu7Ke13jrclPXuU1
# 5zHL2pNe3I6PgNq2kZhAkHnDeMe2scS1ahg4AxCN2NQ3pC4FfYj1gj4QkXCrVYJB
# MtfbBHMqbpEBfCFM1LyuGwN1XXhm2ToxRJozQL8I11pJpMLmqaBn3aQnvKFPObUR
# WBf3JFxGj2T3wWmIdph2PVldQnaHiZdpekjw4KISG2aadMreSx7nDmOu5tTvkpI6
# nj3cAORFJYm2mkQZK37AlLTSYW3rM9nF30sEAMx9HJXDj/chsrIRt7t/8tWMcCxB
# YKqxYxhElRp2Yn72gLD76GSmM9GJB+G9t+ZDpBi4pncB4Q+UDCEdslQpJYls5Q5S
# UUd0viastkF13nqsX40/ybzTQRESW+UQUOsxxcpyFiIJ33xMdT9j7CFfxCBRa2+x
# q4aLT8LWRV+dIPyhHsXAj6KxfgommfXkaS+YHS312amyHeUbAgMBAAGjggE6MIIB
# NjAPBgNVHRMBAf8EBTADAQH/MB0GA1UdDgQWBBTs1+OC0nFdZEzfLmc/57qYrhwP
# TzAfBgNVHSMEGDAWgBRF66Kv9JLLgjEtUYunpyGd823IDzAOBgNVHQ8BAf8EBAMC
# AYYweQYIKwYBBQUHAQEEbTBrMCQGCCsGAQUFBzABhhhodHRwOi8vb2NzcC5kaWdp
# Y2VydC5jb20wQwYIKwYBBQUHMAKGN2h0dHA6Ly9jYWNlcnRzLmRpZ2ljZXJ0LmNv
# bS9EaWdpQ2VydEFzc3VyZWRJRFJvb3RDQS5jcnQwRQYDVR0fBD4wPDA6oDigNoY0
# aHR0cDovL2NybDMuZGlnaWNlcnQuY29tL0RpZ2lDZXJ0QXNzdXJlZElEUm9vdENB
# LmNybDARBgNVHSAECjAIMAYGBFUdIAAwDQYJKoZIhvcNAQEMBQADggEBAHCgv0Nc
# Vec4X6CjdBs9thbX979XB72arKGHLOyFXqkauyL4hxppVCLtpIh3bb0aFPQTSnov
# Lbc47/T/gLn4offyct4kvFIDyE7QKt76LVbP+fT3rDB6mouyXtTP0UNEm0Mh65Zy
# oUi0mcudT6cGAxN3J0TU53/oWajwvy8LpunyNDzs9wPHh6jSTEAZNUZqaVSwuKFW
# juyk1T3osdz9HNj0d1pcVIxv76FQPfx2CWiEn2/K2yCNNWAcAgPLILCsWKAOQGPF
# mCLBsln1VWvPJ6tsds5vIy30fnFqI2si/xK4VC0nftg62fC2h5b9W9FcrBjDTZ9z
# twGpn1eqXijiuZQwggauMIIElqADAgECAhAHNje3JFR82Ees/ShmKl5bMA0GCSqG
# SIb3DQEBCwUAMGIxCzAJBgNVBAYTAlVTMRUwEwYDVQQKEwxEaWdpQ2VydCBJbmMx
# GTAXBgNVBAsTEHd3dy5kaWdpY2VydC5jb20xITAfBgNVBAMTGERpZ2lDZXJ0IFRy
# dXN0ZWQgUm9vdCBHNDAeFw0yMjAzMjMwMDAwMDBaFw0zNzAzMjIyMzU5NTlaMGMx
# CzAJBgNVBAYTAlVTMRcwFQYDVQQKEw5EaWdpQ2VydCwgSW5jLjE7MDkGA1UEAxMy
# RGlnaUNlcnQgVHJ1c3RlZCBHNCBSU0E0MDk2IFNIQTI1NiBUaW1lU3RhbXBpbmcg
# Q0EwggIiMA0GCSqGSIb3DQEBAQUAA4ICDwAwggIKAoICAQDGhjUGSbPBPXJJUVXH
# JQPE8pE3qZdRodbSg9GeTKJtoLDMg/la9hGhRBVCX6SI82j6ffOciQt/nR+eDzMf
# UBMLJnOWbfhXqAJ9/UO0hNoR8XOxs+4rgISKIhjf69o9xBd/qxkrPkLcZ47qUT3w
# 1lbU5ygt69OxtXXnHwZljZQp09nsad/ZkIdGAHvbREGJ3HxqV3rwN3mfXazL6IRk
# tFLydkf3YYMZ3V+0VAshaG43IbtArF+y3kp9zvU5EmfvDqVjbOSmxR3NNg1c1eYb
# qMFkdECnwHLFuk4fsbVYTXn+149zk6wsOeKlSNbwsDETqVcplicu9Yemj052FVUm
# cJgmf6AaRyBD40NjgHt1biclkJg6OBGz9vae5jtb7IHeIhTZgirHkr+g3uM+onP6
# 5x9abJTyUpURK1h0QCirc0PO30qhHGs4xSnzyqqWc0Jon7ZGs506o9UD4L/wojzK
# QtwYSH8UNM/STKvvmz3+DrhkKvp1KCRB7UK/BZxmSVJQ9FHzNklNiyDSLFc1eSuo
# 80VgvCONWPfcYd6T/jnA+bIwpUzX6ZhKWD7TA4j+s4/TXkt2ElGTyYwMO1uKIqjB
# Jgj5FBASA31fI7tk42PgpuE+9sJ0sj8eCXbsq11GdeJgo1gJASgADoRU7s7pXche
# MBK9Rp6103a50g5rmQzSM7TNsQIDAQABo4IBXTCCAVkwEgYDVR0TAQH/BAgwBgEB
# /wIBADAdBgNVHQ4EFgQUuhbZbU2FL3MpdpovdYxqII+eyG8wHwYDVR0jBBgwFoAU
# 7NfjgtJxXWRM3y5nP+e6mK4cD08wDgYDVR0PAQH/BAQDAgGGMBMGA1UdJQQMMAoG
# CCsGAQUFBwMIMHcGCCsGAQUFBwEBBGswaTAkBggrBgEFBQcwAYYYaHR0cDovL29j
# c3AuZGlnaWNlcnQuY29tMEEGCCsGAQUFBzAChjVodHRwOi8vY2FjZXJ0cy5kaWdp
# Y2VydC5jb20vRGlnaUNlcnRUcnVzdGVkUm9vdEc0LmNydDBDBgNVHR8EPDA6MDig
# NqA0hjJodHRwOi8vY3JsMy5kaWdpY2VydC5jb20vRGlnaUNlcnRUcnVzdGVkUm9v
# dEc0LmNybDAgBgNVHSAEGTAXMAgGBmeBDAEEAjALBglghkgBhv1sBwEwDQYJKoZI
# hvcNAQELBQADggIBAH1ZjsCTtm+YqUQiAX5m1tghQuGwGC4QTRPPMFPOvxj7x1Bd
# 4ksp+3CKDaopafxpwc8dB+k+YMjYC+VcW9dth/qEICU0MWfNthKWb8RQTGIdDAiC
# qBa9qVbPFXONASIlzpVpP0d3+3J0FNf/q0+KLHqrhc1DX+1gtqpPkWaeLJ7giqzl
# /Yy8ZCaHbJK9nXzQcAp876i8dU+6WvepELJd6f8oVInw1YpxdmXazPByoyP6wCeC
# RK6ZJxurJB4mwbfeKuv2nrF5mYGjVoarCkXJ38SNoOeY+/umnXKvxMfBwWpx2cYT
# gAnEtp/Nh4cku0+jSbl3ZpHxcpzpSwJSpzd+k1OsOx0ISQ+UzTl63f8lY5knLD0/
# a6fxZsNBzU+2QJshIUDQtxMkzdwdeDrknq3lNHGS1yZr5Dhzq6YBT70/O3itTK37
# xJV77QpfMzmHQXh6OOmc4d0j/R0o08f56PGYX/sr2H7yRp11LB4nLCbbbxV7HhmL
# NriT1ObyF5lZynDwN7+YAN8gFk8n+2BnFqFmut1VwDophrCYoCvtlUG3OtUVmDG0
# YgkPCr2B2RP+v6TR81fZvAT6gt4y3wSJ8ADNXcL50CN/AAvkdgIm2fBldkKmKYcJ
# RyvmfxqkhQ/8mJb2VVQrH4D6wPIOK+XW+6kvRBVK5xMOHds3OBqhK/bt1nz8MIIG
# sDCCBJigAwIBAgIQCK1AsmDSnEyfXs2pvZOu2TANBgkqhkiG9w0BAQwFADBiMQsw
# CQYDVQQGEwJVUzEVMBMGA1UEChMMRGlnaUNlcnQgSW5jMRkwFwYDVQQLExB3d3cu
# ZGlnaWNlcnQuY29tMSEwHwYDVQQDExhEaWdpQ2VydCBUcnVzdGVkIFJvb3QgRzQw
# HhcNMjEwNDI5MDAwMDAwWhcNMzYwNDI4MjM1OTU5WjBpMQswCQYDVQQGEwJVUzEX
# MBUGA1UEChMORGlnaUNlcnQsIEluYy4xQTA/BgNVBAMTOERpZ2lDZXJ0IFRydXN0
# ZWQgRzQgQ29kZSBTaWduaW5nIFJTQTQwOTYgU0hBMzg0IDIwMjEgQ0ExMIICIjAN
# BgkqhkiG9w0BAQEFAAOCAg8AMIICCgKCAgEA1bQvQtAorXi3XdU5WRuxiEL1M4zr
# PYGXcMW7xIUmMJ+kjmjYXPXrNCQH4UtP03hD9BfXHtr50tVnGlJPDqFX/IiZwZHM
# gQM+TXAkZLON4gh9NH1MgFcSa0OamfLFOx/y78tHWhOmTLMBICXzENOLsvsI8Irg
# nQnAZaf6mIBJNYc9URnokCF4RS6hnyzhGMIazMXuk0lwQjKP+8bqHPNlaJGiTUyC
# EUhSaN4QvRRXXegYE2XFf7JPhSxIpFaENdb5LpyqABXRN/4aBpTCfMjqGzLmysL0
# p6MDDnSlrzm2q2AS4+jWufcx4dyt5Big2MEjR0ezoQ9uo6ttmAaDG7dqZy3SvUQa
# khCBj7A7CdfHmzJawv9qYFSLScGT7eG0XOBv6yb5jNWy+TgQ5urOkfW+0/tvk2E0
# XLyTRSiDNipmKF+wc86LJiUGsoPUXPYVGUztYuBeM/Lo6OwKp7ADK5GyNnm+960I
# HnWmZcy740hQ83eRGv7bUKJGyGFYmPV8AhY8gyitOYbs1LcNU9D4R+Z1MI3sMJN2
# FKZbS110YU0/EpF23r9Yy3IQKUHw1cVtJnZoEUETWJrcJisB9IlNWdt4z4FKPkBH
# X8mBUHOFECMhWWCKZFTBzCEa6DgZfGYczXg4RTCZT/9jT0y7qg0IU0F8WD1Hs/q2
# 7IwyCQLMbDwMVhECAwEAAaOCAVkwggFVMBIGA1UdEwEB/wQIMAYBAf8CAQAwHQYD
# VR0OBBYEFGg34Ou2O/hfEYb7/mF7CIhl9E5CMB8GA1UdIwQYMBaAFOzX44LScV1k
# TN8uZz/nupiuHA9PMA4GA1UdDwEB/wQEAwIBhjATBgNVHSUEDDAKBggrBgEFBQcD
# AzB3BggrBgEFBQcBAQRrMGkwJAYIKwYBBQUHMAGGGGh0dHA6Ly9vY3NwLmRpZ2lj
# ZXJ0LmNvbTBBBggrBgEFBQcwAoY1aHR0cDovL2NhY2VydHMuZGlnaWNlcnQuY29t
# L0RpZ2lDZXJ0VHJ1c3RlZFJvb3RHNC5jcnQwQwYDVR0fBDwwOjA4oDagNIYyaHR0
# cDovL2NybDMuZGlnaWNlcnQuY29tL0RpZ2lDZXJ0VHJ1c3RlZFJvb3RHNC5jcmww
# HAYDVR0gBBUwEzAHBgVngQwBAzAIBgZngQwBBAEwDQYJKoZIhvcNAQEMBQADggIB
# ADojRD2NCHbuj7w6mdNW4AIapfhINPMstuZ0ZveUcrEAyq9sMCcTEp6QRJ9L/Z6j
# fCbVN7w6XUhtldU/SfQnuxaBRVD9nL22heB2fjdxyyL3WqqQz/WTauPrINHVUHmI
# moqKwba9oUgYftzYgBoRGRjNYZmBVvbJ43bnxOQbX0P4PpT/djk9ntSZz0rdKOtf
# JqGVWEjVGv7XJz/9kNF2ht0csGBc8w2o7uCJob054ThO2m67Np375SFTWsPK6Wrx
# oj7bQ7gzyE84FJKZ9d3OVG3ZXQIUH0AzfAPilbLCIXVzUstG2MQ0HKKlS43Nb3Y3
# LIU/Gs4m6Ri+kAewQ3+ViCCCcPDMyu/9KTVcH4k4Vfc3iosJocsL6TEa/y4ZXDlx
# 4b6cpwoG1iZnt5LmTl/eeqxJzy6kdJKt2zyknIYf48FWGysj/4+16oh7cGvmoLr9
# Oj9FpsToFpFSi0HASIRLlk2rREDjjfAVKM7t8RhWByovEMQMCGQ8M4+uKIw8y4+I
# Cw2/O/TOHnuO77Xry7fwdxPm5yg/rBKupS8ibEH5glwVZsxsDsrFhsP2JjMMB0ug
# 0wcCampAMEhLNKhRILutG4UI4lkNbcoFUCvqShyepf2gpx8GdOfy1lKQ/a+FSCH5
# Vzu0nAPthkX0tGFuv2jiJmCG6sivqf6UHedjGzqGVnhOMIIGvDCCBKSgAwIBAgIQ
# C65mvFq6f5WHxvnpBOMzBDANBgkqhkiG9w0BAQsFADBjMQswCQYDVQQGEwJVUzEX
# MBUGA1UEChMORGlnaUNlcnQsIEluYy4xOzA5BgNVBAMTMkRpZ2lDZXJ0IFRydXN0
# ZWQgRzQgUlNBNDA5NiBTSEEyNTYgVGltZVN0YW1waW5nIENBMB4XDTI0MDkyNjAw
# MDAwMFoXDTM1MTEyNTIzNTk1OVowQjELMAkGA1UEBhMCVVMxETAPBgNVBAoTCERp
# Z2lDZXJ0MSAwHgYDVQQDExdEaWdpQ2VydCBUaW1lc3RhbXAgMjAyNDCCAiIwDQYJ
# KoZIhvcNAQEBBQADggIPADCCAgoCggIBAL5qc5/2lSGrljC6W23mWaO16P2RHxjE
# iDtqmeOlwf0KMCBDEr4IxHRGd7+L660x5XltSVhhK64zi9CeC9B6lUdXM0s71EOc
# Re8+CEJp+3R2O8oo76EO7o5tLuslxdr9Qq82aKcpA9O//X6QE+AcaU/byaCagLD/
# GLoUb35SfWHh43rOH3bpLEx7pZ7avVnpUVmPvkxT8c2a2yC0WMp8hMu60tZR0Cha
# V76Nhnj37DEYTX9ReNZ8hIOYe4jl7/r419CvEYVIrH6sN00yx49boUuumF9i2T8U
# uKGn9966fR5X6kgXj3o5WHhHVO+NBikDO0mlUh902wS/Eeh8F/UFaRp1z5SnROHw
# SJ+QQRZ1fisD8UTVDSupWJNstVkiqLq+ISTdEjJKGjVfIcsgA4l9cbk8Smlzddh4
# EfvFrpVNnes4c16Jidj5XiPVdsn5n10jxmGpxoMc6iPkoaDhi6JjHd5ibfdp5uzI
# Xp4P0wXkgNs+CO/CacBqU0R4k+8h6gYldp4FCMgrXdKWfM4N0u25OEAuEa3Jyidx
# W48jwBqIJqImd93NRxvd1aepSeNeREXAu2xUDEW8aqzFQDYmr9ZONuc2MhTMizch
# NULpUEoA6Vva7b1XCB+1rxvbKmLqfY/M/SdV6mwWTyeVy5Z/JkvMFpnQy5wR14GJ
# cv6dQ4aEKOX5AgMBAAGjggGLMIIBhzAOBgNVHQ8BAf8EBAMCB4AwDAYDVR0TAQH/
# BAIwADAWBgNVHSUBAf8EDDAKBggrBgEFBQcDCDAgBgNVHSAEGTAXMAgGBmeBDAEE
# AjALBglghkgBhv1sBwEwHwYDVR0jBBgwFoAUuhbZbU2FL3MpdpovdYxqII+eyG8w
# HQYDVR0OBBYEFJ9XLAN3DigVkGalY17uT5IfdqBbMFoGA1UdHwRTMFEwT6BNoEuG
# SWh0dHA6Ly9jcmwzLmRpZ2ljZXJ0LmNvbS9EaWdpQ2VydFRydXN0ZWRHNFJTQTQw
# OTZTSEEyNTZUaW1lU3RhbXBpbmdDQS5jcmwwgZAGCCsGAQUFBwEBBIGDMIGAMCQG
# CCsGAQUFBzABhhhodHRwOi8vb2NzcC5kaWdpY2VydC5jb20wWAYIKwYBBQUHMAKG
# TGh0dHA6Ly9jYWNlcnRzLmRpZ2ljZXJ0LmNvbS9EaWdpQ2VydFRydXN0ZWRHNFJT
# QTQwOTZTSEEyNTZUaW1lU3RhbXBpbmdDQS5jcnQwDQYJKoZIhvcNAQELBQADggIB
# AD2tHh92mVvjOIQSR9lDkfYR25tOCB3RKE/P09x7gUsmXqt40ouRl3lj+8QioVYq
# 3igpwrPvBmZdrlWBb0HvqT00nFSXgmUrDKNSQqGTdpjHsPy+LaalTW0qVjvUBhcH
# zBMutB6HzeledbDCzFzUy34VarPnvIWrqVogK0qM8gJhh/+qDEAIdO/KkYesLyTV
# OoJ4eTq7gj9UFAL1UruJKlTnCVaM2UeUUW/8z3fvjxhN6hdT98Vr2FYlCS7Mbb4H
# v5swO+aAXxWUm3WpByXtgVQxiBlTVYzqfLDbe9PpBKDBfk+rabTFDZXoUke7zPgt
# d7/fvWTlCs30VAGEsshJmLbJ6ZbQ/xll/HjO9JbNVekBv2Tgem+mLptR7yIrpaid
# RJXrI+UzB6vAlk/8a1u7cIqV0yef4uaZFORNekUgQHTqddmsPCEIYQP7xGxZBIhd
# mm4bhYsVA6G2WgNFYagLDBzpmk9104WQzYuVNsxyoVLObhx3RugaEGru+SojW4dH
# PoWrUhftNpFC5H7QEY7MhKRyrBe7ucykW7eaCuWBsBb4HOKRFVDcrZgdwaSIqMDi
# CLg4D+TPVgKx2EgEdeoHNHT9l3ZDBD+XgbF+23/zBjeCtxz+dL/9NWR6P2eZRi7z
# cEO1xwcdcqJsyz/JceENc2Sg8h3KeFUCS7tpFk7CrDqkMIIHyTCCBbGgAwIBAgIQ
# DMNw87U7UZ48Hv1za61jojANBgkqhkiG9w0BAQsFADBpMQswCQYDVQQGEwJVUzEX
# MBUGA1UEChMORGlnaUNlcnQsIEluYy4xQTA/BgNVBAMTOERpZ2lDZXJ0IFRydXN0
# ZWQgRzQgQ29kZSBTaWduaW5nIFJTQTQwOTYgU0hBMzg0IDIwMjEgQ0ExMB4XDTIz
# MDQwNzAwMDAwMFoXDTI2MDQzMDIzNTk1OVowgdExEzARBgsrBgEEAYI3PAIBAxMC
# VVMxGTAXBgsrBgEEAYI3PAIBAhMIQ29sb3JhZG8xHTAbBgNVBA8MFFByaXZhdGUg
# T3JnYW5pemF0aW9uMRQwEgYDVQQFEwsyMDEzMTYzODMyNzELMAkGA1UEBhMCVVMx
# ETAPBgNVBAgTCENvbG9yYWRvMRQwEgYDVQQHEwtDYXN0bGUgUm9jazEZMBcGA1UE
# ChMQUGF0Y2ggTXkgUEMsIExMQzEZMBcGA1UEAxMQUGF0Y2ggTXkgUEMsIExMQzCC
# AiIwDQYJKoZIhvcNAQEBBQADggIPADCCAgoCggIBAKaQcs40YzBFv5HXQFPd04rK
# J4uBdwvAZLKuULy+icZOpgs/Sy329Ng5ikhB5o1IdvE2cOT20sjs3qgb4e+rqs7t
# aTCe6RNLsDINsmcTlp4yxOfV80EZ08ld3o36GEgH0Vy1vrJXLTRKNULzV7gIzF/e
# 3tO1Fab4IxKZNcBSXiv8ORqcgT9O7/RZoqyG87iU6Q/dKfC4WzvU396XJ3FMZrI+
# s4CgV8p6pVNjijBjH7pmzoXynFtA0j6NH6tg4DmQvm+kfWXtWbDpPYhdFz1gccJt
# 1DjTrJetpIwBzDAS8NGA75HQhBmQ3gcnNDJLgylB3HyWOeXS+vxXR0Pi/W419cfn
# 8zCFH0u2O4QFaZsT2HoIE/t9EhdAKdHoKwvVoCgwvlx3jjwFq5MnoB2oJiNmTGQy
# hiRvCaw6JACKUa43eJvlRKylEy4INDTOX5BeivJoTqCw0cCAd6ZuRh6gRl8shIVf
# N78qunQqJZQkDimtQY5Sn33w+ee5/lFSxOxBg6iu7vCGPZ6QxJd6oVdRa8t87vJ4
# QVlsMQQRa400S7kqIX1HOnbR3hxgvcks8kBRMYtZ8g3Fz/WTCW5sWbExVpn6HC6D
# sRhosF/DBGYmIqQJz6odkCFCr7QcmpGjoZs4jRDegSC5utEusBYmvCfVxtud3R43
# WEdCRfHuD1OFDm5HoonnAgMBAAGjggICMIIB/jAfBgNVHSMEGDAWgBRoN+Drtjv4
# XxGG+/5hewiIZfROQjAdBgNVHQ4EFgQU3wgET0b7maQo7OF3wwGWm83hl+0wDgYD
# VR0PAQH/BAQDAgeAMBMGA1UdJQQMMAoGCCsGAQUFBwMDMIG1BgNVHR8Ega0wgaow
# U6BRoE+GTWh0dHA6Ly9jcmwzLmRpZ2ljZXJ0LmNvbS9EaWdpQ2VydFRydXN0ZWRH
# NENvZGVTaWduaW5nUlNBNDA5NlNIQTM4NDIwMjFDQTEuY3JsMFOgUaBPhk1odHRw
# Oi8vY3JsNC5kaWdpY2VydC5jb20vRGlnaUNlcnRUcnVzdGVkRzRDb2RlU2lnbmlu
# Z1JTQTQwOTZTSEEzODQyMDIxQ0ExLmNybDA9BgNVHSAENjA0MDIGBWeBDAEDMCkw
# JwYIKwYBBQUHAgEWG2h0dHA6Ly93d3cuZGlnaWNlcnQuY29tL0NQUzCBlAYIKwYB
# BQUHAQEEgYcwgYQwJAYIKwYBBQUHMAGGGGh0dHA6Ly9vY3NwLmRpZ2ljZXJ0LmNv
# bTBcBggrBgEFBQcwAoZQaHR0cDovL2NhY2VydHMuZGlnaWNlcnQuY29tL0RpZ2lD
# ZXJ0VHJ1c3RlZEc0Q29kZVNpZ25pbmdSU0E0MDk2U0hBMzg0MjAyMUNBMS5jcnQw
# CQYDVR0TBAIwADANBgkqhkiG9w0BAQsFAAOCAgEADaIfBgYBzz7rZspAw5OGKL7n
# t4eo6SMcS91NAex1HWxak4hX7yqQB25Oa66WaVBtd14rZxptoGQ88FDezI1qyUs4
# bwi4NaW9WBY8QDnGGhgyZ3aT3ZEBEvMWy6MFpzlyvjPBcWE5OGuoRMhP42TSMhvF
# lZGCPZy02PLUdGcTynL55YhdTcGJnX0Z2OgSaHUQTmXhgRX+fajIilPnmmv8Av4C
# lr6Xa9SoNHltA04JRiCu4ejDGFqA94F696jSJ+AUYHys6bnPc0E8JB9YnFCAurPR
# G8YBJAofUtxnGIHGE0EiQTZeXf0nKmVBIXkE3hT4mZx7pH7wrlCr0FV4qnq6j0ua
# j4oKqFbkdyzb5u+XQe9pPojshnjVzhIRK53wsGaFP4gSURxWvcThIOyoaKrVDZOd
# LQZXEz8Anks3Vs5XscjyzFR7pv/3Reik7FaZRTvd5rDW6foDJOiCwX5p+UnldHGH
# W83rDvtks1rwgKwuuxvCG3Bkjirl94EImpiugGaRQ7S2Lydxpqzv7Hng4YQbIIvV
# MNC7mNrVZPNWdF4/a9yjDt2nJrnRcDK1zvHBXSrAYIycQ6hhhlHS9Y4MRhz35t1d
# u/Y0IXDB7HBYSvcsrpxtBzXLTd2NCNCtdkwYIl7WTQeoCbZWvo4PbzJBOnPjs1tN
# 4upe9XomxtZkNAwIOfMxggZTMIIGTwIBATB9MGkxCzAJBgNVBAYTAlVTMRcwFQYD
# VQQKEw5EaWdpQ2VydCwgSW5jLjFBMD8GA1UEAxM4RGlnaUNlcnQgVHJ1c3RlZCBH
# NCBDb2RlIFNpZ25pbmcgUlNBNDA5NiBTSEEzODQgMjAyMSBDQTECEAzDcPO1O1Ge
# PB79c2utY6IwDQYJYIZIAWUDBAIBBQCggYQwGAYKKwYBBAGCNwIBDDEKMAigAoAA
# oQKAADAZBgkqhkiG9w0BCQMxDAYKKwYBBAGCNwIBBDAcBgorBgEEAYI3AgELMQ4w
# DAYKKwYBBAGCNwIBFTAvBgkqhkiG9w0BCQQxIgQgqdP34c7FnV9to7a5sTfttImU
# yV6KoAQP1GszPQLBQUgwDQYJKoZIhvcNAQEBBQAEggIAloTx3prm8j1qnU6Ybr2K
# oyds5yHmwOUD4D/pVIkc7Pk3LmW6PBQte01a4ntoCfwlA20h/oE52/E9ULZR12LJ
# 2YziCSnwwEm76V6UVt2yGfxl2eDpJNxTpdOqV6PECpIfAkYARk0t0oR+2rygVxo5
# zXm6iSLOtTrQnWtP134jV7QhkFmZ9pm6BW0dpR3olewsQEtKW6fGlykZtYntpxZL
# vsI+7L+pjssvqh3SGwJq7q7NNeL5kyqxDvRoo5/jAfvvNuYDpUsQf/yAcPCW8ycK
# rcbgvFpm0HbTwq5J0ho07HzUwJZu16+i5PxXSsIUsNlifi9585V/jsIG14IlEhOC
# HA5MRfWQX2iGgo+zkV1AFAoqsZe+t53p+t97AHOVjCzQGAkPruKoTkS+ulNDiFDy
# 92pnh0CY9WaG0gLeDeNKkK7Zka+DerTRlkSF7cfPs4Gv1q4f1EGChi7Ar6ESVq5b
# H5rrgonJgn7fqeyJ6ncySrL5cCDc/Da2kjPNM9kDkQQ+3MKnMTCNa+5359KlzhLh
# 66sDNlOHF02OqwpD8VQs7H4uteMMFwdQgq3IxNYoib8KFl2xdbzEHSyLw0uJrOgT
# 93DUZ69hQ/yuMZOsrvs3XoEDsoyCoJWvSSeLyj2MSpFlapxmgQQMuoAH1OYHu9ev
# e3pK2tM+L5w/Z0aRULSRfxuhggMgMIIDHAYJKoZIhvcNAQkGMYIDDTCCAwkCAQEw
# dzBjMQswCQYDVQQGEwJVUzEXMBUGA1UEChMORGlnaUNlcnQsIEluYy4xOzA5BgNV
# BAMTMkRpZ2lDZXJ0IFRydXN0ZWQgRzQgUlNBNDA5NiBTSEEyNTYgVGltZVN0YW1w
# aW5nIENBAhALrma8Wrp/lYfG+ekE4zMEMA0GCWCGSAFlAwQCAQUAoGkwGAYJKoZI
# hvcNAQkDMQsGCSqGSIb3DQEHATAcBgkqhkiG9w0BCQUxDxcNMjQxMDE0MTYzMzMy
# WjAvBgkqhkiG9w0BCQQxIgQgaSnwahiHXpcOK2PpP3NHESuWcwhvCKayblOnenj4
# dS4wDQYJKoZIhvcNAQEBBQAEggIABfzGeTylziT4Wvb2co5rXi51QpUpbcbgHzHW
# HLnLKw7dvGdoIGLtRiqPXCo96LY1jb2eEAsD27obn6TtV04ASnh71JQxg1TwILXe
# IXnCe1wSj6Xx1U3ztzyPRpLqT2P6wpsI9gcFXQ3q1sXv/lFcGFIS2SgyTB73S3wj
# iOrwwwoUPxSjWBCAcrfakYLwbD9ImRqwIwdXIfyI+4C1g9HzAcEPmbArGqS8n9NJ
# 5XJUDJ7z2MuPjkpfRYFhR9shdDrloMb/uJHBXm3uHe72067ReqO7Ai4FE853Svk0
# /gH81EdArkN2OskdtncjeWCPbl4vwTp9+2a7ztxJh32gLgDNx8qa7eluGcgRE+Uy
# OuXNKUzK5sKeFD1XR1fWOV0b9s+FyayyEx7z3HiDLQho2/ea03uMwOtIAzo1BazC
# TIjolGA1gasMJRJNZk4Els9CzayatvhV3mkwSYkkmap2cRoPrD/RvOqWK/uRN6ME
# kVKQm7kZHpQS6NWWuXIU2qg8HohyrFDiLmIBJcR/0kvyc12MFZO5fNIaOwhRUKtg
# 93nq3uWH7gB1KieYyzyAIFwcjQBqSE8Wa7i0p8KB/QCJmCqiCWb8edRr02iK8PcY
# sJs5a6uDNy+ITPMJfDhEDmsFtP13qPDbXhXtljgmFBgWneRYW8ss9209WsEtAhbz
# KXQW8o4=
# SIG # End signature block
