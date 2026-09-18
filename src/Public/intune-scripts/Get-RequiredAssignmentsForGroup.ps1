# Connect-MgGraph -Scopes "DeviceManagementApps.Read.All" -NoWelcome
function Get-RequiredAssignmentsForGroup {
    param (
        # GroupId
        [Parameter(Mandatory=$true)]
        [string]
        $GroupId
    )

    Write-Host "Scanning Win32 apps for 'Required' assignments to group ID: $GroupId..." -ForegroundColor Cyan

    # 2. Query endpoint directly and handle pagination
    $uri = "https://graph.microsoft.com/v1.0/deviceAppManagement/mobileApps?`$filter=isof('microsoft.graph.win32LobApp')&`$expand=assignments"
    $results = [System.Collections.Generic.List[PSCustomObject]]::new()

    while ($uri) {
        $response = Invoke-MgGraphRequest -Method GET -Uri $uri

        foreach ($app in $response.value) {
            foreach ($assignment in $app.assignments) {
                $assignedGroupId = $assignment.target.groupId

                if ($assignment.intent -eq 'required' -and $assignedGroupId -eq $GroupId) {
                    $results.Add([PSCustomObject]@{
                        AppDisplayName  = $app.displayName
                        AppId           = $app.id
                        Intent          = $assignment.intent
                        GroupId         = $assignedGroupId
                        FilterMode      = $assignment.target.filterType
                        FilterId        = $assignment.target.filterId
                    })
                }
            }
        }

        # Move to next page if results exceed the default page size
        $uri = $response.'@odata.nextLink'
    }

    # 3. Output results
    if ($results.Count -gt 0) {
        Write-Host "`nFound $($results.Count) matching Win32 application(s):" -ForegroundColor Green
        $results | Format-Table -AutoSize
    } else {
        Write-Host "`nNo Win32 applications are deployed as 'Required' to group ID: $GroupId." -ForegroundColor Yellow
    }
}
