$machines = `
    Get-Content "C:\sources\repos\ps-scripts\wdac-scripts\wdac-machines.txt"
$filepath = `
"C:\sources\repos\ps-scripts\wdac-scripts\Set-WDACApplocker.ps1"
foreach($machine in $machines) {
    Invoke-Command -ComputerName $machine `
        -ArgumentList "AuditOnly","Overwrite" `
        -FilePath $filepath
}

function Set-WDACApplocker {
    param(
        # ComputerName
        [Parameter(Mandatory=$true)]
        [string]
        $ComputerName
    )
    $filepath = "C:\sources\repos\ps-scripts\wdac-scripts\Set-WDACApplocker.ps1"
    Invoke-Command -ComputerName $ComputerName -ArgumentList "AuditOnly","Overwrite" -FilePath $filepath
}

function Set-NoApplocker {
    param(
        # ComputerName
        [Parameter(Mandatory=$true)]
        [string]
        $ComputerName
    )
    $filepath = "C:\sources\repos\ps-scripts\wdac-scripts\Set-NoApplocker.ps1"
    Invoke-Command -ComputerName $ComputerName -ArgumentList "AuditOnly","Overwrite" -FilePath $filepath
}

$filepath = "C:\sources\repos\ps-scripts\wdac-scripts\Set-NoApplocker.ps1"
Invoke-Command -ComputerName "5CD42935N5" `
-ArgumentList "AuditOnly","Overwrite" `
-FilePath $filepath

$filepath = `
"C:\sources\repos\ps-scripts\wdac-scripts\Set-WDACApplocker.ps1"
Invoke-Command -ComputerName "MMWIN11-03" `
-ArgumentList "AuditOnly","Overwrite" `
-FilePath $filepath

$filepath = `
"C:\sources\repos\ps-scripts\wdac-scripts\Set-WDACApplocker.ps1"
Invoke-Command -ComputerName "MMWIN11-01" `
-ArgumentList "AuditOnly","Overwrite" `
-FilePath $filepath

$filepath = `
"C:\sources\repos\ps-scripts\wdac-scripts\Set-NoApplocker.ps1"
Invoke-Command -ComputerName "MMWIN11-03" `
-ArgumentList "AuditOnly","Overwrite" `
-FilePath $filepath
