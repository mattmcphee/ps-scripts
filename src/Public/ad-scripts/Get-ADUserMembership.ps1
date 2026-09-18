function Get-ADUserMembership {
    [CmdletBinding()]
    param (
        # Username
        [Parameter(Mandatory)]
        [string]
        $Username
    )
    
    try {
        Get-ADUser -Identity $Username -Properties MemberOf | Select-Object -ExpandProperty MemberOf
    } catch {
        throw $_
    }
}
