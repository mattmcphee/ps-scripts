function Remove-RemediationScriptAssignment {
    [CmdletBinding(DefaultParameterSetName = "ByGroupId")]
    param (
        [Parameter(Mandatory = $true)]
        [string]$ScriptId,

        [Parameter(Mandatory = $true, ParameterSetName = "ByGroupId")]
        [string]$GroupId,

        [Parameter(Mandatory = $true, ParameterSetName = "ByAssignmentId")]
        [string]$AssignmentId,

        [Parameter(Mandatory = $true, ParameterSetName = "All")]
        [switch]$All
    )

    $assignUri = "https://graph.microsoft.com/beta/deviceManagement/deviceHealthScripts/$ScriptId/assign"

    # 1. Handle removing all assignments
    if ($All) {
        $body = @{
            "deviceHealthScriptAssignments" = @()
        } | ConvertTo-Json

        try {
            Invoke-MgGraphRequest -Method POST -Uri $assignUri -Body $body -ContentType "application/json"
            Write-Host "Successfully removed all assignments from Remediation Script: $ScriptId" -ForegroundColor Green
        }
        catch {
            Write-Error "Failed to remove all assignments: $_"
        }
        return
    }

    # 2. Fetch existing assignments
    $existingUri = "https://graph.microsoft.com/beta/deviceManagement/deviceHealthScripts/$ScriptId/assignments"
    try {
        $existing = (Invoke-MgGraphRequest -Method GET -Uri $existingUri).value
    }
    catch {
        Write-Error "Failed to retrieve existing assignments: $_"
        return
    }

    if (-not $existing -or $existing.Count -eq 0) {
        Write-Warning "Remediation Script $ScriptId has no assignments to remove."
        return
    }

    # 3. Filter out the targeted assignment
    $remainingAssignments = [System.Collections.Generic.List[hashtable]]::new()
    $matchFound = $false

    foreach ($item in $existing) {
        $matchesGroup      = ($PSCmdlet.ParameterSetName -eq "ByGroupId" -and $item.target.groupId -eq $GroupId)
        $matchesAssignment = ($PSCmdlet.ParameterSetName -eq "ByAssignmentId" -and $item.id -eq $AssignmentId)

        if ($matchesGroup -or $matchesAssignment) {
            $matchFound = $true
            continue
        }

        # Keep non-matching assignments and rebuild clean object
        $cleanedItem = [ordered]@{
            "@odata.type"          = "#microsoft.graph.deviceHealthScriptAssignment"
            "target"               = $item.target
            "runSchedule"          = $item.runSchedule
            "runRemediationScript" = $item.runRemediationScript
        }
        $remainingAssignments.Add($cleanedItem)
    }

    if (-not $matchFound) {
        $targetIdentifier = if ($PSCmdlet.ParameterSetName -eq "ByGroupId") { "GroupId $GroupId" } else { "AssignmentId $AssignmentId" }
        Write-Warning "No matching assignment found for $targetIdentifier on script $ScriptId."
        return
    }

    # 4. POST the updated assignment list
    $body = @{
        "deviceHealthScriptAssignments" = $remainingAssignments
    } | ConvertTo-Json -Depth 10

    try {
        Invoke-MgGraphRequest -Method POST -Uri $assignUri -Body $body -ContentType "application/json"
        Write-Host "Successfully updated assignments for Remediation Script: $ScriptId" -ForegroundColor Green
    }
    catch {
        Write-Error "Failed to update assignments: $_"
    }
}
