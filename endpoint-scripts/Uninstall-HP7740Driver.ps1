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
    Export-Csv -Path "C:\Windows\Logs\Software\Uninstall-HP7740Driver.log" -Append -NoTypeInformation
}

# vars
$driverName = "HP OfficeJet Pro 7740 series"

# remove driver from driver store
Write-Log -Message "Running: pnputil.exe /d .\Basic_Webpack_x64-40.16.1234-OJ7740_Basicx64_Webpack\hpygid20.inf /f"
try {
    Invoke-Expression "pnputil.exe /d .\Basic_Webpack_x64-40.16.1234-OJ7740_Basicx64_Webpack\hpygid20.inf /f"
    Write-Log "Success"
} catch {
    Write-Log -Message "There was an error running pnputil. The error was: $Error"
}

# uninstall the driver
Write-Log -Message "Running: Remove-PrinterDriver -Name $driverName"
try {
    Remove-PrinterDriver -Name "$driverName"
    Write-Log "Success"
} catch {
    Write-Log -Message "There was an error running Remove-PrinterDriver. The error was: $Error"
}
