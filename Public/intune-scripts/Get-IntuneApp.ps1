function Get-IntuneApp {
    param(
        # DisplayName
        [Parameter(Mandatory=$false)]
        [string]$DisplayName,

        # ID - one or more app guid's to lookup
        [Parameter(Mandatory=$false, ValueFromPipeline=$true, ValueFromPipelineByPropertyName=$true)]
        [Alias('AppId')]
        [string[]]$ID,

        # AllProperties - will add every app property to the returned objects
        [Parameter(Mandatory=$false)]
        [switch]$AllProperties
    )

    begin {
        $baseUri = "https://graph.microsoft.com/v1.0/deviceAppManagement/mobileApps"
        $select = if ($AllProperties) { '' } else { '?$select=id,displayName' }
        $results = [System.Collections.Generic.List[PSCustomObject]]::new()

        function Add-AppObjectToList {
            param([object]$App)

            if ($AllProperties) {
                $results.Add([PSCustomObject]$App)
            } else {
                $results.Add([PSCustomObject]@{
                    ID          = $app.id
                    DisplayName = $app.displayName
                })
            }
        }
    }

    process {
        if ($ID) {
            foreach ($appId in $ID) {
                $uri = "$baseUri/$appId$select"
                try {
                    $app = Invoke-MgGraphRequest -Method GET -Uri $uri -ErrorAction Stop
                } catch {
                    Write-Warning "Couldn't get DisplayName for $appId. $_"
                }
                Add-AppObjectToList -App $app
            }
        } else {
            $uri = "$baseUri$select"
            while ($uri) {
                try {
                    $response = Invoke-MgGraphRequest -Method GET -Uri $uri -ErrorAction Stop
                } catch {
                    Write-Warning "Couldn't get DisplayName for $appId. $_"
                }
                foreach ($app in $response.value) {
                    if ($DisplayName -and $app.displayName -notlike $DisplayName) {
                        continue
                    }
                    Add-AppObjectToList -App $app
                }
                $uri = $response.'@odata.nextLink'
            }
        }
    }

    end {
        $results
    }
}
