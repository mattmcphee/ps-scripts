<#
.SYNOPSIS
Executes Adobe's RemoteUpdateManager.exe which will update creative cloud
applications on the machine.
.NOTES
Author:     Matt McPhee
Created:    06/05/2025
Updated:    06/05/2025
#>
function Update-AdobeAppsRemediation {
    $rumPath = "C:\Program Files (x86)\Common Files\Adobe\OOBE_Enterprise\RemoteUpdateManager\RemoteUpdateManager.exe"
    $logPath = "C:\Windows\Logs\Software\Update-AdobeApps.log"

    try {
        # attempt to run RemoteUpdateManager.exe
        Start-Process -FilePath $rumPath -WindowStyle 'Hidden' -ErrorAction 'Stop'
        Write-Log -Message "RemoteUpdateManager.exe launched." -Level 'Info' -Path $logPath
    } catch {
        Write-Log -Message "Encountered this error when attempting to launch RemoteUpdateManager.exe:" -Level 'Error' -Path $logPath
        Write-Log -Message "$_" -Level 'Error' -Path $logPath
    }
}