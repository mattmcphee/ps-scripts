function Get-ComputerUptime {
    param (
        # ComputerName
        [Parameter(Mandatory=$false)]
        [string]$ComputerName
    )

    if ($PSBoundParameters["ComputerName"]) {
        try {
            $uptime = Invoke-Command -ComputerName $ComputerName -ScriptBlock {
                (Get-Date) - (Get-CimInstance Win32_OperatingSystem -ComputerName $using:ComputerName).LastBootupTime
            }
        } catch {
            throw $_
        }
    } else {
        $uptime = (Get-Date) - (Get-CimInstance Win32_OperatingSystem -ComputerName $ComputerName).LastBootupTime
    }

    "$($uptime.Days) days, $($uptime.Hours) hours, $($uptime.Minutes) minutes, $($uptime.Seconds) seconds."
}
