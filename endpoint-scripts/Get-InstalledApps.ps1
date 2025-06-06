<#
.SYNOPSIS
This function searches the 64bit and 32bit registry stores for installed
applications and displays info about them
.NOTES
Author:     Matt McPhee
Created:    2025-06-02
Updated:    2025-06-02
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

    $apps = @()

    if (!$ComputerName) {
        $apps += Get-ItemProperty "HKLM:\SOFTWARE\Wow6432Node\Microsoft\Windows\CurrentVersion\Uninstall\*"
        $apps += Get-ItemProperty "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall\*"
    } else {
        $apps = Invoke-Command -ComputerName $ComputerName -ScriptBlock {
            $remoteApps = @()
            $remoteApps += Get-ItemProperty "HKLM:\SOFTWARE\Wow6432Node\Microsoft\Windows\CurrentVersion\Uninstall\*"
            $remoteApps += Get-ItemProperty "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall\*"
            return $remoteApps
        }
    }

    if ($ApplicationName) {
        $apps = $apps | Where-Object { $_.DisplayName -like "$ApplicationName" } |
        Select-Object Displayname,DisplayVersion,InstallLocation,UninstallString,QuietUninstallString,@{
            n='RegistryKey'
            e={ $_.PsPath.substring(36) }
        } | Sort-Object DisplayName
    } else {
        $apps = $apps | Select-Object DisplayName,DisplayVersion,InstallLocation,UninstallString,QuietUninstallString,@{
            n='RegistryKey'
            e={ $_.PsPath.substring(36) }
        } | Sort-Object DisplayName
    }

    $apps
}
