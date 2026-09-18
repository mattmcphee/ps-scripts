# Connect-MgGraph -Scopes "DeviceManagementConfiguration.Read.All", "Group.Read.All"

function Get-RemediationScriptAssignment {
    $uri = "https://graph.microsoft.com/beta/deviceManagement/deviceHealthScripts"
    $scriptResults = [System.Collections.Generic.List[PSCustomObject]]::new()

    while ($uri) {
        $response = Invoke-MgGraphRequest -Method GET -Uri $uri

        foreach ($script in $response.value) {
            $scriptResults.Add([PSCustomObject]@{
                ID          = $script.id
                DisplayName = $script.displayName
                Description = $script.description
            })
        }

        # Move to next page if results exceed the default page size
        $uri = $response.'@odata.nextLink'
    }

    $targetScript = $scriptResults | Out-GridView -Title "Select Remediation Script" -OutputMode Single

    if ($targetScript) {
        # 2. Get assignments for the selected remediation script
        $assignmentsUri = "https://graph.microsoft.com/beta/deviceManagement/deviceHealthScripts/$($targetScript.id)/assignments"
        $assignments = (Invoke-MgGraphRequest -Method GET -Uri $assignmentsUri).value

        # 3. Output assignment details
        $assignments | ForEach-Object {
            $target = $_.target
            $targetType = $target.'@odata.type'
            $groupId = $target.groupId
            $groupName = "N/A"

            # Resolve Entra ID Group Name if assigned to a specific group
            if ($groupId) {
                try {
                    $group = Invoke-MgGraphRequest -Method GET -Uri "https://graph.microsoft.com/v1.0/groups/$groupId"
                    $groupName = $group.displayName
                } catch {
                    $groupName = "Unknown/Deleted Group"
                }
            }

            [PSCustomObject]@{
                ScriptName     = $targetScript.displayName
                AssignmentId   = $_.id
                TargetType     = $targetType.Split('.')[-1]
                GroupName      = $groupName
                GroupId        = $groupId
                FilterId       = $target.deviceAndAppManagementAssignmentFilterId
                FilterType     = $target.deviceAndAppManagementAssignmentFilterType
                ScheduleType   = $_.runSchedule.'@odata.type'.Split('.')[-1]
                ScheduleDetail = $_.runSchedule.interval
            }
        } | Format-Table -AutoSize
    }
}
