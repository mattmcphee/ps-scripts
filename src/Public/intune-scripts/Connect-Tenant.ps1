function Connect-Tenant {
    [CmdletBinding()]
    param (
        # Environment
        [Parameter(Mandatory)]
        [ValidateSet("Prod","Dev")]
        [string]
        $Environment,
        # Scopes
        [Parameter(Mandatory=$false)]
        [string[]]
        $Scopes
    )
    
    $curContext = Get-MgContext
    if ($curContext) {
        try {
            Disconnect-MgGraph -ErrorAction Stop | Out-Null
        } catch {
            throw "Error: $($_.Exception.Message)"
        }
    }

    $tenants = @{
        "Prod" = "9a2a4ae5-8ac1-460b-90f0-bb3c8516df35"
        "Dev" = "cab2b5b9-c306-4307-a8ae-402a7693c71e"
    }

    $targetId = $tenants[$Environment]

    try {
        Get-BlockLetters $Environment | Write-Host -ForegroundColor Green
        Connect-MgGraph -TenantId $targetId -Scopes $Scopes -ContextScope 'Process' -ErrorAction Stop | Out-Null
        Get-BlockLetters 'Connected!' -Colour Green
    } catch {
        throw "Error: $($_.Exception.Message)"
    }
}
