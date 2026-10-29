function Get-DefenderDeviceVulns {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [string]$ComputerName
    )

    $sanitizedName = $ComputerName -replace '\\', '\\' -replace "'", "\'"

    $uri = "https://graph.microsoft.com/beta/security/runHuntingQuery"

    # Defender DeviceName is often the FQDN, so match the short name or any domain suffix
    $query = @(
        "let vulns = DeviceTvmSoftwareVulnerabilities"
        "   | where VulnerabilitySeverityLevel in ('Critical', 'High')"
        "   | where DeviceName =~ '$sanitizedName' or DeviceName startswith '$sanitizedName.'"
        "   | summarize CveIds = make_set(CveId),"
        "               CveCount = dcount(CveId),"
        "               HighestSeverity = max(case(VulnerabilitySeverityLevel == 'Critical', 4, VulnerabilitySeverityLevel == 'High', 3, VulnerabilitySeverityLevel == 'Medium', 2, 1))"
        "     by DeviceId, DeviceName, SoftwareVendor, SoftwareName, SoftwareVersion;"
        "vulns"
        "| join kind=leftouter (DeviceTvmSoftwareEvidenceBeta | where DeviceId in ((vulns | distinct DeviceId))) on DeviceId, SoftwareVendor, SoftwareName, SoftwareVersion"
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

    foreach ($row in $response.results) {
        $obj = [ordered]@{ PSTypeName = 'Defender.DeviceVulnerability' }

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
}
