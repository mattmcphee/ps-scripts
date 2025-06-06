<#
.NOTES
THIS IS BROKEN!
#>
function Get-AECCollectionUsers {
    $users = Get-Content -Path "C:\sources\txt\aec-users.txt" |
    ForEach-Object {
        $identity = $_.replace('@bmd.com.au','')
        Get-ADUser -Identity $identity -Properties GivenName, Surname, EmailAddress, Department |
        Select-Object givenName, surname, emailaddress, department, @{
            n="BusinessUnit"
            e={
                switch ($_.department.substring(0,3)) {
                    { '121', '131', '141', '148' -eq $_ } { 'BMD Constructions' }
                    '008' { 'BMD Urban' }
                    '042' { 'BMD UK' }
                    '241' { 'JMAC' }
                    '341' { 'Empower' }
                    default { 'BMD Corporate' }
                }
            }
        }
    }

    $users | Export-Csv -Path 'C:\sources\csv\aec-collection-users-26052025.csv' -NoTypeInformation -Encoding 'utf8' -Force
    $users | Export-Excel -Path 'C:\sources\csv\aec-collection-users-26052025.xlsx'
}
