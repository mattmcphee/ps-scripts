$clientId = 'd7708ecc-2a0f-4773-a38a-ff197163f5fe'
$tenantId = '9a2a4ae5-8ac1-460b-90f0-bb3c8516df35'
$customerId = '1cdf0bbe-ffcf-4a42-9bb4-02e9da04e970'

$entraTokenParams = @{
    ClientId = $clientId
    TenantId = $tenantId
    Scopes   = @('http://patchmypc.onmicrosoft.com/pmpc-cloud-prod/user_impersonation')
}
$entraToken = (Get-MsalToken @entraTokenParams).AccessToken

$pmpToken = Invoke-RestMethod `
    -Uri "https://us.portal.patchmypc.com/api/auth/token/$customerId" `
    -Method Get `
    -Headers @{
        Authorization = "Bearer $entraToken"
        Accept        = 'application/json'
    }

$pmpHeaders = @{
    Authorization                 = "Bearer $pmpToken"
    Accept                        = 'application/json'
    'reporting-dashboard-context' = 'software.userapps'
}

$pmpUri = 'https://us.portal.patchmypc.com/api/devices/dashboard/page/items.software.userapps.viewalluserapplications'

$params = @{
    name            = 'items.software.userapps.viewalluserapplications'
    pageNumber      = 1
    take            = 100
    nextLink        = ''
    sortBy          = ''
    sortAsc         = 'false'
    globalFilter    = ''
    useToggleFilter = 'false'
}

$QueryString = ($params.GetEnumerator() | ForEach-Object {
    '{0}={1}' -f [uri]::EscapeDataString($_.Key), [uri]::EscapeDataString([string]$_.Value)
}) -join '&'

$inv = Invoke-RestMethod `
    -Uri "${pmpUri}?${QueryString}" `
    -Method Get `
    -Headers $pmpHeaders
