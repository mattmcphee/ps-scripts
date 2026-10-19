function Update-IntuneAppInventoryDb {
    Import-Module PSSQLite

    $dbPath = 'C:\sources\sqlite\IntuneAppInstalledInventory.db'
    $dbDir = Split-Path $dbPath -Parent
    $exportJobsUri = 'https://graph.microsoft.com/beta/deviceManagement/reports/exportJobs'
    $workDir = Join-Path ([IO.Path]::GetTempPath()) ([guid]::NewGuid().ToString('N'))
    $buildDb = Join-Path $dbDir ("inventory-{0}.db" -f [guid]::NewGuid().ToString('N'))

    if (-not (Get-MgContext)) {
        throw 'Connect to Microsoft Graph before running the refresh.'
    }

    New-Item -ItemType Directory -Path $dbDir -Force | Out-Null
    New-Item -ItemType Directory -Path $workDir | Out-Null

    try {
        # 1. Request a complete inventory export
        $body = @{
            reportName = 'AppInvRawData'
            format = 'csv'
        } | ConvertTo-Json -Depth 5

        $jobGraphRequestArgs = @{
            Method      = 'POST'
            Uri         = $exportJobsUri
            Body        = $body
            ContentType = 'application/json'
            OutputType  = 'Hashtable'
        }
        $job = Invoke-MgGraphRequest @jobGraphRequestArgs

        if (-not $job['id']) {
            throw 'Graph did not return an export job ID.'
        }

        $jobUri = "$exportJobsUri/$([uri]::EscapeDataString($job['id']))"
        $deadline = (Get-Date).AddMinutes(20)

        # 2. Poll until the report is ready
        do {
            Start-Sleep -Seconds 15

            $job = Invoke-MgGraphRequest -Method GET -Uri $jobUri -OutputType Hashtable

            if ($job['status'] -eq 'failed') {
                throw 'Intune report export failed.'
            }

            if ((Get-Date) -ge $deadline) {
                throw 'Timed out waiting for Intune export.'
            }
        } until ($job['status'] -eq 'completed')

        if (-not $job['url']) {
            throw 'Export completed without a download URL.'
        }

        # 3. Download and extract
        $zipPath = Join-Path $workDir 'inventory.zip'
        $csvDir = Join-Path $workDir 'csv'
        if (-not (Test-Path $csvDir)) {
            $null = New-Item -Path $csvDir -ItemType Directory
        }

        curl.exe -L -o $zipPath $job['url']
        Expand-Archive -LiteralPath $zipPath -DestinationPath $csvDir

        $csvFiles = @(Get-ChildItem -LiteralPath $csvDir -Filter '*.csv' -File -Recurse)

        if ($csvFiles.Count -eq 0) {
            throw 'No CSV files were found in the export.'
        }

        # 4. Create a fresh SQLite database
        $connection = New-SQLiteConnection -DataSource $buildDb

        try {
            $schema = $connection.CreateCommand()
            $schema.CommandText = @(
                'CREATE TABLE installations ('
                    'ApplicationKey TEXT,'
                    'ApplicationId TEXT,'
                    'ApplicationName TEXT NOT NULL,'
                    'ApplicationPublisher TEXT,'
                    'ApplicationShortVersion TEXT,'
                    'ApplicationVersion TEXT,'
                    'DeviceId TEXT,'
                    'DeviceName TEXT,'
                    'OSDescription TEXT,'
                    'OSVersion TEXT,'
                    'Platform TEXT,'
                    'UserId TEXT,'
                    'EmailAddress TEXT,'
                    'UserName TEXT'
                ');'
                'CREATE TABLE cache_info ('
                    'RefreshedUtc TEXT,'
                    'RowCount INTEGER'
                ');'
            ) -join "`n"
            [void]$schema.ExecuteNonQuery()
            $schema.Dispose()

            # 5. Bulk import using a single transaction
            $transaction = $connection.BeginTransaction()
            $count = 0

            try {
                $insert = $connection.CreateCommand()
                $insert.Transaction = $transaction
                $insert.CommandText = @(
                    'INSERT INTO installations'
                    '('
                        'ApplicationKey,'
                        'ApplicationId,'
                        'ApplicationName,'
                        'ApplicationPublisher,'
                        'ApplicationShortVersion,'
                        'ApplicationVersion,'
                        'DeviceId,'
                        'DeviceName,'
                        'OSDescription,'
                        'OSVersion,'
                        'Platform,'
                        'UserId,'
                        'EmailAddress,'
                        'UserName'
                    ')'
                    'VALUES'
                    '('
                        '@ApplicationKey,'
                        '@ApplicationId,'
                        '@ApplicationName,'
                        '@ApplicationPublisher,'
                        '@ApplicationShortVersion,'
                        '@ApplicationVersion,'
                        '@DeviceId,'
                        '@DeviceName,'
                        '@OSDescription,'
                        '@OSVersion,'
                        '@Platform,'
                        '@UserId,'
                        '@EmailAddress,'
                        '@UserName'
                    ');'
                ) -join "`n"

                $columns = @(
                    "ApplicationKey",
                    "ApplicationId",
                    "ApplicationName",
                    "ApplicationPublisher",
                    "ApplicationShortVersion",
                    "ApplicationVersion",
                    "DeviceId",
                    "DeviceName",
                    "OSDescription",
                    "OSVersion",
                    "Platform",
                    "UserId",
                    "EmailAddress",
                    "UserName"
                )

                foreach ($column in $columns) {
                    [void]$insert.Parameters.AddWithValue("@$column", '')
                }

                $insert.Prepare()

                foreach ($csvFile in $csvFiles) {
                    # Validate the exported schema
                    $firstRow = Import-Csv -LiteralPath $csvFile.FullName | Select-Object -First 1

                    if ($null -eq $firstRow) {
                        throw "Empty CSV: $($csvFile.Name)"
                    }

                    foreach ($column in $columns) {
                        if ($column -notin $firstRow.PSObject.Properties.Name) {
                            throw "Missing CSV column: $column"
                        }
                    }

                    Import-Csv -LiteralPath $csvFile.FullName |
                        ForEach-Object {
                            $row = $_

                            foreach ($column in $columns) {
                                $insert.Parameters["@$column"].Value = $row.$column
                            }

                            [void]$insert.ExecuteNonQuery()
                            $count++
                        }
                }

                if ($count -eq 0) {
                    throw 'Inventory contained no records.'
                }

                $insert.Dispose()

                # 6. Build indexes after the import
                $index = $connection.CreateCommand()
                $index.Transaction = $transaction
                $index.CommandText = @(
                    'CREATE INDEX idx_app_version'
                    'ON installations(ApplicationName COLLATE NOCASE, ApplicationVersion);'
                    'CREATE INDEX idx_device_name'
                    'ON installations(DeviceName COLLATE NOCASE);'
                ) -join "`n"
                [void]$index.ExecuteNonQuery()
                $index.Dispose()

                # Store refresh metadata
                $meta = $connection.CreateCommand()
                $meta.Transaction = $transaction
                $meta.CommandText = @(
                    'INSERT INTO cache_info (RefreshedUtc, RowCount)'
                    'VALUES (@RefreshedUtc, @RowCount);'
                ) -join "`n"
                [void]$meta.Parameters.AddWithValue(
                    '@RefreshedUtc', [DateTime]::UtcNow.ToString('o')
                )
                [void]$meta.Parameters.AddWithValue('@RowCount', $count)
                [void]$meta.ExecuteNonQuery()
                $meta.Dispose()

                $transaction.Commit()
            } catch {
                $transaction.Rollback()
                throw
            } finally {
                $transaction.Dispose()
            }
        } finally {
            $connection.Close()
            $connection.Dispose()
            [System.Data.SQLite.SQLiteConnection]::ClearAllPools()
            [GC]::Collect()
            [GC]::WaitForPendingFinalizers()
        }

        # 7. Publish only after a successful import
        if (Test-Path -LiteralPath $dbPath) {
            [IO.File]::Replace($buildDb, $dbPath, [NullString]::Value)
        } else {
            [IO.File]::Move($buildDb, $dbPath)
        }

        Write-Output "Imported $count application records to $dbPath"
    } finally {
        if (Test-Path -LiteralPath $workDir) {
            Remove-Item -LiteralPath $workDir -Recurse -Force
        }

        if (Test-Path -LiteralPath $buildDb) {
            Remove-Item -LiteralPath $buildDb -Force
        }
    }
}
