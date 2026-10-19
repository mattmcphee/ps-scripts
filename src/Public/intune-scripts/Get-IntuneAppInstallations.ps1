function Get-IntuneAppInstallations {
    param(
        # DisplayName
        [Parameter(Mandatory=$false)]
        [string]$DisplayName,

        # MinVersion
        [Parameter(Mandatory=$false)]
        [version]$MinVersion,

        # MaxVersion
        [Parameter(Mandatory=$false)]
        [version]$MaxVersion,

        # DbPath
        [Parameter(Mandatory=$false)]
        [string]$DbPath = "C:\sources\sqlite\IntuneAppInstalledInventory.db"
    )

    Import-Module PSSQLITE

    $query = @(
        'SELECT ApplicationName, ApplicationPublisher, ApplicationVersion, DeviceName, EmailAddress'
        'FROM installations'
    )

    $sqlParams = @{}

    if ($DisplayName) {
        $query += 'WHERE ApplicationName LIKE @DisplayName'
        $sqlParams.DisplayName = $DisplayName.Replace('*', '%').Replace('?', '_')
    }

    $queryString = $query -join "`n"

    $results = Invoke-SqliteQuery -DataSource $DbPath -Query $queryString -SqlParameters $sqlParams

    if ($MinVersion -or $MaxVersion) {
        $results = $results | Where-Object {
            $rowVersion = $null

            if (-not [version]::TryParse($_.ApplicationVersion, [ref]$rowVersion)) {
                return $false
            }

            (-not $MinVersion -or $rowVersion -ge $MinVersion) -and
            (-not $MaxVersion -or $rowVersion -le $MaxVersion)
        }
    }

    $results
}
