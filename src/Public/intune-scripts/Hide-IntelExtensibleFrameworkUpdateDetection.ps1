<#
.SYNOPSIS
Detects whether the 'Intel - Extension - 2.1.10103.24' Windows Update is being
offered to the machine and has not yet been hidden. This update comes through the
local WU scan and not the drivers deployed through Intune.
.NOTES
Author:     Matt McPhee
Created:    15/09/2026
Updated:    15/09/2026
Exit 1 = update is visible and needs hiding, Exit 0 = no action required.
#>
function Hide-IntelExtensibleFrameworkUpdateDetection {
    $titlePattern = "*Intel*Extension*2.1.10103.24*"
    $logPath = "C:\Windows\Logs\Hide-IntelExtensibleFrameworkUpdate.log"

    function Write-CMLog {
        [CmdletBinding()]
        param(
            # Message
            [Parameter(Mandatory = $true, ValueFromPipeline)]
            [AllowEmptyString()]
            [AllowNull()]
            [string[]]
            $Message,
            # Path
            [Parameter(Mandatory = $true)]
            [ValidateNotNullOrEmpty()]
            [string]
            $Path,
            # Level
            [Parameter(Mandatory = $false)]
            [ValidateSet("Error", "Warning", "Info")]
            [string]
            $Level = "Info",
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
            $logDir = Split-Path $Path -Parent

            if (-not (Test-Path -Path $logDir -PathType Container)) {
                try {
                    New-Item -ItemType Directory -Path $logDir -ErrorAction Stop -Force | Out-Null
                } catch {
                    throw "Could not create log directory: $logDir $_"
                }
            }

            $now = Get-Date
            $tzOffset = [TimeZoneInfo]::Local.GetUtcOffset($now).TotalMinutes
            $timeStr = $now.ToString("HH:mm:ss.fff") + ("{0:+000;-000;+000}" -f $tzOffset)
            $dateStr = $now.ToString("MM-dd-yyyy")

            foreach ($line in $Message) {
                if (-not $Quiet) {
                    # output the message
                    Write-Output $line
                }

                # convert level to type codes so cmtrace can read it
                switch ($Level) {
                    "Info" { [int]$type = 1 }
                    "Warning" { [int]$type = 2 }
                    "Error" { [int]$type = 3 }
                }

                $threadId = [System.Threading.Thread]::CurrentThread.ManagedThreadId

                # create log entry
                $logLine = "<![LOG[$line]LOG]!>" +
                "<" +
                "time=`"$timeStr`" " +
                "date=`"$dateStr`" " +
                "component=`"$Component`" " +
                "context=`"$Context`" " +
                "type=`"$type`" " +
                "thread=`"$threadId`" " +
                "file=`"Hide-IntelExtensibleFrameworkUpdateDetection.ps1`"" +
                ">"

                # append line to log file
                $logLine | Out-File -FilePath $Path -Append -Encoding utf8
            }
        }
    }

    try {
        $updateSession = New-Object -ComObject Microsoft.Update.Session
        $updateSearcher = $updateSession.CreateUpdateSearcher()

        # only non-hidden updates are candidates for remediation
        $updates = @($updateSearcher.Search("IsHidden=0").Updates)
    } catch {
        Write-CMLog -Message "Failed to query the Windows Update Agent: $($_.Exception.Message)" -Level 'Error' -Path $logPath -Quiet
        Write-Output "Windows Update Agent query failed"
        exit 0
    }

    $matched = @($updates | Where-Object { $_.Title -like $titlePattern })

    if ($matched.Count -gt 0) {
        # issue detected
        foreach ($update in $matched) {
            Write-CMLog -Message "Detected visible update: $($update.Title)" -Level 'Warning' -Path $logPath -Quiet
        }
        Write-Output "Intel Extensible Framework update 2.1.10103.24 is visible and requires hiding"
        exit 1
    } else {
        Write-CMLog -Message "No visible update matching '$titlePattern'. Taking no action." -Level 'Info' -Path $logPath -Quiet
        Write-Output "Intel Extensible Framework update 2.1.10103.24 not offered or already hidden"
        exit 0
    }
}
