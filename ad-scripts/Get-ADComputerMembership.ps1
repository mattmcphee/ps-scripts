function Get-ADComputerMembership {
    [CmdletBinding()]
    param (
        # ComputerName
        [Parameter(Mandatory)]
        [string]
        $ComputerName
    )
    
    try {
        Get-ADComputer -Identity $ComputerName -Properties MemberOf | Select-Object -ExpandProperty MemberOf
    } catch {
        throw $_
    }
}
