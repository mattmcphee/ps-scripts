function Install-LatestVSTOR2010 {
    function Write-Log {
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
            $Path = "C:\Windows\Logs\Software\Install-LatestVSTOR2010.log",
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

    $url = "https://go.microsoft.com/fwlink/?linkid=140384"
    $destination = "C:\windows\ccmcache\vstor2010\vstor_redist.exe"

    try {
        Write-Log "Beginning download of VSTOR 2010." -Quiet
        Write-Log "Landing page URL is $url" -Quiet

        $pattern = 'https://download\.microsoft\.com/[\w\-/]+vstor_redist\.exe'
        $res = Invoke-WebRequest -Uri $url -UseBasicParsing
        $latestUrl = [regex]::match($res.Content, $pattern).Value

        Write-Log "Download URL from landing page is $latestURL" -Quiet
        Write-Log "Downloading to $destination" -Quiet
        Invoke-WebRequest -Uri $latestUrl -OutFile $destination
        Write-Log "Executing '$destination /q /norestart'" -Quiet

        Start-Process -FilePath $destination -ArgumentList "/q /norestart" -Wait

        Write-Log "Completed installation of VSTOR 2010." -Quiet
    } catch {
        Write-Error "Failed to download the latest VSTO runtime: $_"
        return 1
    }
}
