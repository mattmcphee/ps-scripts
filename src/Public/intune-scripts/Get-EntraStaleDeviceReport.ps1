
function Get-EntraStaleDeviceReport {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$false)]
        [int]$StaleDays = 90,

        [Parameter(Mandatory=$false)]
        [string]$ExportPath
    )

    $uri = 'https://graph.microsoft.com/v1.0/devices?$select=id,deviceId,displayName,operatingSystem,approximateLastSignInDateTime,trustType,accountEnabled,isManaged&$filter=operatingSystem%20eq%20%27Windows%27&$top=999'

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
                EntraObjectId  = $device.id
                EntraDeviceId  = $device.deviceId
                TrustType      = $device.trustType
                AccountEnabled = $device.accountEnabled
                IsManaged      = $device.isManaged
                LastSignIn     = $lastSignIn
                InactiveDays   = $inactiveDays
                IsStale        = ($null -eq $lastSignIn -or $inactiveDays -ge $StaleDays)
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

    $stale = $report.Where({ $_.IsStale })

    Write-Host "Total Windows Entra devices: $total"
    Write-Host "Missing last sign-in: $missingSignIn"
    Write-Host "Stale at $StaleDays days (including missing sign-in): $($stale.Count)"

    if ($ExportPath) {
        $report |
            Sort-Object inactiveDays -Descending |
            Export-Csv -Path $ExportPath -NoTypeInformation

        Write-Host "Exported to: $ExportPath"
    }

    return $stale
}
