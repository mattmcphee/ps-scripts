function Get-12DLicenceUsers {
    param(
        # TxtPath
        [Parameter(Mandatory)]
        [string]
        $TxtPath,
        # CsvPathNoExtension
        [Parameter(Mandatory)]
        [string]
        $CsvPathNoExtension
    )

    $csvPath = "$CsvPathNoExtension.csv"
    $excelPath = "$CsvPathNoExtension.xlsx"

    $users = Get-Content -Path $TxtPath | ForEach-Object {
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
                    '999' { 'BMD Contractor' }
                    default { 'BMD Corporate' }
                }
            }
        }
    }

    $users | Export-Csv -Path $csvPath -NoTypeInformation -Encoding 'utf8' -Force
    $users | Export-Excel -Path $excelPath
}
