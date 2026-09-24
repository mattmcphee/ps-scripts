$titlePattern = "*Intel*Extension*2.1.10103.24*"
$logPath = "C:\Windows\Logs\Unhide-IntelExtensibleFrameworkUpdate.log"

function Write-CMLog {
    [CmdletBinding()]
    param(
        # Message
        [Parameter(Mandatory = $true, ValueFromPipeline)]
        [AllowEmptyString()]
        [AllowNull()]
        [string[]]$Message,
        # Path
        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [string]$Path,
        # Level
        [Parameter(Mandatory = $false)]
        [ValidateSet("Error", "Warning", "Info")]
        [string]$Level = "Info",
        # Component
        [Parameter(Mandatory = $false)]
        [string]$Component = "PowerShellScript",
        # Context
        [Parameter(Mandatory = $false)]
        [string]$Context = "PowerShellScript",
        # Quiet - suppresses output
        [Parameter(Mandatory = $false)]
        [switch]$Quiet = $false
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
            "file=`"Hide-IntelExtensibleFrameworkUpdateRemediation.ps1`"" +
            ">"

            # append line to log file
            $logLine | Out-File -FilePath $Path -Append -Encoding utf8
        }
    }
}

try {
    $updateSession = New-Object -ComObject Microsoft.Update.Session
    $updateSearcher = $updateSession.CreateUpdateSearcher()
    $updates = @($updateSearcher.Search("IsHidden=1").Updates)
} catch {
    Write-CMLog -Message "Failed to query the Windows Update Agent: $($_.Exception.Message)" -Level 'Error' -Path $logPath -Quiet
    exit 1
}

$matched = @($updates | Where-Object { $_.Title -like $titlePattern })

if ($matched.Count -eq 0) {
    Write-CMLog -Message "No hidden update matching '$titlePattern'. Nothing to remediate." -Level 'Info' -Path $logPath -Quiet
    exit 0
}

$failures = [System.Collections.Generic.List[string]]::new()

foreach ($update in $matched) {
    try {
        $update.IsHidden = $false
    } catch {
        Write-CMLog -Message "Failed to unhide $($update.Title): $($_.Exception.Message)" -Level 'Error' -Path $logPath -Quiet
        $failures.Add($update.Title)
        continue
    }

    Start-Sleep -Seconds 60

    # re-read the property to confirm the change persisted to the WU datastore
    if (-not ($update.IsHidden)) {
        Write-CMLog -Message "Successfully unhideded $($update.Title)" -Level 'Info' -Path $logPath -Quiet
    } else {
        Write-CMLog -Message "Unhide operation reported no error but $($update.Title) is still hidden" -Level 'Error' -Path $logPath -Quiet
        $failures.Add($update.Title)
    }
}

if ($failures.Count -gt 0) {
    Write-CMLog "Failed to unhide $($failures.Count) update(s): $($failures -join ', ')" -Level 'Error' -Path $logPath -Quiet
    exit 1
}

exit 0
