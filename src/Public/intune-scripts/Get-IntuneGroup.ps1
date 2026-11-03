function Get-IntuneGroup {
    [CmdletBinding()]
    param (
        # Name - name of the group to search for in entra
        [Parameter(Mandatory=$false)]
        [string]$DisplayName,

        # AllProperties - will return all group properties on the object
        [Parameter(Mandatory=$false)]
        [switch]$AllProperties
    )

    $query = @('$top=999')

    # only get the basic fields
    if (-not $AllProperties) {
        $query += '$select=id,displayName'
    }

    # Narrow results server-side using the literal portion of the -like pattern.
    # The client-side -like check below still guarantees exact wildcard semantics.
    if ($DisplayName) {
        $wildcardIndex = $DisplayName.IndexOfAny([char[]]'*?[`')
        $literal = if ($wildcardIndex -lt 0) { $DisplayName } else { $DisplayName.Substring(0, $wildcardIndex) }
        $escaped = $literal.Replace("'", "''")

        $filter = if ($wildcardIndex -lt 0) {
            "displayName eq '$escaped'"
        } elseif ($literal) {
            "startswith(displayName,'$escaped')"
        }

        if ($filter) {
            $query += '$filter=' + [uri]::EscapeDataString($filter)
        }
    }

    $uri = "https://graph.microsoft.com/v1.0/groups?" + ($query -join '&')

    while ($uri) {
        $response = Invoke-MgGraphRequest -Method GET -Uri $uri

        foreach ($group in $response.value) {
            if ($DisplayName -and $group.displayName -notlike $DisplayName) {
                continue
            }

            if ($AllProperties) {
                [PSCustomObject]$group
            } else {
                [PSCustomObject]@{
                    ID          = $group.id
                    DisplayName = $group.displayName
                }
            }
        }

        # Move to next page if results exceed the default page size
        $uri = $response.'@odata.nextLink'
    }
}
