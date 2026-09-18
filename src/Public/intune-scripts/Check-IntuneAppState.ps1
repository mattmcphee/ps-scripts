function Check-IntuneAppState {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [string]$LogicAppUrl,
        [Parameter(Mandatory=$false)]
        [string]$StateFilePath = "C:\ProgramData\IntuneMonitor\app_state.csv"
    )

    # Ensure data directory exists
    $directory = Split-Path -Path $StateFilePath -Parent
    if (-not (Test-Path $directory)) {
        $null = New-Item -Path $directory -ItemType Directory -Force
    }

    # 1. Collect current Win32 app registry state
    $regBasePath = "HKLM:\SOFTWARE\Microsoft\IntuneManagementExtension\Win32Apps"
    $currentApps = @()

    if (Test-Path $regBasePath) {
        # Scan subkeys 2 levels deep: Win32Apps\<ContextGUID>\<AppGUID>
        $contextKeys = Get-ChildItem -Path $regBasePath -ErrorAction SilentlyContinue

        foreach ($context in $contextKeys) {
            $appKeys = Get-ChildItem -Path $context.PSPath -ErrorAction SilentlyContinue

            foreach ($app in $appKeys) {
                # Exclude special IME utility subkeys like GRS or Reporting
                if ($app.PSChildName -match '^[0-9a-fA-F]{8}-([0-9a-fA-F]{4}-){3}[0-9a-fA-F]{12}$') {
                    $installExCode = $app.GetValue("InstallExCode", $null)
                    $exitCode      = $app.GetValue("ExitCode", $null)

                    if ($null -ne $installExCode) {
                        $currentApps += [PSCustomObject]@{
                            AppId         = $app.PSChildName
                            ContextId     = $context.PSChildName
                            ExitCode      = [string]$exitCode
                            InstallExCode = [string]$installExCode
                            Status        = if ($installExCode -eq 0) { "Success" } else { "Failed" }
                            LastEvaluated = (Get-Date).ToString("yyyy-MM-dd HH:mm:ss")
                        }
                    }
                }
            }
        }
    }

    # 2. Check if a baseline snapshot exists
    if (-not (Test-Path $StateFilePath)) {
        # First run: Save baseline without firing historical alerts
        $currentApps | Export-Csv -Path $StateFilePath -NoTypeInformation
        Write-Host "Baseline state snapshot created with $($currentApps.Count) app entries." -ForegroundColor Cyan
        exit 0
    }

    # 3. Load previous state and detect new or changed failures
    $previousApps = Import-Csv -Path $StateFilePath
    $previousLookup = @{}
    foreach ($item in $previousApps) {
        $previousLookup[$item.AppId] = $item
    }

    foreach ($app in $currentApps) {
        if ($app.Status -eq "Failed") {
            $isNewFailure = $false

            if (-not $previousLookup.ContainsKey($app.AppId)) {
                # Brand new app targeted that failed on first attempt
                $isNewFailure = $true
            }
            elseif ($previousLookup[$app.AppId].Status -ne "Failed" -or 
                    $previousLookup[$app.AppId].InstallExCode -ne $app.InstallExCode) {
                # App previously succeeded or had a different error code
                $isNewFailure = $true
            }

            if ($isNewFailure) {
                Write-Host "New failure detected for App ID: $($app.AppId)" -ForegroundColor Red

                # Format Intune error code to Hex representation if negative
                $hexError = if ([int64]$app.InstallExCode -lt 0) {
                    "0x{0:X8}" -f ([int64]$app.InstallExCode -band 0xFFFFFFFF)
                } else {
                    $app.InstallExCode
                }

                $payload = @{
                    deviceName = $env:COMPUTERNAME
                    appName    = "Win32 App (ID: $($app.AppId))"
                    errorCode  = "Installer Exit: $($app.ExitCode) | Intune HRESULT: $hexError"
                    timestamp  = $app.LastEvaluated
                } | ConvertTo-Json

                try {
                    Invoke-RestMethod -Uri $LogicAppUrl -Method Post -ContentType "application/json" -Body $payload
                    Write-Host "Alert dispatched to Logic App." -ForegroundColor Green
                }
                catch {
                    Write-Error "Failed to send alert: $_"
                }
            }
        }
    }

    # 4. Update the CSV snapshot to the current state
    $currentApps | Export-Csv -Path $StateFilePath -NoTypeInformation
}