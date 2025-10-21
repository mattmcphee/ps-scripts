function Reinstall-SCCMClient {
    [CmdletBinding()]
    param (
        # ComputerName
        [Parameter(Mandatory)]
        [string]
        $ComputerName
    )

    function Write-Log {
        [CmdletBinding()]
        param(
            # Message
            [Parameter(Mandatory = $true, ValueFromPipeline)]
            [AllowEmptyString()]
            [AllowNull()]
            [string[]]
            $Message,
            # Level
            [Parameter(Mandatory = $false)]
            [ValidateSet("Error", "Warning", "Info")]
            [string]
            $Level = "Info",
            # Path
            [Parameter(Mandatory = $false)]
            [ValidateNotNullOrEmpty()]
            [ValidateScript({
                    $dir = Split-Path $_ -Parent
                    if (Test-Path $dir) {
                        return $true
                    } else {
                        throw "LogPath: The folder path '$dir' does not exist."
                    }
                })]
            [string]
            $Path = "C:\sources\logs\Reinstall-SCCMClient.log",
            # Component
            [Parameter(Mandatory = $false)]
            [string]
            $Component = "PowerShellScript",
            # Context
            [Parameter(Mandatory = $false)]
            [string]
            $Context = "PowerShellScript",
            # Quiet - suppresses output
            [Parameter(Mandatory = $false)]
            [switch]
            $Quiet = $false
        )

        process {
            if (-not $Quiet) {
                # output the message
                Write-Host $Message
            }

            # convert level to type codes so cmtrace can read it
            switch ($Level) {
                "Info" { [int]$type = 1 }
                "Warning" { [int]$type = 2 }
                "Error" { [int]$type = 3 }
            }

            $threadId = [System.Threading.Thread]::CurrentThread.ManagedThreadId
            $scriptName = $MyInvocation.MyCommand.Name

            # create log entry
            $logLine = "<![LOG[$Message]LOG]!>" +
            "<" +
            "time=`"$(Get-Date -Format "HH:mm:ss.ffffff")`" " +
            "date=`"$(Get-Date -Format "d-M-yyyy")`" " +
            "component=`"$Component`" " +
            "context=`"$Context`" " +
            "type=`"$type`" " +
            "thread=`"$threadId`" " +
            "file=`"$scriptName`"" +
            ">"

            # append line to log file
            $logLine | Out-File -FilePath $Path -Append -Encoding utf8
        }
    }

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

    # $stopWinMgmtCommand = "-s \\$ComputerName net stop winmgmt /y"
    # Write-Log "Running: psexec $stopWinMgmtCommand"
    # Start-Process -FilePath "psexec" -ArgumentList $stopWinMgmtCommand -Wait
    # Write-Log "winmgmt has been stopped!"
    # Start-Sleep -Seconds $waitSecs

    # $resetWmiRepoCommand = "-s \\$ComputerName winmgmt /resetrepository"
    # Write-Log "Running: psexec $resetWmiRepoCommand"
    # Start-Process -FilePath "psexec" -ArgumentList $resetWmiRepoCommand -Wait
    # Write-Log "WMI repository has been reset!"
    # Start-Sleep -Seconds $waitSecs

    # $mofcompCommand = "-s \\$ComputerName mofcomp `"C:\Program Files\Microsoft Policy Platform\ExtendedStatus.mof`""
    # Write-Log "Running: psexec $mofcompCommand"
    # Start-Process -FilePath "psexec" -ArgumentList $mofcompCommand -Wait
    # Write-Log "Successfully compiled ExtendedStatus.mof!"
    # Start-Sleep -Seconds $waitSecs

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
