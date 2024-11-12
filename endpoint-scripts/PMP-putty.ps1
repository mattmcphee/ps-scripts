[CmdletBinding()]
param(
    # possibly a string to search pmp for
    [string]$AppToSearch = 'PuTTY release*',
    # regex string to search for
    [string]$RegexAppToSearch = '',
    [string]$AppToAvoid = '*CAC*',
    [string]$AppMSICodeToSearch = '{ddc95f26-92b1-4546-9678-5dc68df76ba0}',
    [string]$ApplicationVersionToSearch = '0.81',
    [string]$ApplicationVersionFilter = '*',
    [ValidateSet('Both', 'x86', 'x64')]
    [string]$Architecture = 'x64',
    [ValidateRange(-1, 1)]
    [int]$SystemComponent = -1,
    [ValidateSet('Detection', 'Requirement')]
    [string]$Purpose = 'Detection',
    [ValidateSet('HKLM', 'HKCU')]
    [string[]]$HivesToSearch = 'HKLM',
    [ValidateSet('EXE', 'MSI', 'ANY')]
    [string]$InstallerType = 'Msi',
    [hashtable]$RegKeyDetection = @{},
    [string]$LogFileName = 'PatchMyPC-SoftwareDetectionScript.log'
)

$ScriptVersion = '3.4'
function Get-CMLogDirectory {
    [CmdletBinding()]
    param()
    try {
        $LogDir = (Get-ItemProperty `
        -Path registry::HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\CCM\Logging\@Global\ `
        -Name LogDirectory `
        -ErrorAction Stop).LogDirectory
    } catch {
        $LogDir = $null
    }
    Write-Verbose "CCM Log Directory = $LogDir"
    return $LogDir
}
function Get-CurrentUser {
    [CmdletBinding()]
    param()
    $currentUser = [Security.Principal.WindowsIdentity]::GetCurrent()
    Write-Verbose "Current User = $($currentUser.Name)"
    return $currentUser
}
function Test-IsRunningAsAdministrator {
    [CmdletBinding()]
    param()
    $currentUser = Get-CurrentUser
    $IsUserAdmin = (
        New-Object Security.Principal.WindowsPrincipal $currentUser
    ).IsInRole(
        [Security.Principal.WindowsBuiltinRole]::Administrator
    )
    Write-Verbose "Current User Is Admin = $IsUserAdmin"
    return $IsUserAdmin
}
function Test-IsRunningAsSystem {
    [CmdletBinding()]
    param()
    $RunningAsSystem = (Get-CurrentUser).User -eq 'S-1-5-18'
    Write-Verbose "Running as system = $RunningAsSystem"
    return $RunningAsSystem
}
function Get-PMPLogPath {
    [CmdletBinding()]
    param()
    $LogPath = $env:temp
    if (Test-IsRunningAsSystem) {
        $CMLogDir = Get-CMLogDirectory
        if ($null -ne $CMLogDir -and (Test-Path -Path $CMLogDir)) {
            $LogPath = $CMLogDir
        } else {
            if (Test-Path -Path "$env:programdata\PatchMyPCIntuneLogs") {
                $LogPath = "$env:programdata\PatchMyPCIntuneLogs"
            } else {
                try {
                    $null = New-Item -ItemType Directory -Force `
                    -Path "$env:programdata\PatchMyPCIntuneLogs" `
                    -ErrorAction SilentlyContinue
                    $LogPath = "$env:programdata\PatchMyPCIntuneLogs"
                } catch {}
            } #else
        } #else
    } #if
    Write-Verbose "LogPath = $LogPath"
    return $LogPath
}
Function Write-CCMLogEntry {
    param (
        [parameter(Mandatory = $true, ValueFromPipelineByPropertyName = $true)]
        [Alias('Message', 'ToLog')]
        [string[]]$Value,
        [ValidateSet(1, 2, 3)]
        [int]$Severity = 1,
        [string]$Component = [string]::Format('PatchMyPC-{0}:{1}', $Purpose, $($MyInvocation.ScriptLineNumber)),
        [parameter(Mandatory = $true)]
        [string]$FileName,
        [parameter(Mandatory = $true)]
        [string]$Folder,
        [int]$Bias = [System.DateTimeOffset]::Now.Offset.TotalMinutes,
        [int]$MaxLogFileSize = 5MB,
        [int]$LogsToKeep = 0
    )
    begin {
        $LogFilePath = Join-Path -Path $Folder -ChildPath $FileName
        switch (([System.IO.FileInfo]$LogFilePath).Exists -and $MaxLogFileSize -gt 0) {
            $true {
                switch (([System.IO.FileInfo]$LogFilePath).Length -ge $MaxLogFileSize) {
                    $true {
                        $LogFileNameWithoutExt = $FileName -replace ([System.IO.Path]::GetExtension($FileName))
                        $AllLogs = Get-ChildItem -Path $Folder -Name "$($LogFileNameWithoutExt)_*" -File
                        $AllLogs = Sort-Object -InputObject $AllLogs -Descending -Property { $_ -replace '_\d+\.lo_$' }, { [int]($_ -replace '^.+\d_|\.lo_$') } -ErrorAction Ignore
                        foreach ($Log in $AllLogs) {
                            $LogFileNumber = [int][Regex]::Matches($Log, '_([0-9]+)\.lo_$').Groups[1].Value
                            switch (($LogFileNumber -eq $LogsToKeep) -and ($LogsToKeep -ne 0)) {
                                $true {
                                    [System.IO.File]::Delete("$($Folder)\$($Log)")}
                                $false {
                                    $NewFileName = $Log -replace '_([0-9]+)\.lo_$', "_$($LogFileNumber+1).lo_"
                                    [System.IO.File]::Copy("$($Folder)\$($Log)", "$($Folder)\$($NewFileName)", $true)}}}
                        [System.IO.File]::Copy($LogFilePath, "$($Folder)\$($LogFileNameWithoutExt)_1.lo_", $true)
                        $StreamWriter = New-Object -TypeName System.IO.StreamWriter -ArgumentList $LogFilePath, $false
                        $StreamWriter.Close()}}}}
        $DateTime = Get-Date
        $Date = $DateTime.ToString("MM-dd-yyyy", [Globalization.CultureInfo]::InvariantCulture)
        $Time = $DateTime.ToString("HH:mm:ss.ffffff", [Globalization.CultureInfo]::InvariantCulture)
        $Context = $([System.Security.Principal.WindowsIdentity]::GetCurrent().Name)
    }
    process {
        foreach ($MSG in $Value) {
            $LogText = [string]::Format('<![LOG[{0}]LOG]!><time="{1}" date="{2}" component="{3}" context="{4}" type="{5}" thread="{6}" file="">', $MSG, $Time, $Date, $Component, $Context, $Severity, $PID)
            try {
                $StreamWriter = New-Object -TypeName System.IO.StreamWriter -ArgumentList $LogFilePath, 'Append'
                $StreamWriter.WriteLine($LogText)
                $StreamWriter.Close()}
            catch [System.Exception] {
                try {$LogText | Out-File -FilePath $LogFilePath -Append -ErrorAction Stop}
                catch {Write-Error -Message "Unable to append log entry to $FileName file. Error message: $($_.Exception.Message)"}}}}}
Function Get-PMPVersionFromString {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [string]$stringVar
    )
    $ExtractedVersion = [string]::Empty
    $stringVar = $stringVar.replace('-','.').Replace('_','.')
    if ($stringVar -match '\d+\.\d+(\.\d+)?(\.\d+)?') {
        $ExtractedVersion = $Matches[0]
    }
    Write-Verbose "Extracted version $ExtractedVersion from $stringVar"
    return $ExtractedVersion
}
Function ConvertTo-PMPVersion {
    [CmdletBinding()]
    param(
        [string]$versionString
    )
    try {
        switch (($versionString.ToCharArray() | Where-Object { $_ -eq '.' }).Count) {
            0 {$versionString += '.0' * 3}
            1 {$versionString += '.0.0'}
            2 {$versionString += '.0'}
        }
        return Get-PMPParsedVersion -versionString $versionString
    }
    catch {
        $splitVersionString = $versionString.Split([char]46)
        $fixedVersionStringArray = foreach ($Component in $splitVersionString) {
            try {[int]$Component}
            catch {Write-Verbose "Failed to cast part of the version to an integer. Defaulting to max 32 bit signed integer. [Original Value: $Component]";[int]::MaxValue}}
        try {Get-PMPParsedVersion -versionString $([string]::Join([char]46, $fixedVersionStringArray))}
        catch {return [System.Version]('0.0.0.0')}}}
Function Get-PMPParsedVersion {
    [CmdletBinding()]
    param(
        [string]$versionString
    )
    [System.Version]$version = $versionString
    $major = if ($version.Major -eq -1) {0} else {$version.Major}
    $minor = if ($version.Minor -eq -1) {0} else {$version.Minor}
    $build = if ($version.Build -eq -1) {0} else {$version.Build}
    $revision = if ($version.Revision -eq -1) {0} else {$version.Revision}
    return [System.Version]("$major.$minor.$build.$revision")
}
Function Compare-PMPVersion {
    param(
        [string]$CurrentVersion,
        [string]$TargetVersion,
        [ValidateSet('Requirement', 'Detection')]
        [string]$Purpose
    )
    [System.Version]$version1 = ConvertTo-PMPVersion($CurrentVersion)
    [System.Version]$version2 = ConvertTo-PMPVersion($TargetVersion)
    switch ($Purpose) {
        Requirement {
            $Result = $version1.CompareTo($version2) -lt 0}
        Detection {
            $Result = $version1.CompareTo($version2) -ge 0}}
    Write-Verbose "Result of comparing Current Version $CurrentVersion to Target Version $TargetVersion for the purpose of $Purpose rule = $Result"
    return $Result}
Function Get-PMPInstalledSoftwares {
    param(
        [ValidateSet('Both', 'x86', 'x64')]
        [string]$Architecture,
        [ValidateSet('HKLM', 'HKCU')]
        [string[]]$HivesToSearch
    )
    $PathsToSearch = switch -regex ($Architecture) {
        'Both|x86' {
            if (-not ([IntPtr]::Size -eq 4)) {'Software\Wow6432Node\Microsoft\Windows\CurrentVersion\Uninstall\*'}
            else {'Software\Microsoft\Windows\CurrentVersion\Uninstall\*'}}
        'Both|x64' {
            if (-not ([IntPtr]::Size -eq 4)) {'Software\Microsoft\Windows\CurrentVersion\Uninstall\*'}}}
    $FullPaths = foreach ($PathFragment in $PathsToSearch) {
        switch ($HivesToSearch) {
            'HKLM' {
                [string]::Format('registry::HKEY_LOCAL_MACHINE\{0}', $PathFragment)}
            'HKCU' {
                [string]::Format('registry::HKEY_CURRENT_USER\{0}', $PathFragment)}}}
    Write-Verbose "Will search the following registry paths based on [Architecture = $Architecture] [HivesToSearch = $HivesToSearch]"
    foreach ($RegPath in $FullPaths) {Write-Verbose $RegPath}
    $propertyNames = 'DisplayName', 'DisplayVersion', 'PSChildName', 'Publisher', 'InstallDate', 'SystemComponent'
    $AllFoundObjects = Get-ItemProperty -Path $FullPaths -Name $propertyNames -ErrorAction SilentlyContinue
    foreach ($Result in $AllFoundObjects) {
        if (-not [string]::IsNullOrEmpty($Result.DisplayName)) {$Result | Select-Object -Property $propertyNames}}}
function Test-PMPInstallerType {
    param(
        [Parameter(Mandatory = $true)]
        [string]$KeyName,
        [ValidateSet('EXE', 'MSI', 'ANY')]
        [string]$InstallerType = 'ANY'
    )
    switch ($InstallerType) {
        MSI {
            return $KeyName -as [guid] -is [guid]
        }
        EXE {
            return -not ($KeyName -as [guid] -is [guid])
        }
        ANY {
            return $true
        }}}
function Test-PMPRegKeyAction {
    param(
        [Parameter(Mandatory = $true)]
        [hashtable]$RegKeyDetection
    )
    foreach ($RegKey in $RegKeyDetection.GetEnumerator()) {
        $InitialKey = $RegKey.Key.Keys
        $InitialKeyString = $InitialKey | Out-String
        $PropertyToCheck = $RegKey.Key[$InitialKey]
        $ExpectedValue = $RegKey.Value.Value
        $WOW6432Node = $RegKey.Value.WOW6432Node
        $Operator = $RegKey.Value.Operator
        switch ($WOW6432Node) {
            $true {
                if ($InitialKeyString.StartsWith('SOFTWARE\', [StringComparison]::OrdinalIgnoreCase)) {
                    $resolvedPath = [string]::Concat('registry::HKEY_LOCAL_MACHINE\',
                        "$(if([IntPtr]::Size-eq4){'SOFTWARE'}else{'SOFTWARE\wow6432node'})",
                        $InitialKeyString.Substring(8))
                } else {$resolvedPath = [string]::Concat('registry::HKEY_LOCAL_MACHINE\', $InitialKey)}}
            $false {$resolvedPath = [string]::Concat('registry::HKEY_LOCAL_MACHINE\', $InitialKey)}}
        if (-not [scriptblock]::Create("'$((Get-ItemProperty -Path $resolvedPath.Trim() -Name $PropertyToCheck -ErrorAction SilentlyContinue).$PropertyToCheck)' $Operator '$ExpectedValue'").Invoke()) {return $false}}return $true}
Function Test-PMPAppMeetsCondition {
    param(
        [string]$ApplicationName,
        [string]$RegexSearchPattern,
        [string]$ApplicationNameExclusion,
        [string]$ApplicationVersion,
        [string]$ApplicationVersionFilter,
        [string]$MSIProductCode,
        [ValidateSet('Both', 'x86', 'x64')]
        [string]$Architecture,
        [ValidateSet('Requirement', 'Detection')]
        [string]$Purpose,
        [ValidateSet('HKLM', 'HKCU')]
        [string[]]$HivesToSearch,
        [ValidateSet('EXE', 'MSI', 'ANY')]
        [string]$InstallerType = 'Msi',
        [hashtable]$RegKeyDetection = @{},
        [ValidateRange(-1, 1)]
        [int]$SystemComponent = -1
    )
    $AllInstalledSoftware = Get-PMPInstalledSoftwares -Architecture $Architecture -HivesToSearch $HivesToSearch
    $MatchingInstalledSoftware = foreach ($InstalledSoftware in $AllInstalledSoftware) {
        if ([string]::IsNullOrEmpty($InstalledSoftware.DisplayVersion)) {$DisplayVersion = $InstalledSoftware.DisplayVersion}
        else {$DisplayVersion = Get-PMPVersionFromString -stringVar $InstalledSoftware.DisplayVersion.ToString()}
        $version = Get-PMPVersionFromString -stringVar $InstalledSoftware.DisplayName
        if (-not [string]::IsNullOrEmpty($ApplicationNameExclusion) -and $InstalledSoftware.DisplayName -like $ApplicationNameExclusion) {Write-CCMLogEntry -Message "Ignoring $($InstalledSoftware.DisplayName) because it matches our exclusion name $ApplicationNameExclusion" @LogParams -Severity 2;continue}
        elseif ($InstalledSoftware.PSChildname -eq $MSIProductCode -and (Test-PMPInstallerType -KeyName $InstalledSoftware.PSChildname -InstallerType $InstallerType)) {
            if ($DisplayVersion -notlike $ApplicationVersionFilter) {
                Write-CCMLogEntry -Message "Ignoring the product $($InstalledSoftware.DisplayName) matching based on MSIProductCode $MSIProductCode. It does not match the ApplicationVersionFilter of $ApplicationVersionFilter" @LogParams -Severity 2}
            else {
                if ($RegKeyDetection.Keys.Count -gt 0) {
                    if (Test-PMPRegKeyAction -RegKeyDetection $RegKeyDetection) {
                        if ($SystemComponent -eq -1 -or [int]$InstalledSoftware.SystemComponent -eq $SystemComponent) {
                            Write-Verbose "Found $($InstalledSoftware.DisplayName) matching based on MSIProductCode $MSIProductCode"
                            $InstalledSoftware}
                        else {Write-CCMLogEntry -Message "Ignoring the product $($InstalledSoftware.DisplayName) with product code $MSIProductCode because we expected a SystemComponent value of $SystemComponent but the actual value is $([int]$InstalledSoftware.SystemComponent)" @LogParams -Severity 2}}
                    else {Write-CCMLogEntry -Message "Ignoring the product $($InstalledSoftware.DisplayName) with product code $MSIProductCode because a provided RegKeyDetection did not pass" @LogParams -Severity 2}}
                else {Write-Verbose "Found $($InstalledSoftware.DisplayName) matching based on MSIProductCode $MSIProductCode";$InstalledSoftware}}}
        elseif ($InstalledSoftware.DisplayName -like $ApplicationName -or ($InstalledSoftware.DisplayName -match $RegexSearchPattern -and $RegexSearchPattern -ne '')) {
            if (Test-PMPInstallerType -KeyName $InstalledSoftware.PSChildname -InstallerType $InstallerType) {
                if ($null -ne $InstalledSoftware.DisplayVersion -and ((Compare-PMPVersion -CurrentVersion $DisplayVersion -TargetVersion $ApplicationVersion -Purpose $Purpose) -or ($null -eq $InstalledSoftware.DisplayVersion -and (Compare-PMPVersion -CurrentVersion $version -TargetVersion $ApplicationVersion -Purpose $Purpose)))) {
                    if ($DisplayVersion -notlike $ApplicationVersionFilter) {
                        Write-CCMLogEntry -Message "Ignoring the product $($InstalledSoftware.DisplayName) matching based on ApplicationName $ApplicationName and Version $version. It does not match the ApplicationVersionFilter of $ApplicationVersionFilter" @LogParams -Severity 2}
                    else {
                        if ($RegKeyDetection.Keys.Count -gt 0) {
                            if (Test-PMPRegKeyAction -RegKeyDetection $RegKeyDetection) {
                                if ($SystemComponent -eq -1 -or [int]$InstalledSoftware.SystemComponent -eq $SystemComponent) {
                                    Write-Verbose "Found $($InstalledSoftware.DisplayName) matching based on ApplicationName $ApplicationName and Version $version"
                                    $InstalledSoftware}
                                else {Write-CCMLogEntry -Message "Ignoring the product $($InstalledSoftware.DisplayName) because we expected a SystemComponent value of $SystemComponent but the actual value is $([int]$InstalledSoftware.SystemComponent)" @LogParams -Severity 2}}
                            else {Write-CCMLogEntry -Message "Ignoring the product $($InstalledSoftware.DisplayName) because a provided RegKeyDetection did not pass" @LogParams -Severity 2}}
                        else {
                            if ($SystemComponent -eq -1 -or [int]$InstalledSoftware.SystemComponent -eq $SystemComponent) {
                                Write-Verbose "Found $($InstalledSoftware.DisplayName) matching based on ApplicationName $ApplicationName and Version $version"
                                $InstalledSoftware}
                            else {Write-CCMLogEntry -Message "Ignoring the product $($InstalledSoftware.DisplayName) because we expected a SystemComponent value of $SystemComponent but the actual value is $([int]$InstalledSoftware.SystemComponent)" @LogParams -Severity 2}}}}}
            else {Write-CCMLogEntry -Message "Ignoring the product $($InstalledSoftware.DisplayName) because the key name [$($InstalledSoftware.PSChildName)] does not meet the installer type condition [Installer Type: $InstallerType]" @LogParams -Severity 3}}}
    If ($null -eq $MatchingInstalledSoftware) {
        Write-CCMLogEntry -Message "No valid software found for $($ApplicationName) with version $($ApplicationVersion) meeting $Purpose rules" @LogParams -Severity 2
        Return $false}
    Else {
        foreach ($Software in $MatchingInstalledSoftware) {Write-CCMLogEntry -Message "Found $($Software.DisplayName) version $($Software.DisplayVersion) installed on $($Software.InstallDate)" @LogParams}
        Return $true}}
$LogParams = @{
    FileName       = $LogFileName
    Folder         = Get-PMPLogPath
    Bias           = [System.DateTimeOffset]::Now.Offset.TotalMinutes
    MaxLogFileSize = 2mb
    LogsToKeep     = 1
}
$WriteVerboseMetadata = New-Object System.Management.Automation.CommandMetadata (Get-Command Write-Verbose)
$WriteVerboseBinding = [System.Management.Automation.ProxyCommand]::GetCmdletBindingAttribute($WriteVerboseMetadata)
$WriteVerboseParams = [System.Management.Automation.ProxyCommand]::GetParamBlock($WriteVerboseMetadata)
$WriteVerboseWrapped = { Microsoft.PowerShell.Utility\Write-Verbose @PSBoundParameters; switch ($VerbosePreference) {'Continue' {Write-CCMLogEntry -Message $Message @LogParams}}}
${Function:Write-Verbose} = [string]::Format('{0}param({1}) {2}', $WriteVerboseBinding, $WriteVerboseParams, $WriteVerboseWrapped)
Write-CCMLogEntry -Message "*** Starting $Purpose script for $AppToSearch $(if(-not [string]::IsNullOrEmpty($AppToAvoid)) {"except $AppToAvoid"}) with version $ApplicationVersionToSearch" @LogParams
Write-CCMLogEntry -Message "$Purpose script version $ScriptVersion" @LogParams
Write-CCMLogEntry -Message "Running as $env:username $(if(Test-IsRunningAsAdministrator) {'[Administrator]'} Else {'[Not Administrator]'}) on $env:computername" @LogParams
$TestInstalledSplat = @{
    ApplicationName          = $AppToSearch
    RegexSearchPattern       = $RegexAppToSearch
    ApplicationNameExclusion = $AppToAvoid
    ApplicationVersion       = $ApplicationVersionToSearch
    MSIProductCode           = $AppMSICodeToSearch
    Architecture             = $Architecture
    Purpose                  = $Purpose
    HivesToSearch            = $HivesToSearch
    ApplicationVersionFilter = $ApplicationVersionFilter
    InstallerType            = $InstallerType
    RegKeyDetection          = $RegKeyDetection
    SystemComponent          = $SystemComponent
}
$detectionResult = Test-PMPAppMeetsCondition @TestInstalledSplat
if ($detectionResult) {
$Result = switch ($Purpose) {
        Detection {Write-Output 'Installed'}
        Requirement {Write-Output 'Applicable'}}
    Write-CCMLogEntry -Message "Result of script for checking $Purpose`: $Result" @LogParams
    Write-Output $Result}
Write-CCMLogEntry -Message "*** Ending $Purpose script for $AppToSearch $(if(-not [string]::IsNullOrEmpty($AppToAvoid)) {"except $AppToAvoid"}) with version $ApplicationVersionToSearch" @LogParams
Exit 0