function New-PimGroupRequest {
    [CmdletBinding(SupportsShouldProcess)]
    param (
        [Parameter(Mandatory)]
        [string]$GroupNameOrId,

        [Parameter(Mandatory)]
        [string]$TicketNumber,

        [Parameter(Mandatory)]
        [string]$Description,

        [Parameter(Mandatory=$false)]
        [ValidateRange(1,8)]
        [int]$DurationHours = 8
    )

    $baseUri = 'https://graph.microsoft.com/v1.0'

    # Resolve group name
    $groupId = $null
    $guidRegexPattern = '^[0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{12}$'
    if ($GroupNameOrId -match $guidRegexPattern) {
        $groupId = $GroupNameOrId
    } else {
        $filter = [uri]::EscapeDataString("displayName eq '$GroupNameOrId'")
        $groupNameUri = "$baseUri/groups?`$filter=$filter&`$select=id,displayName"
        $response = Invoke-MgGraphRequest -Method GET -Uri $groupNameUri
        $groups = $response.value
        if ($groups.Count -ne 1) {
            throw "Expected one group '$GroupNameOrId'; found $($groups.Count)."
        }
        $groupId = $groups[0].id
    }

    $ticketSystem = 'TopDesk'
    $duration     = [Xml.XmlConvert]::ToString([TimeSpan]::FromHours($DurationHours))

    $user = Invoke-MgGraphRequest -Method GET -Uri "$baseUri/me?`$select=id" -ErrorAction Stop

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

    if ($PSCmdlet.ShouldProcess($groupId, 'Request PIM group assignment')) {
        Invoke-MgGraphRequest -Method POST `
            -Uri "$baseUri/identityGovernance/privilegedAccess/group/assignmentScheduleRequests" `
            -Body $body `
            -ErrorAction Stop
    }
}
