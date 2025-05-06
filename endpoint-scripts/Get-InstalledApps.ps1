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
