$machines = `
    Get-Content "C:\sources\repos\ps-scripts\wdac-scripts\wdac-machines.txt"
$filepath = `
"C:\sources\repos\ps-scripts\wdac-scripts\Set-WDACApplocker.ps1"
foreach($machine in $machines) {
    Invoke-Command -ComputerName $machine `
        -ArgumentList "AuditOnly","Overwrite" `
        -FilePath $filepath
}

$filepath = `
"C:\sources\repos\ps-scripts\wdac-scripts\Set-WDACApplocker.ps1"
Invoke-Command -ComputerName "MMWIN11-04" `
-ArgumentList "AuditOnly","Overwrite" `
-FilePath $filepath

$filepath = `
"C:\sources\repos\ps-scripts\wdac-scripts\Set-NoApplocker.ps1"
Invoke-Command -ComputerName "MMWIN11-04" `
-ArgumentList "AuditOnly","Overwrite" `
-FilePath $filepath

$filepath = `
"C:\sources\repos\ps-scripts\wdac-scripts\Set-NoApplocker.ps1"
Invoke-Command -ComputerName "5CG21386SL" `
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