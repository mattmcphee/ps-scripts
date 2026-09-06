function Scrape-Logs {
    # Paths
    $logDir   = "$env:ProgramData\Microsoft\IntuneManagementExtension\Logs"
    $regBase  = "HKLM:\SOFTWARE\Microsoft\IntuneManagementExtension\Win32Apps"

    $appMap = @{}

    # Search newest logs first (AppWorkload logs hold Win32 app telemetry in modern IME builds)
    $logFiles = Get-ChildItem -Path $logDir -Filter "*.log" -ErrorAction SilentlyContinue |
    Where-Object { $_.Name -match "AppWorkload|IntuneManagementExtension" } |
    Sort-Object LastWriteTime -Descending

    foreach ($file in $logFiles) {
        # Scan for the policy sync line
        Get-Content -Path $file.FullName -ErrorAction SilentlyContinue |
        Where-Object { $_ -match 'Get policies = (\[.+?\])' } |
        ForEach-Object {
            try {
                $policies = $matches[1] | ConvertFrom-Json
                foreach ($app in $policies) {
                    if ($app.Id -and $app.Name -and -not $appMap.ContainsKey($app.Id)) {
                        $appMap[$app.Id] = $app.Name
                    }
                }
            } catch {
                # Skip partial/corrupted log entries
            }
        }
    }

    # Enumerate the registry and resolve names
    $appInventory = [System.Collections.Generic.List[PSCustomObject]]::new()

    Get-ChildItem -Path $regBase -ErrorAction SilentlyContinue | ForEach-Object {
        $context = $_.PSChildName
        Get-ChildItem -Path $_.PSPath -ErrorAction SilentlyContinue | ForEach-Object {
            $rawGuid   = $_.PSChildName
            $cleanGuid = ($rawGuid -split '_')[0] # Strips revision suffixes like _1
            $props     = Get-ItemProperty -Path $_.PSPath

            $appInventory.Add([PSCustomObject]@{
                AppGuid         = $cleanGuid
                DisplayName     = if ($appMap.ContainsKey($cleanGuid)) { $appMap[$cleanGuid] } else { "Unknown / Log Expired" }
                Scope           = if ($context -eq "00000000-0000-0000-0000-000000000000") { "Device" } else { "User" }
                ComplianceState = $props.ComplianceState
                EnforcementState= $props.EnforcementState
                InstallExCode   = $props.InstallExCode
            })
        }
    }

    # Example: Output to CSV for telemetry/monitoring
    $appInventory | Export-Csv -Path "$env:ProgramData\Win32AppInventory.csv" -NoTypeInformation
}
