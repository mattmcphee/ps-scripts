function Get-WDACPolicyRefreshEventFilter {
    <#
    .SYNOPSIS
    Returns a filter to use to get only events that occured since last policy
    refresh
    .DESCRIPTION
    Get-WDACPolicyRefreshEventFilter retrieves the latest
    Microsoft-Windows-CodeIntegrity/Operational policy refresh event (id 3099)
    and generates a string to insert in "FilterXPath" filters to only search for
    events generated after the latest policy refresh
    .EXAMPLE
    Get-WDACPolicyRefreshEventFilter
    Looks for the latest policy refresh event and returns a filter string such
    as " and TimeCreated[@SystemTime >= '2020-10-05T08:11:22.7969367+02:00']"
    #>
    [CmdletBinding()]
    param()
    # Only consider failed audit events that occured after the last CI policy
    # update (event ID 3099)
    $LastPolicyUpdateEvent = Get-WinEvent -FilterHashtable @{ 
        LogName = 'Microsoft-Windows-CodeIntegrity/Operational'
        Id      = 3099 
    } -MaxEvents 1 -ErrorAction Ignore
    # Sometimes this event will not be present - e.g. if the log rolled since
    # the last update.
    if ($LastPolicyUpdateEvent) {
        $DateTimeAfter = [Xml.XmlConvert]::ToString(
            $LastPolicyUpdateEvent.TimeCreated.ToUniversalTime(), 'O'
        )
        " and TimeCreated[@SystemTime >= '$DateTimeAfter']"
    } else {
        Write-Verbose "No policy update event was present in the event log. Ignoring the -SinceLastPolicyRefresh switch."
        ''
    }
}

function Get-WinEventData {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [Diagnostics.Eventing.Reader.EventLogRecord] $EventRecord
    )

    process {
        $Provider = $Providers[$EventRecord.ProviderName]

        if ($Provider.Events.Id -contains $EventRecord.Id) {
            $EventTemplateName = $EventRecord.ProviderName, $EventRecord.Id, $EventRecord.Version -join '_'

            if (-not $EventTemplates[$EventTemplateName]) {
                $EventTemplates[$EventTemplateName] = ($Provider.Events | Where-Object { $_.Id -eq $EventRecord.Id -and $_.Version -eq $EventRecord.Version }).Template
            }

            [Xml] $XmlTemplate = $EventTemplates[$EventTemplateName]

            $EventData = @{}

            for ($i = 0; $i -lt $EventRecord.Properties.Count; $i++) {
                $Name = $XmlTemplate.template.data.name[$i] -replace ' ', ''
                $Value = $EventRecord.Properties[$i].Value

                $EventData[$Name] = $Value
            }

            $EventData
        }
        else {
            $EventRecord.Properties.Value
        }
    }
}

function Get-CodeIntegrityEvent {
    <#
    .SYNOPSIS
    Returns code integrity event log audit/enforcement events in a more
    human-readable fashion.
    .DESCRIPTION
    Get-WDACCodeIntegrityEvent retrieves and parses
    Microsoft-Windows-CodeIntegrity/Operational PE audit and enforcement events
    into a format that is more human-readable. This function is designed to
    facilitate regular code integrity policy baselining.
    Author: Matthew Graeber
    License: BSD 3-Clause
    .PARAMETER User
    Specifies that only user-mode events should be returned. If neither -User
    nor -Kernel is specified, user and kernel events are returned.
    .PARAMETER Kernel
    Specifies that only kernel-mode events should be returned. If neither -User
    nor -Kernel is specified, user and kernel events are returned.
    .PARAMETER Audit
    Specifies that only audit events (event ID 3076) should be returned. If
    neither -Audit nor -Enforce is specified, audit and enforcement events are
    returned.
    .PARAMETER Enforce
    Specifies that only enforcement events (event ID 3077) should be returned.
    If neither -Audit nor -Enforce is specified, audit and enforcement events
    are returned.
    .PARAMETER SinceLastPolicyRefresh
    Specifies that events should only be returned since the last time the code
    integrity policy was refreshed. This option is useful for baselining
    purposes.
    .PARAMETER SignerInformation
    Specifies that correlated signer information should be collected. Note: When
    there are many CodeIntegrity events present in the event log, collection of
    signature events can be time consuming.
    .PARAMETER CheckWhqlStatus
    Specifies that correlated WHQL events should be collected. Supplying this
    switch will populate the returned FailedWHQL property.
    .PARAMETER IgnoreNativeImagesDLLs
    Specifies that events where ResolvedFilePath is like
    "$env:SystemRoot\assembly\NativeImages*.dll" should be skipped. Useful to
    suppress events caused by auto-generated "NativeImages DLLs"
    .PARAMETER IgnoreDenyEvents
    Specifies that only events will be returned that are not explicitly blocked
    by policy. This switch only works when -SignerInformation is also specified.
    This switch is available to help reduce noise and prevent inadvertantly
    creating allow rules for explicitly denied executables.
    .PARAMETER MaxEvents
    Specifies the maximum number of events that Get-WDACCodeIntegrityEvent
    returns. The default is to return all the events.
    .EXAMPLE
    Get-WDACCodeIntegrityEvent -SinceLastPolicyRefresh
    Return all code integrity events (user/kernel/audit/enforcement) since the
    last code intgrity policy refresh.
    .EXAMPLE
    Get-WDACCodeIntegrityEvent -User -SinceLastPolicyRefresh
    Return all user-mode code integrity events (audit/enforcement) since the
    last code intgrity policy refresh.
    .EXAMPLE
    Get-WDACCodeIntegrityEvent -Kernel -MaxEvents 5
    Return the most recent 5 kernel mode code integrity events.
    .EXAMPLE
    Get-WDACCodeIntegrityEvent -Kernel -Enforce
    Return all kernel mode enforcement events.
    #>
    [CmdletBinding(DefaultParameterSetName = 'NoSignerCheck')]
    param (
        # specifies only usermode events should be returned
        [Parameter(ParameterSetName = 'NoSignerCheck')]
        [Parameter(ParameterSetName = 'SignerCheck')]
        [Switch]
        $User,
        # specifies only kernel mode events should be returned
        [Parameter(ParameterSetName = 'NoSignerCheck')]
        [Parameter(ParameterSetName = 'SignerCheck')]
        [Switch]
        $Kernel,
        # specifies only audit events should be returned
        [Parameter(ParameterSetName = 'NoSignerCheck')]
        [Parameter(ParameterSetName = 'SignerCheck')]
        [Switch]
        $Audit,
        # specifies only enforcement events should be returned
        [Parameter(ParameterSetName = 'NoSignerCheck')]
        [Parameter(ParameterSetName = 'SignerCheck')]
        [Switch]
        $Enforce,
        # only return events generated since last policy refresh
        [Parameter(ParameterSetName = 'NoSignerCheck')]
        [Parameter(ParameterSetName = 'SignerCheck')]
        [Switch]
        $SinceLastPolicyRefresh,
        # forces inclusion of signer info (high performance impact)
        [Parameter(Mandatory, ParameterSetName = 'SignerCheck')]
        [Switch]
        $SignerInformation,
        # forces inclusion of whql status info (high performance impact)
        [Parameter(ParameterSetName = 'NoSignerCheck')]
        [Parameter(ParameterSetName = 'SignerCheck')]
        [Switch]
        $CheckWhqlStatus,
        # ignores events about blocked dlls from native images
        [Parameter(ParameterSetName = 'NoSignerCheck')]
        [Parameter(ParameterSetName = 'SignerCheck')]
        [Switch]
        $IgnoreNativeImagesDLLs,
        # returns events that are not explicitly denied by policy
        # only takes effect if the SignerInformation switch is on
        [Parameter(ParameterSetName = 'SignerCheck')]
        [Switch]
        $IgnoreDenyEvents,
        # limits number of events returned to this value
        [Parameter(ParameterSetName = 'NoSignerCheck')]
        [Parameter(ParameterSetName = 'SignerCheck')]
        [Int64]
        $MaxEvents
    )

    # If neither -User nor -Kernel are supplied, do not filter based on signing scenario
    # If -User and -Kernel are supplied, do not filter based on signing scenario
    # Only filter in a mutually exclusive scenario.
    $ScenarioFilter = ''

    if ($User -and !$Kernel) {
        # 1 == A user-mode rule triggered
        $ScenarioFilter = " and EventData[Data[@Name='SI Signing Scenario'] = 1]"
    } elseif ($Kernel -and !$User) {
        # 2 == A kernel-mode rule triggered
        $ScenarioFilter = " and EventData[Data[@Name='SI Signing Scenario'] = 0]"
    }

    # If neither -Audit nor -Enforce are supplied, do not filter based on event ID
    # If -Audit and -Enforce are supplied, do not filter based on event ID
    # Only filter in a mutually exclusive scenario.
    $ModeFilter = '(EventID = 3076 or EventID = 3077)'

    if ($Audit -and !$Enforce) {
        # Event ID 3076 == an audit event
        $ModeFilter = "EventID = 3076"
    } elseif ($Enforce -and !$Audit) {
        # Event ID 3077 == an enforcement event
        $ModeFilter = "EventID = 3077"
    }

    $PolicyRefreshFilter = ''

    if ($SinceLastPolicyRefresh) {
        $PolicyRefreshFilter = Get-WDACPolicyRefreshEventFilter -Verbose:$False
    }

    $Filter = "*[System[$($ModeFilter)$($PolicyRefreshFilter)]$ScenarioFilter]"

    Write-Verbose "XPath Filter: $Filter"

    $EventIdMapping = @{
        3076 = 'Audit'
        3077 = 'Enforce'
    }

    $SigningScenarioMapping = @{
        [UInt32] 0 = 'Driver'
        [UInt32] 1 = 'UserMode'
    }

    $MaxEventArg = @{}

    # Pass -MaxEvents through to Get-WinEvent
    if ($MaxEvents) { $MaxEventArg = @{ MaxEvents = $MaxEvents } }

    Get-WinEvent -LogName 'Microsoft-Windows-CodeIntegrity/Operational' `
    -FilterXPath $Filter @MaxEventArg -ErrorAction Ignore | ForEach-Object {
        $EventData = Get-WinEventData -EventRecord $_

        $WHQLFailed = $null

        if ($CheckWhqlStatus) {
            $WHQLFailed = $False

            # A correlated 3082 event indicates that WHQL verification failed
            $WHQLEvent = Get-WinEvent `
            -LogName 'Microsoft-Windows-CodeIntegrity/Operational' `
            -FilterXPath "*[System[EventID = 3082 and Correlation[@ActivityID = '$($_.ActivityId.Guid)']]]" `
            -MaxEvents 1 `
            -ErrorAction Ignore

            if ($WHQLEvent) { $WHQLFailed = $True }
        }

        $ResolvedSigners = $null
        $ExplicitlyDeniedSigner = $False

        if ($SignerInformation) {
            # Retrieve correlated signer info (event ID 3089)
            # Note: there may be more than one correlated signer event in the case of the file having multiple signers.
            $Signer = Get-WinEvent -LogName 'Microsoft-Windows-CodeIntegrity/Operational' -FilterXPath "*[System[EventID = 3089 and Correlation[@ActivityID = '$($_.ActivityId.Guid)']]]" -MaxEvents 1 -ErrorAction Ignore

            if ($Signer -and $Signer.Properties -and ($Signer.Properties[0].Value -gt 1)) {
                $Signer = Get-WinEvent `
                -LogName 'Microsoft-Windows-CodeIntegrity/Operational' `
                -FilterXPath "*[System[EventID = 3089 and Correlation[@ActivityID = '$($_.ActivityId.Guid)']]]" `
                -MaxEvents ($Signer.Properties[0].Value) `
                -ErrorAction Ignore
            }

            $ResolvedSigners = $Signer | ForEach-Object {
                $SignerData = Get-WinEventData -EventRecord $_

                $SignatureType = $SignatureTypeMapping[$SignerData.SignatureType]

                $VerificationError = $VerificationErrorMapping[$SignerData.VerificationError]

                if ($IgnoreDenyEvents -and ($VerificationError -eq 'Explicitly denied by WDAC policy')) { $ExplicitlyDeniedSigner = $True }

                $Hash = $null
                if ($SignerData.Hash) { $Hash = [BitConverter]::ToString($SignerData.Hash).Replace('-','') }

                $PublisherTBSHash = $null
                if ($SignerData.PublisherTBSHash) { $PublisherTBSHash = [BitConverter]::ToString($SignerData.PublisherTBSHash).Replace('-','') }

                $IssuerTBSHash = $null
                if ($SignerData.IssuerTBSHash) { $IssuerTBSHash = [BitConverter]::ToString($SignerData.IssuerTBSHash).Replace('-','') }

                New-Object -TypeName PSObject -Property ([Ordered] @{
                    SignatureIndex = $SignerData.Signature
                    Hash = $Hash
                    PageHash = $SignerData.PageHash
                    SignatureType = $SignatureType
                    ValidatedSigningLevel = $SigningLevelMapping[$SignerData.ValidatedSigningLevel]
                    VerificationError = $VerificationError
                    Flags = $SignerData.Flags
                    PolicyBits = $SignerData.PolicyBits
                    NotValidBefore = $SignerData.NotValidBefore
                    NotValidAfter = $SignerData.NotValidAfter
                    PublisherName = $SignerData.PublisherName
                    IssuerName = $SignerData.IssuerName
                    PublisherTBSHash = $PublisherTBSHash
                    IssuerTBSHash = $IssuerTBSHash
                })
            }
        }

        if (-not $ExplicitlyDeniedSigner) {
            $UnresolvedFilePath = $EventData.FileName

            $ResolvedFilePath = $null
            # Make a best effort to resolve the device path to a normal path.
            if ($UnresolvedFilePath -match '(?<Prefix>^\\Device\\HarddiskVolume(?<VolumeNumber>\d)\\)') {
                $ResolvedFilePath = $UnresolvedFilePath.Replace($Matches['Prefix'], "$($PartitionMapping[$Matches['VolumeNumber']]):\")
            } elseif ($UnresolvedFilePath.ToLower().StartsWith('system32')) {
                $ResolvedFilePath = "$($Env:windir)\System32$($UnresolvedFilePath.Substring(8))"
            }

            # If all else fails regarding path resolution, show a warning.
            if ($ResolvedFilePath -and !(Test-Path -Path $ResolvedFilePath)) {
                Write-Warning "The following file path was either not resolved properly or was not present on disk: $ResolvedFilePath"
            }

            $ResolvedProcessName = $null
            $ProcessName = $EventData.ProcessName
            # Make a best effort to resolve the process path to a normal path.
            if ($ProcessName -match '(?<Prefix>^\\Device\\HarddiskVolume(?<VolumeNumber>\d)\\)') {
                $ResolvedProcessName = $ProcessName.Replace($Matches['Prefix'], "$($PartitionMapping[$Matches['VolumeNumber']]):\")
            } elseif ($ProcessName.ToLower().StartsWith('system32')) {
                $ResolvedProcessName = "$($Env:windir)\System32$($ProcessName.Substring(8))"
            }

            # If all else fails regarding path resolution, show a warning.
            if ($ResolvedProcessName -and !(Test-Path -Path $ResolvedProcessName)) {
                Write-Warning "The following process file path was either not resolved properly or was not present on disk: $ResolvedProcessName"
            }

            $UserName = "n/a"

            $SHA1FileHash = $null
            if ($EventData.SHA1FlatHash) { $SHA1FileHash = [BitConverter]::ToString($EventData.SHA1FlatHash[0..19]).Replace('-','') }

            $SHA1AuthenticodeHash = $null
            if ($EventData.SHA1Hash) { $SHA1AuthenticodeHash = [BitConverter]::ToString($EventData.SHA1Hash).Replace('-','') }

            $SHA256FileHash = $null
            if ($EventData.SHA256FlatHash) { $SHA256FileHash = [BitConverter]::ToString($EventData.SHA256FlatHash[0..31]).Replace('-','') }

            $SHA256AuthenticodeHash = $null
            if ($EventData.SHA256Hash) { $SHA256AuthenticodeHash = [BitConverter]::ToString($EventData.SHA256Hash).Replace('-','') }

            $PolicyGuid = $null
            if ($EventData.PolicyGUID) { $PolicyGuid = $EventData.PolicyGUID.Guid.ToUpper() }

            $PolicyHash = $null
            if ($EventData.PolicyHash) { $PolicyHash = [BitConverter]::ToString($EventData.PolicyHash).Replace('-','') }

            $CIEventProperties = [Ordered] @{
                TimeCreated = $_.TimeCreated
                ProcessID = $_.ProcessId
                User = $UserName
                EventType = $EventIdMapping[$_.Id]
                SigningScenario = $SigningScenarioMapping[$EventData.SISigningScenario]
                UnresolvedFilePath = $UnresolvedFilePath
                FilePath = $ResolvedFilePath
                SHA1FileHash = $SHA1FileHash
                SHA1AuthenticodeHash = $SHA1AuthenticodeHash
                SHA256FileHash = $SHA256FileHash
                SHA256AuthenticodeHash = $SHA256AuthenticodeHash
                UnresolvedProcessName = $EventData.ProcessName
                ProcessName = $ResolvedProcessName
                RequestedSigningLevel = $SigningLevelMapping[$EventData.RequestedSigningLevel]
                ValidatedSigningLevel = $SigningLevelMapping[$EventData.ValidatedSigningLevel]
                PolicyName = $EventData.PolicyName
                PolicyID = $EventData.PolicyId
                PolicyGUID = $PolicyGuid
                PolicyHash = $PolicyHash
                OriginalFileName = $EventData.OriginalFileName
                InternalName = $EventData.InternalName
                FileDescription = $EventData.FileDescription
                ProductName = $EventData.ProductName
                FileVersion = $EventData.FileVersion
                PackageFamilyName = $EventData.PackageFamilyName
                UserWriteable = $EventData.UserWriteable
                FailedWHQL = $WHQLFailed
                SignerInfo = ($ResolvedSigners | Sort-Object -Property SignatureIndex)
            }

            if (-not $IgnoreNativeImagesDLLs -or ($IgnoreNativeImagesDLLs -and $CIEventProperties.ResolvedFilePath -notlike "$env:SystemRoot\assembly\NativeImages*.dll")) {
                New-Object -TypeName PSObject -Property $CIEventProperties
            }
        }
    }
}