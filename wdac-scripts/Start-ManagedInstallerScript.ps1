$machines = Get-Content "C:\sources\txt\wdac-machines.txt"
$filepath = `
"C:\sources\repos\ps-scripts\wdac-scripts\Set-WDACApplocker.ps1"
foreach($machine in $machines) {
    Invoke-Command -ComputerName $machine `
        -ArgumentList "AuditOnly","Overwrite" `
        -FilePath $filepath
}