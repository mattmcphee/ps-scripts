function Write-Log {
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
    [CmdletBinding()]
    param(
        # Message
        [Parameter(Mandatory=$true,ValueFromPipeline)]
        [AllowEmptyString()]
        [AllowNull()]
        [string[]]
        $Message,
        # Level
        [Parameter(Mandatory=$false)]
        [ValidateSet("Error", "Warning", "Info")]
        [string]
        $Level = "Info",
        # Path
        [Parameter(Mandatory=$true)]
        [ValidateNotNullOrEmpty()]
        [string]
        $Path
    )

    process {
        # convert level to type codes so cmtrace can read it
        switch ($Level) {
            "Info" { [int]$Type = 1 }
            "Warning" { [int]$Type = 2 }
            "Error" { [int]$Type = 3 }
        }

        # create log entry
        $logLine = "<![LOG[$Message]LOG]!>" +
        "<" +
        "time=`"$(Get-Date -Format "HH:mm:ss.ffffff")`" " +
        "date=`"$(Get-Date -Format "M-d-yyyy")`" " +
        "type=`"$Type`" " +
        ">"

        # append line to log file
        $logLine | Out-File -FilePath $Path -Append -Force -Encoding utf8
    }
}

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
