
function Get-DefenderQueryResults {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory, Position = 0)]
        [string]$Query,

        [Parameter()]
        [ValidateSet('PT1H', 'P1D', 'P7D', 'P30D')]
        [string]$Timespan = 'P30D'
    )

    $uri = 'https://graph.microsoft.com/v1.0/security/runHuntingQuery'

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
