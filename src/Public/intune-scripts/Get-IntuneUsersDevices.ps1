function Get-IntuneUsersDevices {
    [CmdletBinding()]
    param (
        # UserPrincipalName - UPN, supports wildcards e.g. 'MAT*'
        [Parameter(Mandatory)]
        [string]$UserPrincipalName
    )

    # retrieve users
    $baseUri = 'https://graph.microsoft.com/v1.0'

    # filter server-side on the literal text before the first wildcard, then apply the full pattern with -like
    $hasWildcard = $UserPrincipalName -match '[*?]'
    $prefix = ($UserPrincipalName -split '[*?]', 2)[0]
    $value = $prefix.Replace("'", "''")

    $filter = if (-not $hasWildcard) {
        "userPrincipalName eq '$value'"
    } elseif ($prefix) {
        "startswith(userPrincipalName, '$value')"
    }

    $uri = "$baseUri/users?`$select=id,displayName,userPrincipalName&`$top=999"
    if ($filter) {
        $uri += "&`$filter=$([uri]::EscapeDataString($filter))"
    }

    $users = [System.Collections.Generic.List[object]]::new()
    while ($uri) {
        $response = Invoke-MgGraphRequest -Method GET -Uri $uri -ErrorAction Stop

        foreach ($user in $response.value) {
            if (-not $hasWildcard -or $user.userPrincipalName -like $UserPrincipalName) {
                $users.Add($user)
            }
        }

        $uri = $response.'@odata.nextLink'
    }

    if ($users.Count -lt 1) {
        Write-Warning "User '$UserPrincipalName' not found."
        return
    }

    # retrieve devices associated with users - $batch allows max 20 requests per call
    $deviceSelect = 'id,deviceName,lastSyncDateTime,operatingSystem,osVersion,complianceState,azureADDeviceId'
    $devicesByUser = @{}
    for ($i = 0; $i -lt $users.Count; $i += 20) {
        $pending = @($users.GetRange($i, [Math]::Min(20, $users.Count - $i)) | ForEach-Object {
            @{ id = $_.id; method = 'GET'; url = "/users/$($_.id)/managedDevices?`$select=$deviceSelect" }
        })

        while ($pending.Count -gt 0) {
            $body = @{ requests = $pending } | ConvertTo-Json -Depth 5
            $batch = Invoke-MgGraphRequest -Method POST -Uri "$baseUri/`$batch" -Body $body -ContentType 'application/json' -ErrorAction Stop

            $throttled = @()
            $retryAfter = 0
            foreach ($result in $batch.responses) {
                if ($result.status -eq 200) {
                    $devices = [System.Collections.Generic.List[object]]::new()
                    $devices.AddRange(@($result.body.value))
                    $uri = $result.body.'@odata.nextLink'
                    while ($uri) {
                        $response = Invoke-MgGraphRequest -Method GET -Uri $uri -ErrorAction Stop
                        $devices.AddRange(@($response.value))
                        $uri = $response.'@odata.nextLink'
                    }
                    $devicesByUser[$result.id] = $devices
                } elseif ($result.status -eq 404) {
                    $user = $users.Find({ param($u) $u.id -eq $result.id })
                    Write-Warning "Managed devices not found for user '$($user.displayName)' ($($user.id))."
                } elseif ($result.status -eq 429) {
                    $throttled += $pending.Where({ $_.id -eq $result.id })
                    $wait = if ($result.headers.'Retry-After') { [int]$result.headers.'Retry-After' } else { 5 }
                    $retryAfter = [Math]::Max($retryAfter, $wait)
                } else {
                    throw "Failed to get managed devices for user $($result.id): $($result.status) $($result.body.error.message)"
                }
            }

            $pending = $throttled
            if ($pending.Count -gt 0) {
                Start-Sleep -Seconds $retryAfter
            }
        }
    }

    foreach ($user in $users) {
        foreach ($device in $devicesByUser[$user.id]) {
            [PSCustomObject]@{
                UserName            = $User.displayName
                UserPrincipalName   = $User.userPrincipalName
                DeviceName          = $Device.deviceName
                OperatingSystem     = $Device.operatingSystem
                OSVersion           = $Device.osVersion
                ComplianceState     = $Device.complianceState
                LastSync            = $Device.lastSyncDateTime
                IntuneDeviceId      = $Device.id
                EntraDeviceId       = $Device.azureADDeviceId
            }
        }
    }
}