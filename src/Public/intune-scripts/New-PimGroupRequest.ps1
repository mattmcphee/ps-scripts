function New-PimGroupRequest {
    [CmdletBinding(SupportsShouldProcess)]
    param (
        # GroupNameOrId - name or id of the pim group you're requesting membership for
        [Parameter(Mandatory)]
        [ArgumentCompleter({
            $wordToComplete = $args[2] # third arg is the word to complete for ArgumentCompleter

            'rbac_Intune_ApplicationManager_EndpointGroups_PIM',
            'rbac_Intune_EndpointPrivilegeManager_EndpointGroups_PIM',
            'rbac_Intune_EndpointPrivilegeReader_EndpointGroups_PIM',
            'rbac_Intune_EndpointSecurityManager_EndpointGroups_PIM',
            'rbac_Intune_HelpdeskLevel1_Directory',
            'rbac_Intune_HelpdeskLevel1_EndpointGroups_PIM',
            'rbac_Intune_HelpDeskOperator_EndpointGroups_PIM',
            'rbac_Intune_IntuneRoleAdministrator_EndpointGroups_PIM',
            'rbac_Intune_PolicyandProfileManager_EndpointGroups_PIM' |
            Where-Object { $_ -like "$wordToComplete*" } |
            ForEach-Object { [System.Management.Automation.CompletionResult]::new("'$_'", $_, 'ParameterValue', $_) }
        })]
        [string]$GroupNameOrId,

        # TicketNumber - topdesk ticket number
        [Parameter(Mandatory)]
        [string]$TicketNumber,

        # Description - justification for request
        [Parameter(Mandatory)]
        [string]$Description,

        # DurationHours - duration to request role for (defaults to 8 hours)
        [Parameter(Mandatory=$false)]
        [ValidateRange(1,8)]
        [int]$DurationHours = 8
    )

    $baseUri = 'https://graph.microsoft.com/v1.0'

    # Resolve group and current user in a single round trip
    if ([guid]::TryParse($GroupNameOrId, [ref][guid]::Empty)) {
        $groupUrl = "/groups/$GroupNameOrId`?`$select=id,displayName"
    } else {
        $filter   = [uri]::EscapeDataString("displayName eq '$($GroupNameOrId.Replace("'", "''"))'")
        $groupUrl = "/groups?`$filter=$filter&`$select=id,displayName"
    }

    $batchBody = @{
        requests = @(
            @{ id = 'me';    method = 'GET'; url = '/me?$select=id' }
            @{ id = 'group'; method = 'GET'; url = $groupUrl }
        )
    }
    $batchResponse = Invoke-MgGraphRequest -Method POST -Uri "$baseUri/`$batch" -Body $batchBody -ErrorAction Stop

    # Sub-requests don't raise errors on their own, so check each status
    $results = @{}
    foreach ($item in $batchResponse.responses) {
        if ($item.status -ge 400) {
            throw "Batch request '$($item.id)' failed ($($item.status)): $($item.body.error.message)"
        }
        $results[$item.id] = $item.body
    }

    $user = $results['me']

    # GUID lookup returns the group itself; name lookup returns a collection
    $groups = @(
        if ($results['group'].ContainsKey('value')) {
            $results['group'].value
        } else {
            $results['group']
        }
    )

    if ($groups.Count -ne 1) {
        throw "Expected one group '$GroupNameOrId'; found $($groups.Count)."
    }

    $groupId   = $groups[0].id
    $groupName = $groups[0].displayName

    $ticketSystem = 'TopDesk'
    $duration     = [Xml.XmlConvert]::ToString([TimeSpan]::FromHours($DurationHours))

    $body = @{
        action        = 'selfActivate'
        accessId      = 'member'
        principalId   = $user.id
        groupId       = $groupId
        justification = $Description
        ticketInfo    = @{
            ticketNumber = $TicketNumber
            ticketSystem = $ticketSystem
        }
        scheduleInfo  = @{
            startDateTime = [datetime]::UtcNow.ToString('o')
            expiration    = @{ 
                type = 'afterDuration'
                duration = $duration
            }
        }
    }

    if ($PSCmdlet.ShouldProcess("$groupId ($groupName)", 'Request PIM group assignment')) {
        Invoke-MgGraphRequest -Method POST `
            -Uri "$baseUri/identityGovernance/privilegedAccess/group/assignmentScheduleRequests" `
            -Body $body `
            -ErrorAction Stop
    }
}
