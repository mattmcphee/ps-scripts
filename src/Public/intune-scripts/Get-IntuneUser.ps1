function Get-IntuneUser {
    param(
        # UserPrincipalName
        [Parameter(Mandatory=$false)]
        [string]$UserPrincipalName,

        # AllProperties - will add every user property to the returned objects
        [Parameter(Mandatory=$false)]
        [switch]$AllProperties
    )

    $uri = "https://graph.microsoft.com/v1.0/users"

    # only get the basic fields
    if (-not $AllProperties) {
        $uri += '?$select=id,displayName,userPrincipalName,jobTitle'
    }

    $results = [System.Collections.Generic.List[PSCustomObject]]::new()

    while ($uri) {
        $response = Invoke-MgGraphRequest -Method GET -Uri $uri

        foreach ($user in $response.value) {
            if ($UserPrincipalName -and $user.userPrincipalName -notlike $UserPrincipalName) {
                continue
            }

            if ($AllProperties) {
                $results.Add([PSCustomObject]$user)
            } else {
                $results.Add([PSCustomObject]@{
                    ID                  = $user.id
                    UserPrincipalName   = $user.userPrincipalName
                    DisplayName         = $user.displayName
                    JobTitle            = $user.jobTitle
                })
            }
        }

        # Move to next page if results exceed the default page size
        $uri = $response.'@odata.nextLink'
    }

    $results
}
