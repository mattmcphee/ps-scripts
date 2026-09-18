function Get-IntuneGroupMembers {
    param (
        # Name - name of the group to retrieve members of
        [Parameter(Mandatory=$true)]
        [string]$GroupID,

        # AllProperties - will return all properties on the object
        [Parameter(Mandatory=$false)]
        [switch]$AllProperties
    )

    $uri = "https://graph.microsoft.com/v1.0/groups/$GroupID/members"

    # only get the basic fields
    if (-not $AllProperties) {
        $uri += '?$select=id,displayName,userPrincipalName'
    }

    $results = [System.Collections.Generic.List[PSCustomObject]]::new()

    while ($uri) {
        $response = Invoke-MgGraphRequest -Method GET -Uri $uri

        foreach ($member in $response.value) {
            if ($DisplayName -and $group.displayName -notlike $DisplayName) {
                continue
            }

            if ($AllProperties) {
                $results.Add([PSCustomObject]$group)
            } else {
                $results.Add([PSCustomObject]@{
                    ID              = $group.id
                    DisplayName     = $group.displayName
                })
            }
        }

        # Move to next page if results exceed the default page size
        $uri = $response.'@odata.nextLink'
    }

    $results
}
