function Copy-BypassAppsToSource {
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

    $appList = @(
        'addinprocess.exe',
        'addinprocess32.exe',
        'addinutil.exe',
        'aspnet_compiler.exe',
        'bash.exe',
        'bginfo.exe',
        'cdb.exe',
        'cscript.exe',
        'csi.exe',
        'dbghost.exe',
        'dbgsvc.exe',
        'dbgsrv.exe',
        'dnx.exe',
        'dotnet.exe',
        'fsi.exe',
        'fsiAnyCpu.exe',
        'infdefaultinstall.exe',
        'kd.exe',
        'kill.exe',
        'lxssmanager.dll',
        'lxrun.exe',
        'Microsoft.Build.dll',
        'Microsoft.Workflow.Compiler.exe',
        'msbuild.exe',
        'msbuild.dll',
        'mshta.exe',
        'ntkd.exe',
        'ntsd.exe',
        'powershellcustomhost.exe',
        'rcsi.exe',
        'runscripthelper.exe',
        'texttransform.exe',
        'visualuiaverifynative.exe',
        'system.management.automation.dll',
        'webclnt.dll/davsvc.dll',
        'wfc.exe',
        'windbg.exe',
        'wmic.exe',
        'wscript.exe',
        'wsl.exe',
        'wslconfig.exe',
        'wslhost.exe'
    )

    foreach ($app in $appList) {
        $result = Get-ChildItem -Path 'C:\Windows' -Filter "*$app" -Recurse -Depth 2 -ErrorAction SilentlyContinue |
        Select-Object -First 1
        Write-Log -Message $result.FullName -Level Info -Path "C:\source\log\Copy-BypassAppsToSource.log"
        $result | Copy-Item -Destination "C:\source\bypassapps"
    }

    $apps = Get-ChildItem

    foreach ($app in $apps) {
        Start-Process $app.FullName
        Read-Host -Prompt "Enter to continue"
    }
}
