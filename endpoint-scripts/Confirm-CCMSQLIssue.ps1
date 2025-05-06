function Confirm-CCMSQLIssue {
    param(
        # ComputerName
        [Parameter(Mandatory=$true)]
        [string]
        $ComputerName
    )

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

    # logpath
    $logPath = "C:\sources\logs\Confirm-CCMSQLIssue.log"

    # test if machine is online and psremoting is working by testing invoke-command
    Invoke-Command -ComputerName $ComputerName -ScriptBlock {} -ErrorAction Ignore
    $machineOnlineTestFailed = (-not $?)
    if ($machineOnlineTestFailed) {
        $errorMsg = "$ComputerName is offline or psremoting/winrm is cooked."
        Write-Log -Message $errorMsg -Level Error -Path $logPath
    }
    $sql = Invoke-Command -ComputerName $ComputerName -ScriptBlock {
        Get-Content 'C:\Windows\CCM\Logs\CCMSQLCE.log'
    }
    $count = ([regex]::matches($sql,"active concurrent sessions")).count
    $outputMsg = "There were $count instances of the phrase " + `
        "'active concurrent sessions' found in CCMSQLCE.log on $ComputerName"
    Write-Log -Message $outputMsg -Level Warning -Path $logPath
    Write-Output $outputMsg
}
