function Get-CompanyPortalStatus {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [string[]]$ComputerName,

        [Parameter(Mandatory)]
        [string]$CsvPath,

        [Parameter(Mandatory=$false)]
        [ValidateRange(1, 256)]
        [int]$ThrottleLimit = 8,

        [Parameter(Mandatory=$false)]
        [ValidateRange(1000, 60000)]
        [int]$Timeout = 5000
    )

    $computers = @(
        $ComputerName |
            Where-Object { -not [string]::IsNullOrWhiteSpace($_) } |
            ForEach-Object { $_.Trim() } |
            Select-Object -Unique
    )

    if ($computers.Count -eq 0) {
        throw 'No computer names supplied.'
    }

    $sessionOption = New-PSSessionOption -OpenTimeout $Timeout

    $results = @(
        Invoke-Command `
        -ComputerName $computers `
        -ThrottleLimit $ThrottleLimit `
        -SessionOption $sessionOption `
        -ErrorAction SilentlyContinue `
        -ScriptBlock {
            $packageName = 'Microsoft.CompanyPortal'
            $systemInstalled = $null
            $userInstalled = $null

            # Check device-level provisioning
            try {
                $systemInstalled = @(
                    Get-AppxProvisionedPackage -Online -ErrorAction Stop |
                        Where-Object DisplayName -eq $packageName
                ).Count -gt 0
            } catch {
                $systemInstalled = $null
            }

            # Get last logged-on user's SID
            try {
                $logonInfo = Get-ItemProperty `
                    -Path 'HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Authentication\LogonUI' `
                    -ErrorAction Stop

                $user = $logonInfo.LastLoggedOnUserSID

                if (-not $user) {
                    $user = $logonInfo.LastLoggedOnSAMUser
                }

                if (-not $user) {
                    $user = $logonInfo.LastLoggedOnUser
                }

                if ($user) {
                    $userInstalled = @(
                        Get-AppxPackage `
                            -Name $packageName `
                            -User $user `
                            -ErrorAction Stop
                    ).Count -gt 0
                }
            } catch {
                $userInstalled = $null
            }

            [PSCustomObject]@{
                SystemInstalled = $systemInstalled
                UserInstalled   = $userInstalled
            }
        }
    )

    # Index results for efficient lookup
    $lookup = @{}

    foreach ($result in $results) {
        $name = [string]$result.PSComputerName

        if ($name) {
            $lookup[$name] = $result

            $shortName = $name.Split('.')[0]

            if (-not $lookup.ContainsKey($shortName)) {
                $lookup[$shortName] = $result
            }
        }
    }

    # Include every requested computer, even unreachable ones
    $report = foreach ($computer in $computers) {
        $result = $lookup[$computer]

        if (-not $result) {
            $result = $lookup[$computer.Split('.')[0]]
        }

        [PSCustomObject]@{
            ComputerName    = $computer
            SystemInstalled = if ($result) { $result.SystemInstalled } else { $null }
            UserInstalled   = if ($result) { $result.UserInstalled } else { $null }
        }
    }

    $report | Export-Csv -Path $CsvPath -NoTypeInformation -Encoding UTF8

    Write-Verbose "Exported $($report.Count) records to $CsvPath"

    return $report
}
