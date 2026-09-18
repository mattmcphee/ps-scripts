function Add-RemoteLocalGroupMember {
    [CmdletBinding()]
    param (
        # ComputerName
        [Parameter(Mandatory)]
        [string]
        $ComputerName,
        # Group
        [Parameter(Mandatory)]
        [string]
        $Group,
        # Member
        [Parameter(Mandatory)]
        [string]
        $Member
    )
    
    Invoke-Command -ComputerName $ComputerName -ScriptBlock {
        try {
            Add-LocalGroupMember -Group $using:Group -Member $using:Member
        } catch {
            $_
        }
    }
}
