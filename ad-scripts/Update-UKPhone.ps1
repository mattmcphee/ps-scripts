$csv = Import-Csv -Path "C:\Users\mm.su\BMDIS phone numbers.csv"

foreach ($record in $csv) {
    $name = $record.Name
    $phone = $record.Phone
    Get-ADUser -SearchBase 'OU=Locations,DC=bmd,DC=com,DC=au' -Filter {displayname -like $name} | Set-ADUser -MobilePhone $phone
}