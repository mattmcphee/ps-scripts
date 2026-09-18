function Install-SCCMClient {
    [CmdletBinding()]
    param (
        # ComputerName
        [Parameter(Mandatory)]
        [string]
        $ComputerName
    )

    if (-not (Test-Connection $ComputerName -Quiet -Count 2)) {
        throw "Computer is not online or could not find $ComputerName."
    }

    do {
        Write-Host "This will remove the SCCM client from $ComputerName!" -ForegroundColor Red
        $userInput = Read-Host "Type 'y' and press Enter to continue, or 'n' to exit"
        $userInput = $userInput.Trim()

        if ($userInput -eq 'y') {
            # exit the loop and continue the script
            Write-Host "Proceeding..." -ForegroundColor Green
            break
        } elseif ($userInput -eq 'n') {
            # User chose to exit
            Write-Host "Script execution cancelled." -ForegroundColor Red
            return
        } else {
            # Invalid input
            Write-Host "Invalid input. Please type 'y' or 'n'." -ForegroundColor Red
        }
    } while ($true)

    # start
    Write-Log ""
    Write-Log "=============="
    Write-Log $ComputerName
    Write-Log "=============="

    # needs to be in C:\ provider for unc paths to work
    $startLoc = Get-Location
    Set-Location "C:\"

    $waitSecs = 5

    $uninstallCommand = "-s \\$ComputerName C:\windows\ccmsetup\ccmsetup.exe /uninstall"
    Write-Log "Running: psexec $uninstallCommand"
    Start-Process -FilePath "psexec" -ArgumentList $uninstallCommand -Wait
    Write-Log "SCCM client has been uninstalled!"
    Start-Sleep -Seconds $waitSecs

    Write-Log "Copying ccmsetup files to remote machine..."
    try {
        $ccmSetupHostPath = "C:\sources\staging\ccmsetup"
        $ccmSetupDestinationPath = "\\$ComputerName\c$\Windows"
        Copy-Item -Path $ccmSetupHostPath -Destination $ccmSetupDestinationPath -Recurse -Force -ErrorAction Stop
        Write-Log "ccmsetup files have been copied to C:\Windows\ccmsetup on remote machine!"
    } catch {
        throw $_
    }

    $installCommand = "-s \\$ComputerName C:\windows\ccmsetup\ccmsetup.exe /mp:BNESCCM01.BMD.COM.AU SMSSITECODE=A00 SMSMP=BNESCCM01.BMD.COM.AU FSP=BNESCCM01.BMD.COM.AU /MANAGEDINSTALLER"
    Write-Log "Starting SCCM client install..."
    Start-Process -FilePath "psexec" -ArgumentList $installCommand -Wait
    Write-Log "SCCM client install has been started! Inspect C:\Windows\ccmsetup\logs\ccmsetup.log"
    Start-Sleep -Seconds $waitSecs

    Set-Location $startLoc
}
