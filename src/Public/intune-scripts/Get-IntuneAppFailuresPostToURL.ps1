function Get-IntuneAppFailuresPostToURL {
    function Write-CMLog {
        [CmdletBinding()]
        param(
            # Message
            [Parameter(Mandatory = $true, ValueFromPipeline)]
            [AllowEmptyString()]
            [AllowNull()]
            [string[]]
            $Message,
            # Path
            [Parameter(Mandatory = $false)]
            [ValidateNotNullOrEmpty()]
            [string]
            $Path = "$env:PROGRAMDATA\IntuneAppFailureMonitor\IntuneAppFailureMonitor.log",
            # Level
            [Parameter(Mandatory = $false)]
            [ValidateSet("Error", "Warning", "Info")]
            [string]
            $Level = "Info",
            # Component
            [Parameter(Mandatory = $false)]
            [string]
            $Component = "PowerShellScript",
            # Context
            [Parameter(Mandatory = $false)]
            [string]
            $Context = "PowerShellScript",
            # Quiet - suppresses output
            [Parameter(Mandatory = $false)]
            [switch]
            $Quiet = $false
        )

        process {
            $logDir = Split-Path $Path -Parent

            if (-not (Test-Path -Path $logDir -PathType Container)) {
                try {
                    New-Item -ItemType Directory -Path $logDir -ErrorAction Stop -Force
                } catch {
                    throw "Could not create log directory: $logDir $_"
                }
            }

            $now = Get-Date
            $tzOffset = [TimeZoneInfo]::Local.GetUtcOffset($now).TotalMinutes
            $timeStr = $now.ToString("HH:mm:ss.fff") + ("{0:+000;-000;+000}" -f $tzOffset)
            $dateStr = $now.ToString("MM-dd-yyyy")

            foreach ($line in $Message) {
                if (-not $Quiet) {
                    # output the message
                    Write-Output $line
                }

                # convert level to type codes so cmtrace can read it
                switch ($Level) {
                    "Info" { [int]$type = 1 }
                    "Warning" { [int]$type = 2 }
                    "Error" { [int]$type = 3 }
                }

                $threadId = [System.Threading.Thread]::CurrentThread.ManagedThreadId
                $scriptName = $MyInvocation.MyCommand.Name

                # create log entry
                $logLine = "<![LOG[$line]LOG]!>" +
                "<" +
                "time=`"$timeStr`" " +
                "date=`"$dateStr`" " +
                "component=`"$Component`" " +
                "context=`"$Context`" " +
                "type=`"$type`" " +
                "thread=`"$threadId`" " +
                "file=`"$scriptName`"" +
                ">"

                # append line to log file
                $logLine | Out-File -FilePath $Path -Append -Encoding utf8
            }
        }
    }

    $regPath = "Registry::HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\IntuneManagementExtension\Win32Apps\Reporting\00000000-0000-0000-0000-000000000000"

    $appRegItems = Get-ChildItem $regPath | Get-ItemProperty

    $appFailures = foreach ($appRegItem in $appRegItems) {
        $statusServiceReportTime = [datetime]::ParseExact(
            $appRegItem.StatusServiceReportTime,
            'MM/dd/yyyy HH:mm:ss',
            [System.Globalization.CultureInfo]::InvariantCulture,
            [System.Globalization.DateTimeStyles]::AssumeUniversal -bor
            [System.Globalization.DateTimeStyles]::AdjustToUniversal
        )

        $statusServiceReportIsStale = $statusServiceReportTime -lt (Get-Date).ToUniversalTime().AddMinutes(-[Math]::Abs(60))
        if ($statusServiceReportIsStale) { continue }

        $lastUpdatedTime = [datetime]::ParseExact(
            $appRegItem.LastUpdatedTime,
            'MM/dd/yyyy HH:mm:ss',
            [System.Globalization.CultureInfo]::InvariantCulture,
            [System.Globalization.DateTimeStyles]::AssumeUniversal -bor
            [System.Globalization.DateTimeStyles]::AdjustToUniversal
        )

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

        Write-CMLog "StatusServiceReport for $appId is less than one hour old and has at least one error."
        Write-CMLog "AppId: $appId"
        Write-CMLog "StatusServiceReportTime: $statusServiceReportTime"
        Write-CMLog "EnforcementErrorCode: $enforcementErrorCode"

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

    if ($appFailures.Count -gt 0) {
        $computerName = $env:COMPUTERNAME
        $scanTime = (Get-Date).ToString('o')
        $appIndex = 1
        $appReportHtml = foreach ($appFailure in $appFailures) {
@"
<table style="border-collapse:collapse; margin-bottom:20px; width:700px;">
    <th colspan="2" style="text-align:center; background:#f2f2f2; padding:10px; border:1px solid #ccc;">
        Application Installation Failure #$($appIndex)
    </th>
<tr>
    <td style="font-weight:bold; padding:8px; border:1px solid #ccc; width:200px;">
        App ID
    </td>
    <td style="padding:8px; border:1px solid #ccc;">
        $($appFailure.AppId)
    </td>
</tr>
<tr>
    <td style="font-weight:bold; padding:8px; border:1px solid #ccc;">
        Intune Status Service Report Time
    </td>
    <td style="padding:8px; border:1px solid #ccc;">
        $($appFailure.StatusServiceReportTime)
    </td>
</tr>
<tr>
    <td style="font-weight:bold; padding:8px; border:1px solid #ccc;">
        Intune Installation Status Last Changed
    </td>
    <td style="padding:8px; border:1px solid #ccc;">
        $($appFailure.AppStatusLastChanged)
    </td>
</tr>
<tr>
    <td style="font-weight:bold; padding:8px; border:1px solid #ccc;">
        Enforcement Error Code
    </td>
    <td style="padding:8px; border:1px solid #ccc;">
        $($appFailure.EnforcementErrorCode)
    </td>
</tr>
</table>
"@
            $appIndex++
        }

        $appIdsString = (
            $appFailures | ForEach-Object {
                "'$($_.AppId)'"
            }
        ) -join ",`r`n"

        $htmlBody = 
@"
<html>
<body style="font-family:Segoe UI,Arial,sans-serif;">
<h2>Installation Failure Detected!</h2>
<p><strong>Computer:</strong> $env:COMPUTERNAME</p>
<p><strong>Scan Time:</strong> $scanTime</p>
<h3>Failure Details</h3>
$($appReportHtml -join "`n")
<h3>Copy IDs</h3>
<pre style="background:#f4f4f4;border:1px solid #ccc;padding:12px;font-family:Consolas,monospace;white-space:pre-wrap;">
<code>
$appIdsString
</code>
</pre>
</body>
</html>
"@

        $payload = [PSCustomObject]@{
            Subject         = "[ALERT] Intune App Install Failed!"
            Body            = $htmlBody
        }

        $json = $payload | ConvertTo-Json -Depth 10

        $thumb = "36D08BA1F03685F06B9B3E7B047C337CD4590877"
        $cert = Get-Item "Cert:\LocalMachine\My\$thumb"
        $cmsPath = "$env:PROGRAMDATA\IntuneAppFailureMonitor\LogicAppUrl.cms"
        $url = Unprotect-CmsMessage -LiteralPath $cmsPath -To $cert -ErrorAction Stop

        try {
            Invoke-RestMethod -Uri $url -Method POST -ContentType 'application/json' -Body $json -ErrorAction Stop
        } catch {
            Write-CMLog "Failed to send payload to endpoint: $($_.Exception.Message)"
        }
    }
}
