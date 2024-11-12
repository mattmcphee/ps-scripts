$winmgmt = "winmgmt.exe" 
$arg1 = "/verifyRepository"
$arg2 = "/salvageRepository" 
$arg3 = "/resetRepository"
 
if ((Get-WmiObject -Namespace root\cimv2 -Class Win32_ComputerSystem) -and `
    (Get-WmiObject -Namespace root\RSOP -Class __Namespace)) {
        Write-Host "WMI is working"
} else {
    #Salvage First
    $SalvageResult = & $winmgmt $arg2 

    if (($SalvageResult -eq "WMI repository is consistent") -and `
    (Get-WmiObject -Namespace root\cimv2 -Class Win32_ComputerSystem) -and `
    (Get-WmiObject -Namespace root\RSOP -Class __Namespace)) {
        Write-Host "Salvage has fixed WMI"
    } else {
        #Reset Second 
        $ResetResult = & $winmgmt $arg3
        if ((Get-WmiObject -Namespace root\cimv2 -Class Win32_ComputerSystem) -and `
        (Get-WmiObject -Namespace root\RSOP -Class __Namespace)) {
            Write-Host "Reset has fixed WMI"
        } else {
            #Rebuild Last 
            try {
                Get-Service -Name Winmgmt | Set-Service -StartupType Disabled
                Get-Service -Name Winmgmt | Stop-Service -Force
            } catch {
                Write-Host "Service couldn't stop"
                $p=Tasklist /svc /fi "SERVICES eq winmgmt" /fo csv | convertfrom-csv
                Stop-Process $p.PID -Force  
            }
            $i = 0
            Get-ChildItem -Path "$env:windir\System32\wbem\" -Filter "Repository*" | ForEach-Object {$i ++} 
            Get-ChildItem -Path "$env:windir\System32\wbem\" -Filter "Repository" | Rename-Item -NewName "Repository$i" 
            Get-Service -Name Winmgmt | Set-Service -StartupType Automatic
            Get-Service -Name Winmgmt | Start-Service
            
            if ((Get-WmiObject -Namespace root\cimv2 -Class Win32_ComputerSystem) -and `
            (Get-WmiObject -Namespace root\RSOP -Class __Namespace)) {
                Write-Host "Rebuild has fixed WMI"
            } else {
                Write-Host "Salvage, Reset and Rebuild Failed. Please manually fix."
            }
        }
    }
}

if ((Get-WmiObject -Namespace root\cimv2 -Class Win32_ComputerSystem) -and `
(Get-WmiObject -Namespace root\RSOP -Class __Namespace)) {
    Write-Host "WMI is working"
} else {
    Write-Host "WMI is not working"
}