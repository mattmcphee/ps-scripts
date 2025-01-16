function Get-TeamsVersion {
    [CmdletBinding()]
    param (
        # ComputerName
        [Parameter(Mandatory=$false)]
        [string]
        $ComputerName = $env:COMPUTERNAME
    )
    $output = Invoke-Command -ComputerName $ComputerName -ScriptBlock {
        $output = (Get-ChildItem "C:\Program Files\WindowsApps\MSTeams*").Name
        $output
    }
    $output
}