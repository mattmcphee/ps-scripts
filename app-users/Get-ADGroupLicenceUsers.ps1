function Get-ADGroupLicenceUsers {
    param(
        # ADGroup
        [Parameter(Mandatory)]
        [string]
        $ADGroup,
        # CsvPathNoExtension with no extension
        [Parameter(Mandatory)]
        [string]
        $CsvPathNoExtension
    )

    $csvPath = "$CsvPathNoExtension.csv"
    $excelPath = "$CsvPathNoExtension.xlsx"

    $users = Get-ADGroupMember $ADGroup |
    Get-ADUser -Properties givenName, surname, department, emailaddress |
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

    $users | Export-Csv -Path $csvPath -NoTypeInformation -Encoding 'utf8'
    $users | Export-Excel -Path $excelPath
}
