#region Comments
<#
.SYNOPSIS
This function searches the 64bit and 32bit registry stores for installed
applications and displays info about them
.NOTES
Author:     Matt McPhee
Created:    2025-06-02
Changelog:  2025-11-05 - added test paths for office click to run and bmd reg keys
.PARAMETER ComputerName
The name of the computer on the network. If this is not supplied, it will use
the computer the script runs on.
.PARAMETER ApplicationName
The name of the application. You should use wildcards on either side. If this
is not supplied, it will return all apps found in the registry.
.EXAMPLE
Get-InstalledApps -ComputerName MMWIN11-05 -ApplicationName *note*
#>
function Get-InstalledApps {
    [CmdletBinding()]
    #region Params
    param(
        # ComputerName
        [Parameter(Mandatory = $true)]
        [string]
        $ComputerName,
        # ApplicationName
        [Parameter(Mandatory = $false)]
        [string]
        $ApplicationName,
        # PathHeadings
        [Parameter(Mandatory = $false)]
        [switch]
        $NoPathHeadings = $false
    )

    #region Write-DashLine
    function Write-DashLine {
        param(
            [string]$Text
        )

        $totalLength = 100
        $dashCount = $totalLength - $Text.Length
        $dashChar = "="
        $boundChar = "|"
        $boundStart = $boundChar + $dashChar * 3
        $boundEnd = $dashChar * 3 + $boundChar

        if ($dashCount -le 0) {
            $line = "$boundStart $Text $boundEnd"
        } else {
            $boundEndDynamic = $dashChar * ($dashCount) + $boundEnd
            $line = "$boundStart $Text $boundEndDynamic"
        }

        Write-Host $line -ForegroundColor Cyan
    }

    #region Variables
    $ErrorActionPreference = 'Stop'

    $regPaths = @(
        "SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall",
        "SOFTWARE\Wow6432Node\Microsoft\Windows\CurrentVersion\Uninstall",
        "SOFTWARE\Microsoft\Office\ClickToRun",
        "SOFTWARE\BMD"
    )

    $propsToCapture = @(
        'DisplayName',
        'DisplayVersion',
        'Version',
        'InstallLocation',
        'UninstallString',
        'QuietUninstallString',
        'InstallationPath',
        'ProductReleaseIds',
        'VersionToReport'
    )

    #region Main
    try {
        $baseKey = [Microsoft.Win32.RegistryKey]::OpenRemoteBaseKey(
            'LocalMachine',
            $ComputerName,
            [Microsoft.Win32.RegistryView]::Registry64
        )
    } catch {
        $baseKey.Close()
        throw "Could not find $ComputerName on the network."
    }

    foreach ($regPath in $regPaths) {
        $regKey = $baseKey.OpenSubKey($regPath)
        if (-not $regKey) {
            Write-Verbose "Could not find registry path: HKLM:\$regPath - skipping..."
            continue
        }

        $apps = @()

        $regKeySubKeyNames = $regKey.GetSubKeyNames()

        foreach ($appKeyName in $regKeySubKeyNames) {
            $appKey = $baseKey.OpenSubKey("$regPath\$appKeyName")

            if ($appKey.ValueCount -gt 0) {
                $displayName = $appKey.GetValue('DisplayName')
                if (
                    $ApplicationName -and `
                        $appKeyName -notlike $ApplicationName -and `
                        $displayName -notlike $ApplicationName -and `
                        $appKey.Name -notlike $ApplicationName
                ) {
                    continue
                }

                $appInfo = New-Object -TypeName PSCustomObject

                $appInfo | Add-Member -MemberType NoteProperty -Name 'RegistryPath' -Value $appKey.Name
                $appInfo | Add-Member -MemberType NoteProperty -Name 'KeyName' -Value $appKeyName
                
                $appKeyValueNames = $appKey.GetValueNames() | Sort-Object

                foreach ($appKeyValueName in $appKeyValueNames) {
                    if ($propsToCapture -contains $appKeyValueName) {
                        $propValue = $appKey.GetValue($appKeyValueName)
                        $appInfo | Add-Member -MemberType NoteProperty -Name $appKeyValueName -Value $propValue
                    }
                }

                $apps += $appInfo
            }

            $appkey.Close()
        }

        $regKey.Close()

        if ($apps.Count -gt 0) {
            if (-not $NoPathHeadings) {
                Write-DashLine -Text "HKLM:\$regPath"
            }
            $apps
        }
    }

    $baseKey.Close()
}
