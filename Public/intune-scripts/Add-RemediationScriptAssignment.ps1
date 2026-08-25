function Add-RemediationScriptAssignment {
    [CmdletBinding(SupportsShouldProcess=$true)]
    param (
        [Parameter(Mandatory = $true)]
        [string]$ScriptId,

        [Parameter(Mandatory = $true)]
        [string]$GroupId,

        [Parameter(Mandatory = $false)]
        [ValidateSet("Daily", "Hourly", "RunOnce")]
        [string]$ScheduleType = "Daily",

        [Parameter(Mandatory = $false)]
        [int]$Interval = 1,

        [Parameter(Mandatory = $false)]
        [bool]$RunRemediationScript = $true,

        [Parameter(Mandatory = $false)]
        [string]$FilterId,

        [Parameter(Mandatory = $false)]
        [ValidateSet("include", "exclude")]
        [string]$FilterType = "include",

        [Parameter(Mandatory = $false)]
        [switch]$Append
    )

    # 1. Build Target Object
    $target = [ordered]@{
        "@odata.type" = "#microsoft.graph.groupAssignmentTarget"
        "groupId"     = $GroupId
    }

    if ($FilterId) {
        $target["deviceAndAppManagementAssignmentFilterId"]   = $FilterId
        $target["deviceAndAppManagementAssignmentFilterType"] = $FilterType
    }

    # 2. Build Schedule Object
    switch ($ScheduleType) {
        "Daily" {
            $schedule = [ordered]@{
                "@odata.type" = "#microsoft.graph.deviceHealthScriptDailySchedule"
                "interval"    = $Interval
            }
        }
        "Hourly" {
            $schedule = [ordered]@{
                "@odata.type" = "#microsoft.graph.deviceHealthScriptHourlySchedule"
                "interval"    = $Interval
            }
        }
        "RunOnce" {
            $schedule = [ordered]@{
                "@odata.type"   = "#microsoft.graph.deviceHealthScriptRunOnceSchedule"
                "date"          = (Get-Date).AddDays(1).ToString("yyyy-MM-dd")
                "time"          = "00:00:00"
                "useUtc"        = $true
            }
        }
    }

    # 3. Create the new assignment payload item
    $newAssignment = [ordered]@{
        "@odata.type"          = "#microsoft.graph.deviceHealthScriptAssignment"
        "target"               = $target
        "runSchedule"          = $schedule
        "runRemediationScript" = $RunRemediationScript
    }

    $assignmentsList = [System.Collections.Generic.List[object]]::new()

    # 4. If appending, fetch existing assignments first
    if ($Append) {
        $existingUri = "https://graph.microsoft.com/beta/deviceManagement/deviceHealthScripts/$ScriptId/assignments"

        try {
            $existing = (Invoke-MgGraphRequest -Method GET -Uri $existingUri -ErrorAction Stop).value
        } catch {
            Write-Error "Failed to retrieve existing assignments for script '$ScriptId': $_"
            return
        }

        foreach ($item in $existing) {
            # Prevent duplicate assignment to the same group ID
            if ($item.target.groupId -eq $GroupId) {
                Write-Warning "Group ID $GroupId is already assigned. Updating its configuration."
                continue
            }

            $cleanedItem = [ordered]@{
                "@odata.type"          = "#microsoft.graph.deviceHealthScriptAssignment"
                "target"               = $item.target
                "runSchedule"          = $item.runSchedule
                "runRemediationScript" = $item.runRemediationScript
            }
            $assignmentsList.Add($cleanedItem)
        }
    }

    $assignmentsList.Add($newAssignment)

    # 5. Send the assign payload to Graph API
    $assignUri = "https://graph.microsoft.com/beta/deviceManagement/deviceHealthScripts/$ScriptId/assign"
    $body = @{
        "deviceHealthScriptAssignments" = $assignmentsList
    } | ConvertTo-Json -Depth 10

    $action = if ($Append) {
        "Add assignment on top of any existing assignments"
    } else {
        "Replace all assignments with this one"
    }

    if ($PSCmdlet.ShouldProcess($ScriptId, $action)) {
        try {
            Invoke-MgGraphRequest -Method POST -Uri $assignUri -Body $body -ContentType "application/json"
            Write-Information "Successfully updated assignments for Remediation Script: $ScriptId"
        }
        catch {
            Write-Error "Failed to assign script: $_"
        }
    }
}
