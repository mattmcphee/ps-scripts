function Get-IntuneApp {
    param(
        # DisplayName
        [Parameter(Mandatory=$false)]
        [string]$DisplayName,

        # AllProperties - will add every app property to the returned objects
        [Parameter(Mandatory=$false)]
        [switch]$AllProperties
    )

    $uri = "https://graph.microsoft.com/v1.0/deviceAppManagement/mobileApps"

    # only get the basic fields
    if (-not $AllProperties) {
        $uri += '?$select=id,displayName'
    }

    $results = [System.Collections.Generic.List[PSCustomObject]]::new()

    while ($uri) {
        $response = Invoke-MgGraphRequest -Method GET -Uri $uri

        foreach ($app in $response.value) {
            if ($DisplayName -and $app.displayName -notlike $DisplayName) {
                continue
            }

            if ($AllProperties) {
                $results.Add([PSCustomObject]$app)
            } else {
                $results.Add([PSCustomObject]@{
                    ID                  = $app.id
                    DisplayName         = $app.displayName
                })
            }
        }

        # Move to next page if results exceed the default page size
        $uri = $response.'@odata.nextLink'
    }

    $results
}
