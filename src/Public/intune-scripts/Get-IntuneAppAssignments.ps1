function Get-IntuneAppAssignments {
    [CmdletBinding()]
    param(
        # ApplicationName - app display name, supports wildcards e.g. 'OBS Studio*'
        [Parameter(Mandatory)]
        [string]$ApplicationName
    )

    # beta is required - v1.0 does not return winGetApp (Microsoft Store) apps
    $uri = 'https://graph.microsoft.com/beta/deviceAppManagement/mobileApps?$select=id,displayName'
    $apps = [System.Collections.Generic.List[object]]::new()

    while ($uri) {
        $response = Invoke-MgGraphRequest -Method GET -Uri $uri -ErrorAction Stop

        foreach ($app in $response.value) {
            if ($app.displayName -like $ApplicationName) {
                $apps.Add($app)
            }
        }

        $uri = $response.'@odata.nextLink'
    }

    if ($apps.Count -eq 0) {
        return
    }

    # fetch assignments only for matching apps - $batch allows max 20 requests per call
    $assignmentsByApp = @{}
    for ($i = 0; $i -lt $apps.Count; $i += 20) {
        $pending = @($apps.GetRange($i, [Math]::Min(20, $apps.Count - $i)) | ForEach-Object {
            @{ id = $_.id; method = 'GET'; url = "/deviceAppManagement/mobileApps/$($_.id)/assignments" }
        })

        while ($pending.Count -gt 0) {
            $body = @{ requests = $pending } | ConvertTo-Json -Depth 5
            $batch = Invoke-MgGraphRequest -Method POST -Uri 'https://graph.microsoft.com/beta/$batch' -Body $body -ContentType 'application/json' -ErrorAction Stop

            $throttled = @()
            $retryAfter = 0
            foreach ($result in $batch.responses) {
                if ($result.status -eq 200) {
                    $assignmentsByApp[$result.id] = $result.body.value
                } elseif ($result.status -eq 429) {
                    $throttled += $pending.Where({ $_.id -eq $result.id })
                    $wait = if ($result.headers.'Retry-After') { [int]$result.headers.'Retry-After' } else { 5 }
                    $retryAfter = [Math]::Max($retryAfter, $wait)
                } else {
                    throw "Failed to get assignments for app $($result.id): $($result.status) $($result.body.error.message)"
                }
            }

            $pending = $throttled
            if ($pending.Count -gt 0) {
                Start-Sleep -Seconds $retryAfter
            }
        }
    }

    $allAssignments = @($assignmentsByApp.Values | ForEach-Object { $_ })

    # resolve all group names in bulk - getByIds accepts max 1000 ids per call
    $groupNames = @{}
    $groupIds = [System.Collections.Generic.List[string]]@(
        $allAssignments.target.groupId | Where-Object { $_ } | Select-Object -Unique
    )
    for ($i = 0; $i -lt $groupIds.Count; $i += 1000) {
        $body = @{
            ids   = @($groupIds.GetRange($i, [Math]::Min(1000, $groupIds.Count - $i)))
            types = @('group')
        } | ConvertTo-Json
        $response = Invoke-MgGraphRequest -Method POST -Uri 'https://graph.microsoft.com/v1.0/directoryObjects/getByIds' -Body $body -ContentType 'application/json' -ErrorAction Stop
        foreach ($group in $response.value) {
            $groupNames[$group.id] = $group.displayName
        }
    }

    # filters are few per tenant - list them all once rather than one call per filter id
    $filterNames = @{}
    if ($allAssignments.target.deviceAndAppManagementAssignmentFilterId | Where-Object { $_ }) {
        $uri = 'https://graph.microsoft.com/beta/deviceManagement/assignmentFilters?$select=id,displayName'
        while ($uri) {
            $response = Invoke-MgGraphRequest -Method GET -Uri $uri -ErrorAction Stop
            foreach ($filter in $response.value) {
                $filterNames[$filter.id] = $filter.displayName
            }
            $uri = $response.'@odata.nextLink'
        }
    }

    foreach ($app in $apps) {
        $appType = $app.'@odata.type'.Split('.')[-1]
        $assignments = $assignmentsByApp[$app.id]

        if (-not $assignments) {
            [PSCustomObject]@{
                AppDisplayName = $app.displayName
                AppId          = $app.id
                AppType        = $appType
                Intent         = $null
                GroupName      = $null
                GroupId        = $null
                FilterName     = $null
                FilterId       = $null
                FilterType     = $null
            }
            continue
        }

        foreach ($assignment in $assignments) {
            $target = $assignment.target
            $groupId = $target.groupId
            $groupName = switch ($target.'@odata.type') {
                '#microsoft.graph.allLicensedUsersAssignmentTarget' { 'All Users' }
                '#microsoft.graph.allDevicesAssignmentTarget' { 'All Devices' }
                default { $null }
            }

            if ($groupId) {
                $groupName = if ($groupNames.ContainsKey($groupId)) { $groupNames[$groupId] } else { 'Unknown/Deleted Group' }
            }

            $filterId = $target.deviceAndAppManagementAssignmentFilterId
            $filterName = $null
            if ($filterId) {
                $filterName = if ($filterNames.ContainsKey($filterId)) { $filterNames[$filterId] } else { 'Unknown/Deleted Filter' }
            }

            [PSCustomObject]@{
                AppDisplayName = $app.displayName
                AppId          = $app.id
                AppType        = $appType
                Intent         = $assignment.intent
                GroupName      = $groupName
                GroupId        = $groupId
                FilterName     = $filterName
                FilterId       = $filterId
                FilterType     = $target.deviceAndAppManagementAssignmentFilterType
            }
        }
    }
}