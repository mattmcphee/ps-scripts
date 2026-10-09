function New-PimRequest {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory)]
        [string]$TicketNumber,

        [Parameter(Mandatory)]
        [string]$Description
    )

    $tenantId     = '9a2a4ae5-8ac1-460b-90f0-bb3c8516df35'
    $groupId      = 'c385f88e-372b-4a3a-98d4-0d98cabb0916'
    $ticketSystem = 'TopDesk'
    $duration     = 'PT8H'
    $scopes       = 'Group.Read.All'

    $ctx = Get-MgContext
    if (-not $ctx -or $ctx.TenantId -ne $tenantId -or ($scopes | Where-Object { $_ -notin $ctx.Scopes })) {
        Connect-MgGraph -TenantId $tenantId -Scopes $scopes -ContextScope Process -NoWelcome -ErrorAction Stop
    }

    $user = Invoke-MgGraphRequest -Method GET -Uri 'v1.0/me?$select=id' -ErrorAction Stop

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

    Invoke-MgGraphRequest -Method POST `
        -Uri 'v1.0/identityGovernance/privilegedAccess/group/assignmentScheduleRequests' `
        -Body $body -ErrorAction Stop
}
