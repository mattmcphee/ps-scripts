function Remove-AutoCADRegKeys {
    [CmdletBinding(SupportsShouldProcess)]
    param (
        # ComputerName
        [Parameter(Mandatory)]
        [string]
        $ComputerName,
        # UserUPN
        [Parameter(Mandatory)]
        [string]
        $UserUPN,
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

    # confirm user is logged in
    try {
        $explorerProcesses = Get-CimInstance -ClassName Win32_Process -ComputerName $ComputerName -Filter "Name = 'explorer.exe'"

        $loggedOnUsers = foreach ($proc in $explorerProcesses) {
            (Invoke-CimMethod -InputObject $proc -MethodName GetOwner).User
        }

        if ($loggedOnUsers -contains $UserUPN) {
            Write-CMLog "$UserUPN is currently logged into $ComputerName"
        } else {
            throw "ERROR: $UserUPN is not currently logged into $ComputerName. $UserUPN must be logged in. $_"
        }
    } catch {
        throw "ERROR: $_"
    }

    try {
        Write-CMLog -Message "Attempting to remove reg keys for '$ApplicationName'"
        $sid = (Get-ADUser -Identity $UserUPN).SID
        Write-CMLog -Message "$UserUPN SID is '$sid'"

        if ($ApplicationName -eq "AutoCAD 2024") {
            $appRegPath = "R24.3\ACAD-7101:409"
        } elseif ($ApplicationName -eq "AutoCAD Civil 3D 2025") {
            $appRegPath = "R25.0\ACAD-8100:409"
        }

        $keyPath = "$sid\Software\Autodesk\AutoCAD\$appRegPath"
        Write-CMLog -Message "Registry path to recursively delete will be: 'HKEY_USERS\$keyPath'"

        try {
            Invoke-Command -ComputerName $ComputerName -ScriptBlock {
                try {
                    [Microsoft.Win32.Registry]::Users.DeleteSubKeyTree($using:keyPath, $false)
                } catch {
                    throw "ERROR: $_"
                }
            }
        } catch {
            throw "ERROR: $_"
        }

        Write-CMLog -Message "Successfully deleted 'HKEY_USERS\$keyPath' (or it did not exist)."
    } catch {
        throw "ERROR: $_"
    }
}
