function Compare-ComputersADGroups {
    [CmdletBinding()]
    param (
        # First object to compare
        [Parameter(Mandatory)]
        [string]
        $ADComputer1,
        # Second object to compare
        [Parameter(Mandatory)]
        [string]
        $ADComputer2
    )

    # CN=bne_it_gs,OU=Level 2 - Access - General,OU=au_groups,OU=Locations,DC=bmd,DC=com,DC=au

    $ADGroups1 = (Get-ADComputer $ADComputer1 -Properties MemberOf).MemberOf
    $formattedList1 = [System.Collections.ArrayList]::new()
    $ADGroups1 | ForEach-Object {
        $splitString = $_.split(",")
        $CNItem = $splitString[0]
        $groupName = $CNItem.SubString(3)
        $formattedList1.add($groupName) | Out-Null
    }

    $ADGroups2 = (Get-ADComputer $ADComputer2 -Properties MemberOf).MemberOf
    $formattedList2 = [System.Collections.ArrayList]::new()
    $ADGroups2 | ForEach-Object {
        $splitString = $_.split(",")
        $CNItem = $splitString[0]
        $groupName = $CNItem.SubString(3)
        $formattedList2.add($groupName) | Out-Null
    }

    $duplicates = [System.Collections.ArrayList]::new()
    $ADComputer1Uniques = [System.Collections.ArrayList]::new()
    $ADComputer2Uniques = [System.Collections.ArrayList]::new()

    foreach ($group in $formattedList1) {
        if ($formattedList2.Contains($group)) {
            $duplicates.add($group) | Out-Null
        }
        else {
            $ADComputer1Uniques.add($group) | Out-Null
        }
    }

    foreach ($group in $formattedList2) {
        if (-not $formattedList1.Contains($group)) {
            $ADComputer2Uniques.Add($group) | Out-Null
        }
    }

    Write-Host "`nBoth users are in these groups:" -ForegroundColor Green
    foreach ($group in $duplicates) {
        Write-Host $group
    }

    Write-Host "`n$ADComputer1 is in these unique groups:" -ForegroundColor Green
    foreach ($group in $ADComputer1Uniques) {
        Write-Host $group
    }

    Write-Host "`n$ADComputer2 is in these unique groups:" -ForegroundColor Green
    foreach ($group in $ADComputer2Uniques) {
        Write-Host $group
    }
}
