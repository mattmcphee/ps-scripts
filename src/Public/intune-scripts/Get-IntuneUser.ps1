function Get-IntuneUser {
    param(
        # UserPrincipalName - filter results by UPN; supports wildcards (* and ?)
        [Parameter(Mandatory=$false)]
        [string]$UserPrincipalName,

        # AllProperties - will add every user property to the returned objects
        [Parameter(Mandatory=$false)]
        [switch]$AllProperties
    )

    # 999 is the max page size for /users (default is 100)
    $query = @('$top=999')

    # only get the basic fields
    if (-not $AllProperties) {
        $query += '$select=id,displayName,userPrincipalName,jobTitle'
    }

    $needsClientFilter = $false

    if ($UserPrincipalName) {
        $wildcardIndex = $UserPrincipalName.IndexOfAny([char[]]'*?')
        $filter = $null
        if ($wildcardIndex -lt 0) {
            $filter = "userPrincipalName eq '$($UserPrincipalName.Replace("'", "''"))'"
        } elseif ($wildcardIndex -gt 0) {
            $prefix = $UserPrincipalName.Substring(0, $wildcardIndex).Replace("'", "''")
            $filter = "startswith(userPrincipalName,'$prefix')"
            # Only "PREFIX*" is fully handled by Graph; anything else needs a -like check
            $needsClientFilter = $UserPrincipalName -ne ($UserPrincipalName.Substring(0, $wildcardIndex) + '*')
        } else {
            $needsClientFilter = $true  # leading wildcard: Graph can't filter this
        }
        if ($filter) {
            # Encode so characters like '#' in guest UPNs (#EXT#) aren't treated as a URI fragment
            $query += '$filter=' + [uri]::EscapeDataString($filter)
        }
    }

    $uri = 'https://graph.microsoft.com/v1.0/users?' + ($query -join '&')

    while ($uri) {
        $response = Invoke-MgGraphRequest -Method GET -Uri $uri

        foreach ($user in $response.value) {
            if ($needsClientFilter -and $user.userPrincipalName -notlike $UserPrincipalName) {
                continue
            }

            if ($AllProperties) {
                [PSCustomObject]$user
            } else {
                [PSCustomObject]@{
                    ID                  = $user.id
                    UserPrincipalName   = $user.userPrincipalName
                    DisplayName         = $user.displayName
                    JobTitle            = $user.jobTitle
                }
            }
        }

        # Move to next page if results exceed the default page size
        $uri = $response.'@odata.nextLink'
    }
}
