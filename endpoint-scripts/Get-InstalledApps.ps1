function Get-InstalledApps {
    [CmdletBinding()]
    param (
        # ComputerName
        [Parameter(Mandatory)]
        [string]
        $ComputerName
    )

    $apps = Invoke-Command -ComputerName $ComputerName -ScriptBlock {
        $Apps = @()
        $Apps += Get-ItemProperty "HKLM:\SOFTWARE\Wow6432Node\Microsoft\Windows\CurrentVersion\Uninstall\*" # 32 Bit
        $Apps += Get-ItemProperty "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall\*"             # 64 Bit
        return $Apps
    }

    $apps
}
