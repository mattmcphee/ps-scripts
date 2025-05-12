<#
.SYNOPSIS
Gets vulnerable versions of Illustrator and displays info about them.
.NOTES
Author:     Matt McPhee
Created:    09/05/2025
Updated:    09/05/2025
#>

function Get-InstalledApps {
    [CmdletBinding()]
    param(
        # ComputerName
        [Parameter(Mandatory=$false)]
        [string]
        $ComputerName
    )

    if (!$ComputerName) {
        Get-ItemProperty "HKLM:\SOFTWARE\Wow6432Node\Microsoft\Windows\CurrentVersion\Uninstall\*" # 32 Bit
        Get-ItemProperty "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall\*"             # 64 Bit
    } else {
        $apps = Invoke-Command -ComputerName $ComputerName -ScriptBlock {
            $remoteMachineApps = @()
            $remoteMachineApps += Get-ItemProperty "HKLM:\SOFTWARE\Wow6432Node\Microsoft\Windows\CurrentVersion\Uninstall\*" # 32 Bit
            $remoteMachineApps += Get-ItemProperty "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall\*"             # 64 Bit
            $remoteMachineApps
        }
        $apps
    }
}

$vulnIlluMachines = @(
    '5cg3246q5w',
    '5cd23678zz',
    '5cg1043bpd',
    'cnd1087hqy',
    'cnd1087hrt',
    '5cd4413p6f',
    '5cg21386mw',
    '5cd4467ts3',
    'cnd1087hvb'
)

foreach ($machine in $vulnIlluMachines) {
    $installedApps = Get-InstalledApps -ComputerName $machine

    Write-Host "==================================================================="
    Write-Host "Illustrator 2021"
    Write-Host "==================================================================="

    $installedApps | Where-Object {
        $_.DisplayName -like '*Illustrator 2021*' -and
        $_.DisplayVersion -le '25.4.7'
    } |
    Select-Object @{
        name='ComputerName'
        exp={$machine}
    },DisplayName,DisplayVersion,UninstallString,InstallLocation |
    Sort-Object DisplayName

    Write-Host "==================================================================="
    Write-Host "Illustrator 2022"
    Write-Host "==================================================================="
    $installedApps | Where-Object {
        $_.DisplayName -like '*Illustrator 2022*' -and
        $_.DisplayVersion -le '26.4'
    } |
    Select-Object @{
        name='ComputerName'
        exp={$machine}
    },DisplayName,DisplayVersion,UninstallString,InstallLocation |
    Sort-Object DisplayName

    Write-Host "==================================================================="
    Write-Host "Illustrator 2023"
    Write-Host "==================================================================="
    $installedApps | Where-Object {
        $_.DisplayName -like '*Illustrator 2023*' -and
        $_.DisplayVersion -le '27.9.5'
    } |
    Select-Object @{
        name='ComputerName'
        exp={$machine}
    },DisplayName,DisplayVersion,UninstallString,InstallLocation |
    Sort-Object DisplayName

    Write-Host "==================================================================="
    Write-Host "Illustrator 2024"
    Write-Host "==================================================================="
    $installedApps | Where-Object {
        $_.DisplayName -like '*Illustrator 2024*' -and
        $_.DisplayVersion -le '28.6'
    } |
    Select-Object @{
        name='ComputerName'
        exp={$machine}
    },DisplayName,DisplayVersion,UninstallString,InstallLocation |
    Sort-Object DisplayName
}
