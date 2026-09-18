<#
.SYNOPSIS
    This function will write a message to a file for logging purposes.
.PARAMETER Message
    A message to be logged. Can accept an array of messages (each message will be logged on a separate line).
.PARAMETER Level
    The severity level of the log line. Can be Info (default), Warn or Error.
.PARAMETER Path
    The desired path the log will be written to. Must include filename and file extension.
.OUTPUTS
    Appends a line to a log file.
#>
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
                New-Item -ItemType Directory -Path $logDir -ErrorAction Stop -Force
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
            $scriptName = $MyInvocation.MyCommand.Name

            # create log entry
            $logLine = "<![LOG[$line]LOG]!>" +
            "<" +
            "time=`"$timeStr`" " +
            "date=`"$dateStr`" " +
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
}
