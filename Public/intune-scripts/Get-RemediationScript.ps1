function Get-RemediationScript {
    $uri = "https://graph.microsoft.com/beta/deviceManagement/deviceHealthScripts"
    $scriptResults = [System.Collections.Generic.List[PSCustomObject]]::new()

    while ($uri) {
        $response = Invoke-MgGraphRequest -Method GET -Uri $uri

        foreach ($script in $response.value) {
            $scriptResults.Add([PSCustomObject]@{
                ID          = $script.id
                DisplayName = $script.displayName
                Description = $script.description
            })
        }

        # Move to next page if results exceed the default page size
        $uri = $response.'@odata.nextLink'
    }

    $scriptResults
}
