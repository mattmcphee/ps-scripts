function Get-IntuneAppFailures {
    param (
        # ComputerName
        [Parameter(Mandatory = $false)]
        [string]$ComputerName = $env:COMPUTERNAME,

        # LastXDays - returns failures in the last x days, defaults to one day
        [Parameter(Mandatory=$false)]
        [int]$LastXDays = 1
    )

    $errors = Invoke-Command -ComputerName $ComputerName -ArgumentList $LastXDays -ScriptBlock {
        $regPath = "Registry::HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\IntuneManagementExtension\Win32Apps\Reporting\00000000-0000-0000-0000-000000000000"

        $appRegItems = Get-ChildItem $regPath | Get-ItemProperty

        foreach ($appRegItem in $appRegItems) {
            $statusServiceReportTime = [datetime]::ParseExact(
                $appRegItem.StatusServiceReportTime,
                'MM/dd/yyyy HH:mm:ss',
                [System.Globalization.CultureInfo]::InvariantCulture,
                [System.Globalization.DateTimeStyles]::AssumeUniversal -bor
                [System.Globalization.DateTimeStyles]::AdjustToUniversal
            )

            $lastUpdatedTime = [datetime]::ParseExact(
                $appRegItem.LastUpdatedTime,
                'MM/dd/yyyy HH:mm:ss',
                [System.Globalization.CultureInfo]::InvariantCulture,
                [System.Globalization.DateTimeStyles]::AssumeUniversal -bor
                [System.Globalization.DateTimeStyles]::AdjustToUniversal
            )

            $lastUpdatedTimeIsStale = $lastUpdatedTime -lt (Get-Date).ToUniversalTime().AddDays(-[Math]::Abs($using:LastXDays))
            if ($lastUpdatedTimeIsStale) { continue }

            $appId                                  = $appRegItem.PSChildName
            $reportingState                         = $appRegItem.ReportingState | ConvertFrom-Json
            $enforcementErrorCode                   = $reportingState.EnforcementErrorCode
            $hasEnforcementError                    = (-not [string]::IsNullOrWhiteSpace($enforcementErrorCode)) -and ($enforcementErrorCode -ne 0) -and ($enforcementErrorCode -ne "0x80070642")
            $detectionErrorOccurred                 = $reportingState.DetectionErrorOccurred
            $hasDetectionError                      = $detectionErrorOccurred -eq 'True'
            $applicabilityErrorOccurred             = $reportingState.ApplicabilityErrorOccurred
            $hasApplicabilityError                  = $applicabilityErrorOccurred -eq 'True'
            $noErrors                               = (-not $hasEnforcementError) -and (-not $hasDetectionError) -and (-not $hasApplicabilityError)

            if ($noErrors) { continue }

            [PSCustomObject]@{
                'AppId'                        = $appId
                'StatusServiceReportTime'      = $statusServiceReportTime.ToLocalTime()
                'AppStatusLastChanged'         = $lastUpdatedTime.ToLocalTime()
                'HasEnforcementError'          = $hasEnforcementError
                'EnforcementErrorCode'         = '0x{0:X8}' -f ($enforcementErrorCode -band 0x00000000FFFFFFFF)
                'HasDetectionError'            = $hasDetectionError
                'DetectionErrorCode'           = $reportingState.DetectionErrorCode
                'HasApplicabilityError'        = $hasApplicabilityError
                'ApplicabilityErrorCode'       = $reportingState.ApplicabilityErrorCode
            }
        }
    }

    $errors | Select-Object @{
        Name = 'DisplayName'
        Expr = { (Get-IntuneApp -ID $_.AppId).DisplayName }
    }, * -ExcludeProperty 'PSComputerName','RunspaceId'
}
