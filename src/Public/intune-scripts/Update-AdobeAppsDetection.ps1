<#
.SYNOPSIS
Detects if the Adobe RemoteUpdateManager.exe exists on the machine.
.NOTES
Author:     Matt McPhee
Created:    06/05/2025
Updated:    06/05/2025
#>
function Update-AdobeAppsDetection {
    $rumPath = "C:\Program Files (x86)\Common Files\Adobe\OOBE_Enterprise\RemoteUpdateManager\RemoteUpdateManager.exe"
    $logPath = "C:\Windows\Logs\Software\Update-AdobeApps.log"

    if (Test-Path $rumPath) {
        # issue detected
        Write-Log -Message "RemoteUpdateManager.exe detected. Proceeding to launch it." -Level Info -Path $logPath
        exit 1
    } else {
        Write-Log -Message "RemoteUpdateManager.exe not detected. Taking no action." -Level Info -Path $logPath
        exit 0
    }
}
