function Get-DefenderSoftwareEvidence {
    [CmdletBinding()]
    param(
        # SoftwareName
        [Parameter(Mandatory=$false)]
        [string]$SoftwareName,

        # CsvPath - exports results to this CSV file (array values are joined with '; ') instead of outputting objects
        [Parameter(Mandatory=$false)]
        [string]$CsvPath
    )

    $softwareFilter = if ($SoftwareName) {
        $sanitizedSoftwareName = $SoftwareName -replace "'", "\'"
        "| where SoftwareName contains '$sanitizedSoftwareName'"
    } else {
        ''
    }

    $uri = "https://graph.microsoft.com/beta/security/runHuntingQuery"

    $query = @(
        "let vulns = DeviceTvmSoftwareVulnerabilities"
        "    $softwareFilter"
        "    | where VulnerabilitySeverityLevel in ('Critical', 'High')"
        "    | summarize CveIds = make_set(CveId),"
        "                CveCount = dcount(CveId),"
        "                HighestSeverity = max(case(VulnerabilitySeverityLevel == 'Critical', 4, VulnerabilitySeverityLevel == 'High', 3, VulnerabilitySeverityLevel == 'Medium', 2, 1))"
        "      by DeviceId, SoftwareVendor, SoftwareName, SoftwareVersion;"
        "DeviceTvmSoftwareEvidenceBeta"
        $softwareFilter
        "| join kind=inner vulns on DeviceId, SoftwareVendor, SoftwareName, SoftwareVersion"
        "| join kind=leftouter (DeviceInfo | summarize arg_max(Timestamp, DeviceName) by DeviceId) on DeviceId"
        "| extend HighestSeverity = case(HighestSeverity == 4, 'Critical', HighestSeverity == 3, 'High', HighestSeverity == 2, 'Medium', 'Low')"
        "| project DeviceName, DeviceId, SoftwareVendor, SoftwareName, SoftwareVersion, HighestSeverity, CveCount, CveIds, DiskPaths, RegistryPaths, LastSeenTime"
        "| order by CveCount desc"
    ) -join "`n"

    $body = @{
        Query = $query
    } | ConvertTo-Json

    $reqArgs = @{
        Method      = "POST"
        Uri         = $uri
        Body        = $body
        ContentType = "application/json"
    }
    $response = Invoke-MgGraphRequest @reqArgs

    $results = foreach ($row in $response.results) {
        $obj = [ordered]@{ PSTypeName = 'Defender.SoftwareEvidence' }

        foreach ($column in $response.schema) {
            $value = $row[$column.Name]

            switch ($column.Type) {
                'DateTime' {
                    if ($value) { $value = [datetime]$value }
                }
                'Dynamic' {
                    if ($value -is [string] -and $value) {
                        try {
                            $value = $value | ConvertFrom-Json
                        } catch {
                            Write-Warning "Could not convert $value to json format."
                        }
                    }
                }
            }

            $obj[$column.Name] = $value
        }

        [PSCustomObject]$obj
    }

    if (-not $CsvPath) {
        return $results
    }

    $results | ForEach-Object {
        $flat = [ordered]@{}
        foreach ($property in $_.PSObject.Properties) {
            $value = $property.Value
            if ($value -is [System.Collections.IEnumerable] -and $value -isnot [string]) {
                $value = @($value | ForEach-Object {
                    if ($_ -is [string] -or $_ -is [ValueType]) { $_ } else { $_ | ConvertTo-Json -Compress -Depth 5 }
                }) -join '; '
            }
            $flat[$property.Name] = $value
        }
        [PSCustomObject]$flat
    } | Export-Csv -Path $CsvPath -NoTypeInformation -Encoding UTF8

    Write-Verbose "Exported $(@($results).Count) rows to $CsvPath"
}
