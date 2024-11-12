$users = Get-Content "C:\sources\PowershellScripts\users.txt"

foreach ($user in $users) {
    $userSAM = Get-ADUser -SearchBase 'OU=Locations,DC=bmd,DC=com,DC=au' -Filter {employeeID -like $user} | select SamAccountName
    Add-ADGroupMember -Identity 'app_ax_emp_selfservice_usg' -Members $userSAM.SamAccountName
}

Get-ADUser -SearchBase 'OU=Locations,DC=bmd,DC=com,DC=au' -Filter {streetaddress -like '10 Harris*'} -properties displayname,streetaddress |
Set-ADUser -POBox $null -StreetAddress "Lot 2, 18 Railway Parade, Bayswater, WA" -City "Perth" -State "WA" -PostalCode "6053" -Country "AU"

foreach ($user in $users) {
    Get-ADUser -SearchBase 'OU=Locations,DC=bmd,DC=com,DC=au' -Filter {displayname -like $user} `
        -Properties displayname,streetaddress,company,city,state,postalcode | 
        Set-ADUser -StreetAddress '46 Price St, Nerang QLD' -Company 'BMD Urban Gold Coast' `
        -City 'Gold Coast' -State 'QLD' -PostalCode '4211' -Country 'AU' -Verbose
}

Get-ADUser -SearchBase 'OU=Locations,DC=bmd,DC=com,DC=au' -Filter {department -like '341-Q10'} -properties displayname,streetaddress |
Set-ADUser -POBox 'PO Box 197 Wynnum Qld 4178' -StreetAddress "Office 1A, 25 Cambridge Parade, Manly" -City "Manly" -State "QLD" -PostalCode "4179" -Country "AU"