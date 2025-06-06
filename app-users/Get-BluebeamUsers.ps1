<#
.NOTES
THIS IS BROKEN!
#>
function Get-BluebeamUsers {
$bluebeamUsers = Get-ADGroupMember app_bluebeam_revu_usg |
Get-ADUser -Properties givenName, surname, department, emailaddress

$bluebeamBusinessUnits = $bluebeamUsers | Select-Object givenName, surname, emailaddress, department, @{
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

$sortedBluebeamUsers = $bluebeamBusinessUnits | Sort-Object department, surname

$sortedBluebeamUsers | Export-Csv -Path 'C:\sources\csv\bluebeam-users-23052025.csv' -NoTypeInformation -Encoding 'utf8'
$sortedBluebeamUsers | Export-Excel -Path 'C:\sources\csv\bluebeam-users-23052025.xlsx'
}
