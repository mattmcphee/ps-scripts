function Get-WindowsUpdateDiagnosticReport {
    [CmdletBinding()]
    param (
        # Days - how many days to go back searching
        [Parameter(Mandatory = $false)]
        [int]$Days = 30,

        # how many events to return from event log
        [Parameter(Mandatory = $false)]
        [int]$EventCount = 50,

        # where to save the json report
        [Parameter(Mandatory = $false)]
        [string]$OutputPath,

        # skip searching windows update
        [Parameter(Mandatory = $false)]
        [switch]$SkipUpdateSearch
    )

    $ErrorActionPreference = 'Stop'
    $since = (Get-Date).AddDays(-$Days)

    # -------------------------------------------------------------------------
    # Basic machine information
    # -------------------------------------------------------------------------

    $OS = Get-CimInstance Win32_OperatingSystem

    $WindowsVersion = Get-RegistrySnapshot 'HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion'

    $SystemDrive = Get-CimInstance Win32_LogicalDisk -Filter "DeviceID='C:'"

    $IsAdmin = (
        New-Object Security.Principal.WindowsPrincipal(
            [Security.Principal.WindowsIdentity]::GetCurrent()
        )
    ).IsInRole(
        [Security.Principal.WindowsBuiltInRole]::Administrator
    )

    $BasicInfo = [PSCustomObject]@{
        ComputerName       = $env:COMPUTERNAME
        Generated          = Get-Date
        IsAdministrator    = $IsAdmin
        OS                 = $WindowsVersion.ProductName
        DisplayVersion     = $WindowsVersion.DisplayVersion
        Build              = "$($WindowsVersion.CurrentBuild).$($WindowsVersion.UBR)"
        Architecture       = $OS.OSArchitecture
        LastBoot           = $OS.LastBootUpTime
        UptimeDays         = [Math]::Round(
            ((Get-Date) - $OS.LastBootUpTime).TotalDays,
            1
        )
        SystemDriveFreeGB  = [Math]::Round($SystemDrive.FreeSpace / 1GB, 2)
        SystemDriveSizeGB  = [Math]::Round($SystemDrive.Size / 1GB, 2)
        PowerShellVersion  = $PSVersionTable.PSVersion.ToString()
    }

    # -------------------------------------------------------------------------
    # Windows Update related services
    # -------------------------------------------------------------------------

    $serviceNames = @(
        'wuauserv',
        'bits',
        'UsoSvc',
        'WaaSMedicSvc',
        'cryptsvc'
    )

    $services = foreach ($serviceName in $serviceNames) {
        try {
            $Service = Get-CimInstance Win32_Service `
                -Filter "Name='$serviceName'" `
                -ErrorAction Stop

            [PSCustomObject]@{
                Name      = $Service.Name
                State     = $Service.State
                StartMode = $Service.StartMode
                StartName = $Service.StartName
            }
        } catch {
            [PSCustomObject]@{
                Name      = $serviceName
                State     = 'Not found'
                StartMode = $null
                StartName = $null
            }
        }
    }

    # -------------------------------------------------------------------------
    # Windows Update / Intune / Group Policy
    # -------------------------------------------------------------------------

    $WUConfiguredPolicy = Get-RegistrySnapshot 'HKLM:\SOFTWARE\Policies\Microsoft\Windows\WindowsUpdate'
    $AUConfiguredPolicy = Get-RegistrySnapshot 'HKLM:\SOFTWARE\Policies\Microsoft\Windows\WindowsUpdate\AU'
    $UpdatePolicyStatus = Get-RegistrySnapshot 'HKLM:\SOFTWARE\Microsoft\WindowsUpdate\UpdatePolicy\Settings'
    $MDMEffectivePolicy = Get-RegistrySnapshot 'HKLM:\SOFTWARE\Microsoft\PolicyManager\current\device\Update'

    $Policies = [PSCustomObject]@{
        WindowsUpdatePolicy = $WUConfiguredPolicy
        AutomaticUpdates    = $AUConfiguredPolicy
        UpdatePolicyStatus  = $UpdatePolicyStatus
        MDMEffectivePolicy  = $MDMEffectivePolicy
    }

    # -------------------------------------------------------------------------
    # Pending reboot
    # -------------------------------------------------------------------------

    $CBSRebootPending = Test-Path 'HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Component Based Servicing\RebootPending'
    $WURebootPending = Test-Path 'HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\WindowsUpdate\Auto Update\RebootRequired'
    $PendingFileRename = $false

    try {
        $RenameValue = Get-RegistrySnapshot 'HKLM:\SYSTEM\CurrentControlSet\Control\Session Manager' |
            Get-RegistrySnapshotValue -Name PendingFileRenameOperations

        if ($null -ne $RenameValue.PendingFileRenameOperations) {
            $PendingFileRename = $true
        }
    } catch {
        Write-Verbose "Unable to read PendingFileRenameOperations: $($_.Exception.Message)"
    }

    $ConfigMgrRebootPending = $null

    try {
        $CCMReboot = Invoke-CimMethod `
            -Namespace 'root\ccm\ClientSDK' `
            -ClassName 'CCM_ClientUtilities' `
            -MethodName 'DetermineIfRebootPending' `
            -ErrorAction Stop

        $ConfigMgrRebootPending = $CCMReboot.RebootPending
    } catch {
        # Expected on machines without the ConfigMgr client
        Write-Verbose "ConfigMgr reboot state unavailable: $($_.Exception.Message)"
    }

    $PendingReboot = [PSCustomObject]@{
        CBS                    = $CBSRebootPending
        WindowsUpdate          = $WURebootPending
        PendingFileRename      = $PendingFileRename
        ConfigMgr              = $ConfigMgrRebootPending
        AnyPendingReboot       = (
            $CBSRebootPending -or
            $WURebootPending -or
            $PendingFileRename -or
            $ConfigMgrRebootPending
        )
    }

    # -------------------------------------------------------------------------
    # Windows Update Agent history
    # -------------------------------------------------------------------------

    $UpdateHistory = @()
    $UpdateHistoryError = $null
    $Searcher = $null

    try {
        $Session = New-Object -ComObject Microsoft.Update.Session
        $Searcher = $Session.CreateUpdateSearcher()
        $HistoryCount = $Searcher.GetTotalHistoryCount()

        if ($HistoryCount -gt 0) {
            $QueryCount = [Math]::Min($HistoryCount, 300)
            $RawHistory = $Searcher.QueryHistory(0, $QueryCount)

            $ResultCodes = @{
                0 = 'NotStarted'
                1 = 'InProgress'
                2 = 'Succeeded'
                3 = 'SucceededWithErrors'
                4 = 'Failed'
                5 = 'Aborted'
            }

            $OperationCodes = @{
                1 = 'Installation'
                2 = 'Uninstallation'
                3 = 'Other'
            }

            $UpdateHistory = @(
                foreach ($Entry in $RawHistory) {
                    if ($Entry.Date -lt $since) {
                        continue
                    }

                    [PSCustomObject]@{
                        Date       = $Entry.Date
                        Title      = $Entry.Title
                        Operation  = $OperationCodes[[int]$Entry.Operation]
                        Result     = $ResultCodes[[int]$Entry.ResultCode]
                        HResult    = ConvertTo-HexHResult $Entry.HResult
                        UpdateID   = $Entry.UpdateIdentity.UpdateID
                        Revision   = $Entry.UpdateIdentity.RevisionNumber
                    }
                }
            )
        }
    } catch {
        $UpdateHistoryError = $_.Exception.Message
    }

    # -------------------------------------------------------------------------
    # Currently applicable / pending updates
    #
    # This performs a WUA search against the update source configured for
    # the machine. Use -SkipUpdateSearch if you only want passive collection.
    # -------------------------------------------------------------------------

    $PendingUpdates = @()
    $UpdateSearchError = $null

    if (-not $SkipUpdateSearch) {
        try {
            if ($null -eq $Searcher) {
                $Session = New-Object -ComObject Microsoft.Update.Session
                $Searcher = $Session.CreateUpdateSearcher()
            }

            $SearchResult = $Searcher.Search(
                'IsInstalled=0 and IsHidden=0'
            )

            $PendingUpdates = @(
                for ($i = 0; $i -lt $SearchResult.Updates.Count; $i++) {
                    $Update = $SearchResult.Updates.Item($i)
                    $Categories = @()

                    for (
                        $CategoryIndex = 0;
                        $CategoryIndex -lt $Update.Categories.Count;
                        $CategoryIndex++
                    ) {
                        $Categories += $Update.Categories.Item($CategoryIndex).Name
                    }

                    $KBs = @()

                    foreach ($KB in $Update.KBArticleIDs) {
                        $KBs += "KB$KB"
                    }

                    [PSCustomObject]@{
                        Title          = $Update.Title
                        KB             = $KBs -join ', '
                        Categories     = $Categories -join ', '
                        Severity       = $Update.MsrcSeverity
                        IsDownloaded   = $Update.IsDownloaded
                        RebootRequired = $Update.RebootRequired
                    }
                }
            )
        } catch {
            $UpdateSearchError = $_.Exception.Message
        }
    }

    # -------------------------------------------------------------------------
    # Windows Update errors / warnings from event log
    # -------------------------------------------------------------------------

    $WindowsUpdateEvents = @()
    $WindowsUpdateEventError = $null

    try {
        $WindowsUpdateEvents = @(
            Get-WinEvent -FilterHashtable @{
                LogName   = 'Microsoft-Windows-WindowsUpdateClient/Operational'
                StartTime = $since
                Level     = 2, 3
            } -ErrorAction Stop |
            Select-Object -First $EventCount |
            ForEach-Object {
                [PSCustomObject]@{
                    TimeCreated = $_.TimeCreated
                    EventID     = $_.Id
                    Level       = $_.LevelDisplayName
                    Message     = $_.Message
                }
            }
        )
    } catch {
        if ($_.FullyQualifiedErrorId -notlike 'NoMatchingEventsFound*') {
            $WindowsUpdateEventError = $_.Exception.Message
        }
    }

    # -------------------------------------------------------------------------
    # Recent installed hotfixes
    # -------------------------------------------------------------------------

    $RecentHotFixes = @()

    try {
        $RecentHotFixes = @(
            Get-HotFix |
            Where-Object InstalledOn |
            Sort-Object InstalledOn -Descending |
            Select-Object -First 15 `
                HotFixID,
                Description,
                InstalledOn
        )
    } catch {
        Write-Warning "Unable to query installed hotfixes: $($_.Exception.Message)"
    }

    # -------------------------------------------------------------------------
    # Update related scheduled tasks
    # -------------------------------------------------------------------------

    $UpdateScheduledTasks = @()

    try {
        $UpdateScheduledTasks = @(
            Get-ScheduledTask `
                -TaskPath '\Microsoft\Windows\UpdateOrchestrator\' `
                -ErrorAction SilentlyContinue

            Get-ScheduledTask `
                -TaskPath '\Microsoft\Windows\WindowsUpdate\' `
                -ErrorAction SilentlyContinue
        ) |
        Select-Object TaskName, TaskPath, State
    } catch {
        Write-Warning "Unable to query update scheduled tasks: $($_.Exception.Message)"
    }

    # -------------------------------------------------------------------------
    # Proxy / time configuration
    # -------------------------------------------------------------------------

    try {
        $WinHTTPProxy = (
            & netsh winhttp show proxy 2>&1 |
                Out-String
        ).Trim()
    } catch {
        $WinHTTPProxy = "Unable to query WinHTTP proxy: $($_.Exception.Message)"
    }

    try {
        $TimeStatus = (
            & w32tm /query /status 2>&1 |
                Out-String
        ).Trim()
    } catch {
        $TimeStatus = "Unable to query time service: $($_.Exception.Message)"
    }

    # -------------------------------------------------------------------------
    # Build basic "things worth investigating" summary
    # -------------------------------------------------------------------------

    $LikelyIssues = @()

    if (-not $IsAdmin) {
        $LikelyIssues += 'Script was not run elevated. Some diagnostic information may be unavailable.'
    }

    if ($BasicInfo.SystemDriveFreeGB -lt 15) {
        $LikelyIssues += "System drive has only $($BasicInfo.SystemDriveFreeGB) GB free. Low disk space can interfere with servicing."
    }

    $DisabledServices = @(
        $services |
            Where-Object StartMode -eq 'Disabled'
    )

    foreach ($Service in $DisabledServices) {
        $LikelyIssues += "Windows Update related service '$($Service.Name)' is disabled."
    }

    if ($PendingReboot.AnyPendingReboot) {
        $LikelyIssues += 'The machine has a pending reboot.'
    }

    # Windows Update disabled
    $NoAutoUpdate = Get-RegistrySnapshotValue -Snapshot $AUConfiguredPolicy -Name 'NoAutoUpdate'

    if ($NoAutoUpdate -eq 1) {
        $LikelyIssues += 'NoAutoUpdate policy is enabled.'
    }

    # Windows Update UI/access disabled
    $DisableWUAccess = Get-RegistrySnapshotValue -Snapshot $WUConfiguredPolicy -Name 'DisableWindowsUpdateAccess'

    if ($DisableWUAccess -eq 1) {
        $LikelyIssues += 'DisableWindowsUpdateAccess policy is enabled.'
    }

    # Quality update pause
    $PausedQualityStatus = Get-RegistrySnapshotValue -Snapshot $UpdatePolicyStatus -Name 'PausedQualityStatus'
    $ConfiguredQualityPause = Get-RegistrySnapshotValue -Snapshot $WUConfiguredPolicy -Name 'PauseQualityUpdates'

    if (
        ($PausedQualityStatus -eq 1) -or
        ($ConfiguredQualityPause -eq 1)
    ) {
        $LikelyIssues += 'Quality updates appear to be paused.'
    }

    # Quality update deferral
    $QualityDeferral = Get-RegistrySnapshotValue -Snapshot $WUConfiguredPolicy -Name 'DeferQualityUpdatesPeriodInDays'
    if (-not($QualityDeferral -is [int])) { $QualityDeferral = 0 }
    if ($QualityDeferral -gt 0) {
        $LikelyIssues += "Quality updates are configured to be deferred by $QualityDeferral day(s)."
    }

    # WSUS / SUP configuration
    $UseWUServer = Get-RegistrySnapshotValue -Snapshot $AUConfiguredPolicy -Name 'UseWUServer'
    $WUServer = Get-RegistrySnapshotValue -Snapshot $WUConfiguredPolicy -Name 'WUServer'

    if (($UseWUServer -eq 1) -and (-not $WUServer)) {
        $LikelyIssues += 'UseWUServer is enabled but no WUServer value was found.'
    }

    # WUA search failure
    if ($UpdateSearchError) {
        $LikelyIssues += "Windows Update Agent search failed: $UpdateSearchError"
    }

    # Recent update installation failures
    $RecentFailures = @(
        $UpdateHistory |
        Where-Object {
            $_.Result -in @(
                'Failed',
                'Aborted',
                'SucceededWithErrors'
            )
        }
    )

    if ($RecentFailures.Count -gt 0) {
        $LikelyIssues += "$($RecentFailures.Count) unsuccessful or partially successful Windows Update history entries were found in the last $Days days."
    }

    # No recent successful installs
    $LatestSuccessfulUpdate = $UpdateHistory |
        Where-Object {
            $_.Operation -eq 'Installation' -and
            $_.Result -eq 'Succeeded'
        } |
        Sort-Object Date -Descending |
        Select-Object -First 1

    if (-not $LatestSuccessfulUpdate) {
        $LikelyIssues += "No successful Windows Update installation was found in the last $Days days."
    }

    # Event log problems
    if ($WindowsUpdateEvents.Count -gt 0) {
        $LikelyIssues += "$($WindowsUpdateEvents.Count) Windows Update warning/error event(s) were found in the last $Days days."
    }

    # -------------------------------------------------------------------------
    # Final report
    # -------------------------------------------------------------------------

    $Report = [PSCustomObject]@{
        Summary = [PSCustomObject]@{
            ComputerName            = $BasicInfo.ComputerName
            WindowsVersion          = $BasicInfo.DisplayVersion
            Build                   = $BasicInfo.Build
            LastBoot                = $BasicInfo.LastBoot
            UptimeDays              = $BasicInfo.UptimeDays
            FreeSpaceGB             = $BasicInfo.SystemDriveFreeGB
            PendingReboot           = $PendingReboot.AnyPendingReboot
            PendingUpdateCount      = $PendingUpdates.Count
            RecentFailureCount      = $RecentFailures.Count
            LatestSuccessfulUpdate  = $LatestSuccessfulUpdate
            UsesWSUS                = ($UseWUServer -eq 1)
            WUServer                = $WUServer
        }

        LikelyIssues              = $LikelyIssues
        Computer                  = $BasicInfo
        Services                  = $services
        PendingReboot             = $PendingReboot
        Policies                  = $Policies
        PendingUpdates            = $PendingUpdates
        UpdateSearchError         = $UpdateSearchError
        UpdateHistory             = $UpdateHistory
        UpdateHistoryError        = $UpdateHistoryError
        WindowsUpdateEvents       = $WindowsUpdateEvents
        WindowsUpdateEventError   = $WindowsUpdateEventError
        RecentHotFixes            = $RecentHotFixes
        ConfigMgr                 = $ConfigMgr
        UpdateScheduledTasks      = $UpdateScheduledTasks
        WinHTTPProxy              = $WinHTTPProxy
        TimeService               = $TimeStatus
    }

    # -------------------------------------------------------------------------
    # Optional JSON export
    # -------------------------------------------------------------------------

    if ($OutputPath) {
        $Parent = Split-Path $OutputPath -Parent

        if ($Parent -and -not (Test-Path $Parent)) {
            New-Item `
                -Path $Parent `
                -ItemType Directory `
                -Force |
                Out-Null
        }

        $Report |
            ConvertTo-Json -Depth 8 |
            Set-Content `
                -Path $OutputPath `
                -Encoding UTF8

        Write-Verbose "Report written to $OutputPath"
    }

    return $Report
}
