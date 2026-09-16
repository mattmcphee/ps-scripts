function Get-IntuneAppFailures {
    param (
        # LastXDays - returns failures in the last x days, defaults to one day
        [Parameter(Mandatory=$false)]
        [int]$LastXDays = 1
    )

    $results = [System.Collections.Generic.List[PSCustomObject]]::new()

    $regPath = "Registry::HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\IntuneManagementExtension\Win32Apps\Reporting\00000000-0000-0000-0000-000000000000"

    $appRegItems = Get-ChildItem $regPath | Get-ItemProperty

    foreach ($appRegItem in $appRegItems) {
        $statusServiceReportTime        = [datetime]::ParseExact(
            $appRegItem.StatusServiceReportTime,
            'MM/dd/yyyy HH:mm:ss',
            [CultureInfo]::InvariantCulture
        )
        $statusServiceReportIsStale = $statusServiceReportTime -lt (Get-Date).AddDays((-[Math]::Abs($LastXDays)))
        if ($statusServiceReportIsStale) {
            continue
        }

        $lastUpdatedTime                = [datetime]::ParseExact(
            $appRegItem.LastUpdatedTime,
            'MM/dd/yyyy HH:mm:ss',
            [CultureInfo]::InvariantCulture
        )

        $result = [ordered]@{}

        $appId                                  = $appRegItem.PSChildName
        $reportingState                         = $appRegItem.ReportingState | ConvertFrom-Json
        $enforcementErrorCode                   = $reportingState.EnforcementErrorCode
        $hasEnforcementError                    = (-not [string]::IsNullOrWhiteSpace($enforcementErrorCode)) -and ($enforcementErrorCode -ne 0)
        $detectionErrorOccurred                 = $reportingState.DetectionErrorOccurred
        $hasDetectionError                      = $detectionErrorOccurred -eq 'True'
        $applicabilityErrorOccurred             = $reportingState.ApplicabilityErrorOccurred
        $hasApplicabilityError                  = $applicabilityErrorOccurred -eq 'True'
        $noErrors                               = (-not $hasEnforcementError) -and (-not $hasDetectionError) -and (-not $hasApplicabilityError)

        if ($noErrors) { continue }

        # getting the displayname from the id is an expensive operation
        # so we do it only when there's a confirmed error
        $displayName = (Get-IntuneApp -ID $appId).DisplayName

        $result['AppId']                        = $appId
        $result['DisplayName']                  = $displayName
        $result['StatusServiceReportTime']      = $statusServiceReportTime
        $result['AppStatusLastChanged']         = $lastUpdatedTime
        $result['HasEnforcementError']          = $hasEnforcementError
        $result['EnforcementErrorCode']         = '0x{0:X8}' -f ($enforcementErrorCode -band 0x00000000FFFFFFFF)
        $result['HasDetectionError']            = $hasDetectionError
        $result['DetectionErrorCode']           = $reportingState.DetectionErrorCode
        $result['HasApplicabilityError']        = $hasApplicabilityError
        $result['ApplicabilityErrorCode']       = $reportingState.ApplicabilityErrorCode

        $results.Add($result)
    }

    $results
}
