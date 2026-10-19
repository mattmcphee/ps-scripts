function Invoke-MgGraphRequestAll {
    [CmdletBinding()]
    param (
        # Uri
        [Parameter(Mandatory)]
        [string]$Uri
    )

    # $results = [System.Collections.Generic.List[object]]::new()

    while ($Uri) {
        $response = Invoke-MgGraphRequest `
            -Method GET `
            -Uri $Uri `
            -OutputType Hashtable `
            -ErrorAction Stop

        foreach ($item in $response['value']) {
            $item | Where-Object platform -eq 'windows' | Select-Object displayName
        }

        $Uri = $response['@odata.nextLink']
    }
}
