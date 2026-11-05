
function Get-EntraStaleDeviceReport {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$false)]
        [string]$ExportPath
    )

    $uri = 'https://graph.microsoft.com/v1.0/devices?$select=id,deviceId,displayName,operatingSystem,approximateLastSignInDateTime,trustType,accountEnabled,isManaged&$top=999'

    $devices = [System.Collections.Generic.List[object]]::new()

    do {
        $response = Invoke-MgGraphRequest -Method GET -Uri $uri

        foreach ($device in $response.value) {
            $devices.Add($device)
        }

        $uri = $response.'@odata.nextLink'
    } while ($uri)

    $now = [datetime]::UtcNow

    $report = @(
        foreach ($device in $devices) {
            $lastSignIn = if ($device.approximateLastSignInDateTime) {
                ([datetimeoffset]$device.approximateLastSignInDateTime).UtcDateTime
            } else {
                $null
            }

            $inactiveDays = if ($null -ne $lastSignIn) {
                [math]::Floor(($now - $lastSignIn).TotalDays)
            } else {
                $null
            }

            [PSCustomObject]@{
                DeviceName     = $device.displayName
                OperatingSystem = $device.operatingSystem
                EntraObjectId  = $device.id
                EntraDeviceId  = $device.deviceId
                TrustType      = $device.trustType
                AccountEnabled = $device.accountEnabled
                IsManaged      = $device.isManaged
                LastSignIn     = $lastSignIn
                InactiveDays   = $inactiveDays
                Inactive30Days  = ($null -ne $lastSignIn -and $inactiveDays -ge 30)
                Inactive60Days  = ($null -ne $lastSignIn -and $inactiveDays -ge 60)
                Inactive90Days  = ($null -ne $lastSignIn -and $inactiveDays -ge 90)
                Inactive120Days = ($null -ne $lastSignIn -and $inactiveDays -ge 120)
                Inactive180Days = ($null -ne $lastSignIn -and $inactiveDays -ge 180)
                Inactive270Days = ($null -ne $lastSignIn -and $inactiveDays -ge 270)
            }
        }
    )

    $total = $report.Count

    $summary = foreach ($Days in @(30, 60, 90, 120, 180, 270)) {
        $Count = $report.Where({
            $null -ne $_.inactiveDays -and
            $_.inactiveDays -ge $Days
        }).Count

        [PSCustomObject]@{
            InactiveDays = "$Days+"
            DeviceCount  = $Count
            Percentage   = if ($total) {
                [math]::Round(($Count / $total) * 100, 2)
            } else {
                0
            }
        }
    }

    $summary | Format-Table -AutoSize | Out-Host

    $missingSignIn = $report.Where({
        $null -eq $_.inactiveDays
    }).Count

    Write-Host "Total Entra devices: $total"
    Write-Host "Missing last sign-in: $missingSignIn"

    if ($ExportPath) {
        $report |
            Sort-Object inactiveDays -Descending |
            Export-Csv -Path $ExportPath -NoTypeInformation

        Write-Host "Exported to: $ExportPath"
    }
}
