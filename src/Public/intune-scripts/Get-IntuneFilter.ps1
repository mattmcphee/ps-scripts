function Get-IntuneFilter {
    [CmdletBinding()]
    param(
        # FilterName - filter display name, supports wildcards e.g. '3D*'
        [Parameter()]
        [string]$FilterName = '*'
    )

    # assignment filters are only available in beta
    $uri = 'https://graph.microsoft.com/beta/deviceManagement/assignmentFilters'

    while ($uri) {
        $response = Invoke-MgGraphRequest -Method GET -Uri $uri -ErrorAction Stop

        foreach ($filter in $response.value) {
            if ($filter.displayName -notlike $FilterName) {
                continue
            }

            [PSCustomObject]@{
                DisplayName    = $filter.displayName
                Id             = $filter.id
                Platform       = $filter.platform
                ManagementType = $filter.assignmentFilterManagementType
                Description    = $filter.description
                Rule           = $filter.rule
            }
        }

        $uri = $response.'@odata.nextLink'
    }
}
