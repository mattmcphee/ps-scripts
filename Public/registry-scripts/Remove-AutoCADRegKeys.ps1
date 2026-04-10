function Remove-AutoCADRegKeys {
    [CmdletBinding()]
    param (
        # ComputerName
        [Parameter(Mandatory)]
        [string]
        $ComputerName,
        # User
        [Parameter(Mandatory)]
        [string]
        $User,
        # ApplicationName
        [Parameter(Mandatory)]
        [ValidateSet("AutoCAD 2024", "AutoCAD Civil 3D 2025")]
        [string]
        $ApplicationName
    )

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
            [Parameter(Mandatory = $false)]
            [ValidateNotNullOrEmpty()]
            [string]
            $Path = "C:\Windows\Logs\Software\Remove-AutoCADRegKeys.log",
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
            foreach ($line in $Message) {
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
    }

    try {
        Write-CMLog -Message "Attempting to remove reg keys for '$ApplicationName'"
        $sid = (Get-ADUser -Identity $User).SID
        Write-CMLog -Message "$User SID is '$sid'"

        if ($ApplicationName -eq "AutoCAD 2024") {
            $appRegPath = "R24.3\ACAD-7101:409"
        } elseif ($ApplicationName -eq "AutoCAD Civil 3D 2025") {
            $appRegPath = "R25.0\ACAD-8100:409"
        }

        Write-CMLog -Message "Registry path to recursively delete will be: 'HKEY_USERS\$sid\Software\Autodesk\AutoCAD\$appRegPath'"


    } catch {
        throw $_
    }
}
