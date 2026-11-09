function Get-DefenderAsrBlocks {
    [CmdletBinding()]
    param (
        # Timespan - 1 hour, 1 day, 7 days or 30 days
        [Parameter()]
        [ValidateSet('PT1H', 'P1D', 'P7D', 'P30D')]
        [string]$Timespan
    )

    $uri = 'https://graph.microsoft.com/v1.0/security/runHuntingQuery'

    $query = @(
        'DeviceEvents'
        '| where ActionType startswith "AsrUntrusted"'
        '| where ActionType endswith "Blocked"'
        '| project Timestamp, DeviceName, FileName, FolderPath, InitiatingProcessFileName, InitiatingProcessFolderPath, InitiatingProcessCommandLine, InitiatingProcessCreationTime, InitiatingProcessAccountName, InitiatingProcessParentFileName'
    ) -join "`n"

    $body = @{
        Query    = $Query
        Timespan = $Timespan
    } | ConvertTo-Json -Compress

    $requestArgs = @{
        Method      = 'POST'
        Uri         = $uri
        Body        = $body
        ContentType = 'application/json; charset=utf-8'
        ErrorAction = 'Stop'
        OutputType  = 'PSObject'
    }

    (Invoke-MgGraphRequest @requestArgs).results
}
