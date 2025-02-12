function Write-Log {
    param(
        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [string]$Message,
        [Parameter(Mandatory = $false)]
        [ValidateSet("Error", "Warn", "Info")]
        [string]$Level = "Info"
    )

    # format date for our log file
    $FormattedDate = Get-Date -Format "yyyy-MM-dd HH:mm:ss"

    [pscustomobject]@{
        Time     = $FormattedDate
        Severity = $Level
        Message  = $Message
    } |
    Export-Csv -Path "C:\Windows\Logs\Software\Install-HP7740Driver.log" -Append -NoTypeInformation
}

# vars
$driverName = "HP OfficeJet Pro 7740 series"

# add driver into driver store
Write-Log -Message 'Running: pnputil.exe /a .\Basic_Webpack_x64-40.16.1234-OJ7740_Basicx64_Webpack\hpygid20.inf /i'
try {
    Invoke-Expression "pnputil.exe /a .\Basic_Webpack_x64-40.16.1234-OJ7740_Basicx64_Webpack\hpygid20.inf /i"
    Write-Log "Success"
} catch {
    Write-Log -Message "There was an error running pnputil. The error was: $Error"
}

# install the driver
Write-Log -Message "Running: Add-PrinterDriver -Name $driverName"
try {
    Add-PrinterDriver -Name "$driverName"
    Write-Log "Success"
} catch {
    Write-Log -Message "There was an error running Add-PrinterDriver. The error was: $Error"
}
