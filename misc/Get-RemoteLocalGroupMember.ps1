function Get-RemoteLocalGroupMember {
    [CmdletBinding()]
    param (
        # ComputerName
        [Parameter(Mandatory)]
        [string]
        $ComputerName,
        # Group
        [Parameter(Mandatory)]
        [string]
        $Group
    )
    
    Invoke-Command -ComputerName $ComputerName -ScriptBlock {
        try {
            Get-LocalGroupMember -Group $using:Group
        } catch {
            $_
        }
    }
}
