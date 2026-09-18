function Get-IntuneGroup {
    param (
        # Name - name of the group to search for in entra
        [Parameter(Mandatory=$false)]
        [string]$DisplayName,

        # AllProperties - will return all group properties on the object
        [Parameter(Mandatory=$false)]
        [switch]$AllProperties
    )

    $uri = "https://graph.microsoft.com/v1.0/groups"

    # only get the basic fields
    if (-not $AllProperties) {
        $uri += '?$select=id,displayName'
    }

    $results = [System.Collections.Generic.List[PSCustomObject]]::new()

    while ($uri) {
        $response = Invoke-MgGraphRequest -Method GET -Uri $uri

        foreach ($group in $response.value) {
            if ($DisplayName -and $group.displayName -notlike $DisplayName) {
                continue
            }

            if ($AllProperties) {
                $results.Add([PSCustomObject]$group)
            } else {
                $results.Add([PSCustomObject]@{
                    ID          = $group.id
                    DisplayName   = $group.displayName
                })
            }
        }

        # Move to next page if results exceed the default page size
        $uri = $response.'@odata.nextLink'
    }

    $results
}
