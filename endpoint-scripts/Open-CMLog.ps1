function Open-CMLog {
    param (
        # ComputerName
        [Parameter()]
        [string]
        $ComputerName
    )

    # log file to open
    & "C:\Program Files\CMTrace\CMTrace.exe" "\\$ComputerName\c$\Windows\Logs\Software\Uninstall-AdobeApps.log"
}
