$appFailureObjs = [System.Collections.Generic.List[PSCustomObject]]::new()

$regPath = "Registry::HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\IntuneManagementExtension\Win32Apps\Reporting\00000000-0000-0000-0000-000000000000"

$appRegItems = Get-ChildItem $regPath | Get-ItemProperty

foreach ($appRegItem in $appRegItems) {
    $statusServiceReportTime        = [datetime]::ParseExact(
        $appRegItem.StatusServiceReportTime,
        'MM/dd/yyyy HH:mm:ss',
        [CultureInfo]::InvariantCulture
    )
    $statusServiceReportIsStale = $statusServiceReportTime -lt (Get-Date).AddMinutes(-72000)
    if ($statusServiceReportIsStale) {
        continue
    }

    $lastUpdatedTime                = [datetime]::ParseExact(
        $appRegItem.LastUpdatedTime,
        'MM/dd/yyyy HH:mm:ss',
        [CultureInfo]::InvariantCulture
    )

    $appId                          = $appRegItem.PSChildName
    $reportingState                 = $appRegItem.ReportingState | ConvertFrom-Json

    $enforcementErrorCode           = $reportingState.EnforcementErrorCode
    $hasEnforcementError            = (-not [string]::IsNullOrWhiteSpace($enforcementErrorCode)) -and ($enforcementErrorCode -ne 0)

    $detectionErrorOccurred         = $reportingState.DetectionErrorOccurred
    $hasDetectionError              = $detectionErrorOccurred -eq 'True'

    $applicabilityErrorOccurred     = $reportingState.ApplicabilityErrorOccurred
    $hasApplicabilityError          = $applicabilityErrorOccurred -eq 'True'

    if ( (-not $hasEnforcementError) -and (-not $hasDetectionError) -and (-not $hasApplicabilityError) ) {
        continue
    }

    $failedApps = [ordered]@{
        AppId                       = $appId
        StatusServiceReportTime     = $statusServiceReportTime
        LastUpdatedTime             = $lastUpdatedTime
        EnforcementErrorCode        = '0x{0:X8}' -f ($enforcementErrorCode -band 0x00000000FFFFFFFF)

    }
}

if ($appFailureObjs.Count -gt 0) {
    $payload = @{
        ComputerName    = $env:COMPUTERNAME
        ScanTime        = (Get-Date).ToString('o')
        FailedApps      = @($failedApps)
    }

    $json = $payload | ConvertTo-Json -Depth 10

    $secureUrl = Get-Content "$env:PROGRAMDATA\IntuneFailureMonitor\LogicAppUrl.txt"
    $url = [Net.NetworkCredential]::new('', $secureUrl).Password

    try {
        Invoke-RestMethod -Uri $url -Method POST -ContentType 'application/json' -Body $json -ErrorAction Stop
    } catch {
        Write-Error "Failed to send payload to endpoint: $_"
    }
}
