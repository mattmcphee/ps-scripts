function Repair-ConfigMGRClient {
    <#
    .SYNOPSIS
    Runs health check on ConfigMGR Client

    .DESCRIPTION
    Runs health check on ConfigMGR Client and upgrade to current version if less than current version
    It will also attempt to repair BITS, DNS, Updates missing, Free Space, WMI, Windows Update Agent, select services.
    Also advise of drivers that are an issue and pending reboot

    .PARAMETER Computers
    Specify single or multiple computers to run against. This is manadatory

    .PARAMETER InvokeActions
    This will run on the specified systems the following ConfigMGR Agent actions: Machine Policy Retrieval & Evaluation Cycle, User Policy Retrieval & Evaluation Cycle, Application Deployment Evaluation Cycle, Software Update Scan, Software Update Deployment Evaluation Cycle

    .PARAMETER Updates
    This will change behaviour from checking if select updates are missing to installing these missing updates.

    .INPUTS
    None. You cannot pipe objects to Add-Extension.

    .OUTPUTS
    Logs are stored \\bmd\bmdapps\MEM_ClientHealthLogs

    .NOTES
    Version:        1.3
    Author:         Bryan Bultitude
    Creation Date:  11/08/2021
    Purpose/Change: 11/08/2021 - Bryan Bultitude - Initial script development
                    13/08/2021 - Bryan Bultitude - Added ConfigMGRClientHealth.ps1 versioning. Initial version set to '1.0.0 (BMD Customized)'
                    17/08/2021 - Bryan Bultitude - Incremented ConfigMGRClientHealth.ps1 version to '1.0.1 (BMD Customized)'
                    09/12/2021 - Bryan Bultitude - Moved Comment Based Help to top of function

    .EXAMPLE
    PS> Check-MEMAgentHealth -Computer Computer1

    .EXAMPLE
    PS> Check-MEMAgentHealth -Computer "Computer1","Computer2","Computer3"

    .EXAMPLE
    PS> Check-MEMAgentHealth -Computer Computer1 -InvokeActions

    .EXAMPLE
    PS> Check-MEMAgentHealth -Computer Computer1 -Updates

    .EXAMPLE
    PS> Check-MEMAgentHealth -Computer Computer1 -InvokeActions -Updates

    .EXAMPLE
    PS> Check-MEMAgentHealth -Computer "Computer1","Computer2","Computer3" -InvokeActions -Updates

    #> 
    param (
        [Parameter(Mandatory = $true)]
        [string[]]
        $Computers,
        [Parameter(Mandatory = $false)]
        [Switch]
        $InvokeActions,
        [Parameter(Mandatory = $false)]
        [Switch]
        $Updates
    )
    $computerCount = $Computers.Count
    $progressTracker = 0
    foreach ($computer in $Computers) {
        Write-Host $computer
        $pingable = Test-Connection $computer -Count 2 -Quiet
        $progressTracker += 0.25
        if ($pingable -eq $true) {
            Invoke-Command -ComputerName $computer -ScriptBlock {
                if (Get-ScheduledTask | Where-Object { $_.TaskName -eq "Health Checking" }) { schtasks /delete /tn "Health Checking" /f }
            }
            if ($Updates -eq $false) {
                Invoke-Command -ComputerName $computer -ScriptBlock {
                    $schedtask = @"
<?xml version="1.0" encoding="UTF-16"?>
<Task version="1.4" xmlns="http://schemas.microsoft.com/windows/2004/02/mit/task">
  <RegistrationInfo>
    <Date>2021-08-10T12:46:22</Date>
    <Author>BMD\bb.su</Author>
    <URI>\HealthCheckingCheck</URI>
  </RegistrationInfo>
  <Principals>
    <Principal id="Author">
      <UserId>S-1-5-18</UserId>
      <RunLevel>HighestAvailable</RunLevel>
    </Principal>
  </Principals>
  <Settings>
    <DisallowStartIfOnBatteries>false</DisallowStartIfOnBatteries>
    <StopIfGoingOnBatteries>false</StopIfGoingOnBatteries>
    <ExecutionTimeLimit>P1D</ExecutionTimeLimit>
    <MultipleInstancesPolicy>StopExisting</MultipleInstancesPolicy>
    <IdleSettings>
      <StopOnIdleEnd>false</StopOnIdleEnd>
      <RestartOnIdle>false</RestartOnIdle>
    </IdleSettings>
    <UseUnifiedSchedulingEngine>true</UseUnifiedSchedulingEngine>
  </Settings>
  <Triggers />
  <Actions Context="Author">
    <Exec>
      <Command>Powershell.exe</Command>
      <Arguments>-WindowStyle Hidden -ExecutionPolicy Bypass -File \\bmd\bmdapps\MEM_ClientHealth\ConfigMgrClientHealth.ps1 -Config \\bmd\bmdapps\MEM_ClientHealth\configUpdateCheck.xml</Arguments>
    </Exec>
  </Actions>
</Task>
"@
                    Register-ScheduledTask -xml $schedtask -TaskName "Health Checking"
                    #schtasks /create /sc ONSTART /TN "Health Checking" /TR 'Powershell.exe -WindowStyle Hidden -ExecutionPolicy Bypass -File "\\bmd\bmdapps\MEM_ClientHealth\ConfigMgrClientHealth.ps1" -Config "\\bmd\bmdapps\MEM_ClientHealth\configUpdateCheck.xml"' /RU SYSTEM /RL HIGHEST
                }
            }
            if ($Updates -eq $true) {
                Invoke-Command -ComputerName $computer -ScriptBlock {
                    $schedtask = @"
<?xml version="1.0" encoding="UTF-16"?>
<Task version="1.4" xmlns="http://schemas.microsoft.com/windows/2004/02/mit/task">
  <RegistrationInfo>
    <Date>2021-08-10T12:46:22</Date>
    <Author>BMD\bb.su</Author>
    <URI>\HealthCheckingCheck</URI>
  </RegistrationInfo>
  <Principals>
    <Principal id="Author">
      <UserId>S-1-5-18</UserId>
      <RunLevel>HighestAvailable</RunLevel>
    </Principal>
  </Principals>
  <Settings>
    <DisallowStartIfOnBatteries>false</DisallowStartIfOnBatteries>
    <StopIfGoingOnBatteries>false</StopIfGoingOnBatteries>
    <ExecutionTimeLimit>P1D</ExecutionTimeLimit>
    <MultipleInstancesPolicy>StopExisting</MultipleInstancesPolicy>
    <IdleSettings>
      <StopOnIdleEnd>false</StopOnIdleEnd>
      <RestartOnIdle>false</RestartOnIdle>
    </IdleSettings>
    <UseUnifiedSchedulingEngine>true</UseUnifiedSchedulingEngine>
  </Settings>
  <Triggers />
  <Actions Context="Author">
    <Exec>
      <Command>Powershell.exe</Command>
      <Arguments>-WindowStyle Hidden -ExecutionPolicy Bypass -File \\bmd\bmdapps\MEM_ClientHealth\ConfigMgrClientHealth.ps1 -Config \\bmd\bmdapps\MEM_ClientHealth\configUpdateFix.xml</Arguments>
    </Exec>
  </Actions>
</Task>
"@
                    Register-ScheduledTask -xml $schedtask -TaskName "Health Checking"
                    #schtasks /create /sc ONSTART /TN "Health Checking" /TR 'Powershell.exe -WindowStyle Hidden -ExecutionPolicy Bypass -File "\\bmd\bmdapps\MEM_ClientHealth\ConfigMgrClientHealth.ps1" -Config "\\bmd\bmdapps\MEM_ClientHealth\configUpdateFix.xml"' /RU SYSTEM /RL HIGHEST
                }
            }
            Invoke-Command -ComputerName $computer -ScriptBlock {
                $progressTracker += 0.25
                Write-Progress -activity "Health Check" -status "Status: " -PercentComplete (($progressTracker / $computerCount) * 100)
                Start-Sleep -Seconds 5
                Get-ScheduledTask -TaskName "Health Checking" | Start-ScheduledTask
                do {
                    Start-Sleep -Seconds 5
                    $schedtask = Get-ScheduledTask -TaskName "Health Checking"
                    $TaskState = $schedtask.State
                }
                until ($TaskState -eq "Ready")
                $progressTracker += 0.25
                Write-Progress -activity "Health Check" -status "Status: " -PercentComplete (($progressTracker / $computerCount) * 100)
                Start-Sleep -Seconds 5
                schtasks /delete /tn "Health Checking" /f
            } -ErrorAction SilentlyContinue
            if ($InvokeActions -eq $true) {
                Invoke-WMIMethod -ComputerName $computer -Namespace root\ccm -Class SMS_CLIENT -Name TriggerSchedule "{00000000-0000-0000-0000-000000000021}" -ErrorAction SilentlyContinue
                Invoke-WMIMethod -ComputerName $computer -Namespace root\ccm -Class SMS_CLIENT -Name TriggerSchedule "{00000000-0000-0000-0000-000000000022}" -ErrorAction SilentlyContinue
                Invoke-WMIMethod -ComputerName $computer -Namespace root\ccm -Class SMS_CLIENT -Name TriggerSchedule "{00000000-0000-0000-0000-000000000026}" -ErrorAction SilentlyContinue
                Invoke-WMIMethod -ComputerName $computer -Namespace root\ccm -Class SMS_CLIENT -Name TriggerSchedule "{00000000-0000-0000-0000-000000000027}" -ErrorAction SilentlyContinue
                Invoke-WMIMethod -ComputerName $computer -Namespace root\ccm -Class SMS_CLIENT -Name TriggerSchedule "{00000000-0000-0000-0000-000000000121}" -ErrorAction SilentlyContinue
                Invoke-WMIMethod -ComputerName $computer -Namespace root\ccm -Class SMS_CLIENT -Name TriggerSchedule "{00000000-0000-0000-0000-000000000113}" -ErrorAction SilentlyContinue
                Invoke-WMIMethod -ComputerName $computer -Namespace root\ccm -Class SMS_CLIENT -Name TriggerSchedule "{00000000-0000-0000-0000-000000000114}" -ErrorAction SilentlyContinue
                Invoke-WMIMethod -ComputerName $computer -Namespace root\ccm -Class SMS_CLIENT -Name TriggerSchedule "{00000000-0000-0000-0000-000000000001}" -ErrorAction SilentlyContinue 
            }
            $progressTracker += 0.25
            Write-Progress -activity "Health Check" -status "Status: " -PercentComplete (($progressTracker / $computerCount) * 100)
        }
    }
}