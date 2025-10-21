function Get-ADGroupMemberInfo {
    param (
        # GroupName
        [Parameter(Mandatory = $true)]
        [string]
        $GroupName
    )

    $memberList = @()

    $members = Get-ADGroupMember -Identity $GroupName

    foreach ($member in $members) {
        $memberInfo = [PSCustomObject]@{
            Name           = $member.Name
            ObjectClass    = $member.ObjectClass
            SamAccountName = $member.SamAccountName
            ParentGroup    = $GroupName
        }

        $memberList += $memberInfo

        if ($member.ObjectClass -eq 'group') {
            Get-ADGroupMemberInfo -GroupName $member.Name
        }
    }

    $memberList | Select-Object ObjectClass, Name, SamAccountName, ParentGroup
}
