function Get-LastLogonUser {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [string]
        $ComputerName
    )

    Get-CMDevice -Name $ComputerName |
    Select-Object @{n="ComputerName";e=$ComputerName},lastlogonuser
}
