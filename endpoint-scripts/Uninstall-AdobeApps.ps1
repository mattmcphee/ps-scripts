#region Functions
<#
.SYNOPSIS
This script will search the registry for vulnerable Adobe suite uninstallation
keys. It will then execute the registry key's UninstallString.
#>

function Get-InstalledApps {
    $apps = @()
    $apps += Get-ItemProperty "HKLM:\SOFTWARE\Wow6432Node\Microsoft\Windows\CurrentVersion\Uninstall\*"
    $apps += Get-ItemProperty "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall\*"

    return $apps
}

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

#region vars
$logPath = 'C:\Windows\Logs\Software\Uninstall-AdobeApps.log'
# the below registry keys were retrieved from the security portal
# spreadsheet located in Teams -> Endpoint -> Vulnerabilities
$regPaths = @(
    'HKEY_LOCAL_MACHINE\SOFTWARE\WOW6432Node\Microsoft\Windows\CurrentVersion\Uninstall\AME_24_6_1',
    'HKEY_LOCAL_MACHINE\SOFTWARE\WOW6432Node\Microsoft\Windows\CurrentVersion\Uninstall\IDSN_17_4_2',
    'HKEY_LOCAL_MACHINE\SOFTWARE\WOW6432Node\Microsoft\Windows\CurrentVersion\Uninstall\IDSN_18_5_4',
    'HKEY_LOCAL_MACHINE\SOFTWARE\WOW6432Node\Microsoft\Windows\CurrentVersion\Uninstall\ILST_25_0_1',
    'HKEY_LOCAL_MACHINE\SOFTWARE\WOW6432Node\Microsoft\Windows\CurrentVersion\Uninstall\ILST_27_7',
    'HKEY_LOCAL_MACHINE\SOFTWARE\WOW6432Node\Microsoft\Windows\CurrentVersion\Uninstall\ILST_27_8',
    'HKEY_LOCAL_MACHINE\SOFTWARE\WOW6432Node\Microsoft\Windows\CurrentVersion\Uninstall\KBRG_13_0_9',
    'HKEY_LOCAL_MACHINE\SOFTWARE\WOW6432Node\Microsoft\Windows\CurrentVersion\Uninstall\PHSP_22_2',
    'HKEY_LOCAL_MACHINE\SOFTWARE\WOW6432Node\Microsoft\Windows\CurrentVersion\Uninstall\PHSP_26_4',
    'HKEY_LOCAL_MACHINE\SOFTWARE\WOW6432Node\Microsoft\Windows\CurrentVersion\Uninstall\DRWV_21_4'
)

Write-Log -Message "***********************************************************" -Level Info -Path $logPath
Write-Log -Message "******************** SCRIPT START ***********************" -Level Info -Path $logPath
Write-Log -Message "***********************************************************" -Level Info -Path $logPath

$apps = Get-InstalledApps | Where-Object { $_.DisplayName -like "*adobe*" }

Write-Log -Message "Searching for installation of vulnerable Adobe apps..." -Level Info -Path $logPath

$processString = "C:\Program Files (x86)\Common Files\Adobe\Adobe Desktop Common\HDBox\Setup.exe"
if (Test-Path -Path $processString) {
    Write-Log -Message "Found uninstaller process: $processString" -Level Info -Path $logPath
} else {
    Write-Log -Message "Uninstaller not found! Exiting script..." -Level Error -Path $logPath
    return
}

foreach ($app in $apps) {
    Write-Log -Message "Current app: $($app.DisplayName)" -Level Info -Path $logPath

    foreach ($regPath in $regPaths) {
        if ($app.PsPath -like "*$regPath") {
            Write-Log -Message "Found $($app.DisplayName) with reg key $regPath that matches:" -Level Info -Path $logPath
            Write-Log -Message $app.PsPath -Level Info -Path $logPath
            # build our own uninstall parameters
            $sapCodeIndex = $app.UninstallString.IndexOf('sapCode=')
            $sapCode = $app.UninstallString.substring(($sapCodeIndex + 'sapCode='.Length), 4)
            Write-Log -Message "sapCode: $sapCode" -Level Info -Path $logPath

            $baseVersionIndex = $app.UninstallString.IndexOf('productVersion=')
            $baseVersion = $app.UninstallString.substring(($baseVersionIndex + 'productVersion='.Length), 2)
            $baseVersion = "$baseVersion.0"
            Write-Log -Message "baseVersion: $baseVersion" -Level Info -Path $logPath

            $paramString = "--uninstall=1 --sapCode=$sapCode --baseVersion=$baseVersion --platform=win64 --deleteUserPreferences=false"

            $uninstallString = "$processString $paramString"

            Write-Log -Message "The process string is: $processString" -Level Info -Path $logPath
            Write-Log -Message "The param string is: $paramString" -Level Info -Path $logPath

            Write-Log -Message "Proceeding to uninstall using uninstall string:" -Level Info -Path $logPath
            Write-Log -Message $uninstallString -Level Info -Path $logPath

            Start-Process -FilePath $processString -ArgumentList $paramString -WindowStyle Hidden

            if (Test-Path -Path "Registry::$regPath") {
                Write-Log -Message "Something went wrong! $($app.DisplayName) not uninstalled!" -Level Error -Path $logPath
            } else {
                Write-Log -Message "Successfully uninstalled $($app.DisplayName)" -Level Info -Path $logPath
            }
        }
    }
}

Write-Log -Message "***********************************************************" -Level Info -Path $logPath
Write-Log -Message "********************* SCRIPT END ************************" -Level Info -Path $logPath
Write-Log -Message "***********************************************************" -Level Info -Path $logPath
Write-Log -Message "" -Level Info -Path $logPath
