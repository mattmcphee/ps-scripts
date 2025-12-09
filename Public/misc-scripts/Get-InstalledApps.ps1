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
    param(
        # ComputerName
        [Parameter(Mandatory=$false)]
        [string]
        $ComputerName,
        # ApplicationName
        [Parameter(Mandatory=$false)]
        [string]
        $ApplicationName
    )

    $getAppsScriptBlock = {
        $apps = @()

        $x64Apps = Get-ItemProperty "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall\*" |
            Select-Object *,@{ n="RegistryKey"; e={$_.PSPath.Substring(36)} }
        $apps += $x64Apps

        $x86Apps = Get-ItemProperty "HKLM:\SOFTWARE\Wow6432Node\Microsoft\Windows\CurrentVersion\Uninstall\*" |
            Select-Object *,@{ n="RegistryKey"; e={$_.PSPath.Substring(36)} }
        $apps += $x86Apps

        $selectProperties = @(
            'DisplayName',
            'DisplayVersion',
            'InstallLocation',
            'UninstallString',
            'QuietUninstallString',
            'RegistryKey'
        )

        return $apps | Select-Object $selectProperties
    }

    if ($ComputerName) {
        $apps = Invoke-Command -ComputerName $ComputerName -ScriptBlock $getAppsScriptBlock
    } else {
        $apps = & $getAppsScriptBlock
    }

    if ($ApplicationName) {
        return $apps | Where-Object { $_.DisplayName -like $ApplicationName } | Sort-Object DisplayName
    } else {
        return $apps | Sort-Object DisplayName
    }
}
