function Get-TeamsVersion {
    [CmdletBinding()]
    param (
        # ComputerName
        [Parameter(Mandatory=$false)]
        [string]
        $ComputerName = $env:COMPUTERNAME
    )

    Invoke-Command -ComputerName $ComputerName -ScriptBlock {
        (Get-ChildItem "C:\Program Files\WindowsApps\MSTeams*").Name
    }
}
