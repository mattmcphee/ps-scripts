function Set-ArchiveAfter180 {
    [CmdletBinding()]
    param (
        # User list path to txt file containing users
        [Parameter(Mandatory=$true)]
        [string]
        $UserListPath
    )
    $users = Get-Content $UserListPath
    foreach ($user in $users) {
        $mailbox = Get-RemoteMailbox $user | Select-Object CustomAttribute14
        $ca14 = $mailbox.CustomAttribute14
        if ($ca14 -ne "") {
            $newCa14 = ($ca14 += ",ArchiveAfter180")
            Set-RemoteMailbox -Identity $user -CustomAttribute14 $newCa14
        } else {
            Set-RemoteMailbox -Identity $user -CustomAttribute14 "ArchiveAfter180"
        }
    }
}