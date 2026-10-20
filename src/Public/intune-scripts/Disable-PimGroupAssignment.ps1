
function Disable-PIMGroupAssignment {
    [CmdletBinding(SupportsShouldProcess)]
    param(
        [Parameter(Mandatory)]
        [string]$GroupNameOrId
    )

    $ErrorActionPreference = 'Stop'
    $baseUri = 'https://graph.microsoft.com/v1.0'

    # Resolve group name
    $guidRegexPattern = '^[0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{12}$'
    if ($GroupNameOrId -match $guidRegexPattern) {
        $groupId = $GroupNameOrId
    } else {
        $filter = [uri]::EscapeDataString("displayName eq '$GroupNameOrId'")
    }

    $groupNameUri = "$baseUri/groups?`$filter=$filter&`$select=id,displayName"
    $response = Invoke-MgGraphRequest -Method GET -Uri $groupNameUri
    $groups = $response.value

    if ($groups.Count -ne 1) {
        throw "Expected one group '$GroupNameOrId'; found $($groups.Count)."
    }

    $groupId = $groups[0].id

    # Retrieve current user's active PIM group assignments
    $currentPimGroupAssignmentsUri = "$baseUri/identityGovernance/privilegedAccess/group/assignmentScheduleInstances/filterByCurrentUser(on='principal')"

    $assignments = [System.Collections.Generic.List[PSCustomObject]]::new()

    do {
        $response = Invoke-MgGraphRequest -Method GET -Uri $currentPimGroupAssignmentsUri
        $assignments.Add($response.value)
        $currentPimGroupAssignmentsUri = $response.'@odata.nextLink'
    } while ($currentPimGroupAssignmentsUri)

    # Match group and access type
    $assignmentMatches = $assignments | Where-Object {
        ($_.groupId -eq $groupId) -and
        ($_.accessId -eq 'member') -and
        ($_.assignmentType -eq 'activated')
    }

    if ($assignmentMatches.Count -eq 0) {
        throw "No active PIM assignment found for '$groupName'."
    }

    if ($assignmentMatches.Count -gt 1) {
        throw "Multiple active PIM assignments found for '$groupName'."
    }

    $assignment = $assignmentMatches[0]

    # Submit self-deactivation
    $body = @{
        action      = 'selfDeactivate'
        groupId     = $groupId
        principalId = $assignment.principalId
        accessId    = 'member'
        scheduleInfo = @{
            startDateTime = (Get-Date).ToUniversalTime().ToString('o')
            expiration = @{
                type = 'NoExpiration'
            }
        }
    }

    if ($PSCmdlet.ShouldProcess($groupName, 'Deactivate PIM group assignment')) {
        $pimGroupRequestUri = "$baseUri/identityGovernance/privilegedAccess/group/assignmentScheduleRequests"

        $result = Invoke-MgGraphRequest `
            -Method POST `
            -Uri $pimGroupRequestUri `
            -Body ($body | ConvertTo-Json -Depth 10) `
            -ContentType 'application/json'

        [PSCustomObject]@{
            GroupName = $groupName
            AccessId  = $result.accessId
            RequestId = $result.id
            Status    = $result.status
        }
    }
}
