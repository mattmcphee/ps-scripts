<#
.SYNOPSIS
    Fixes the issue where the CCMSQLCE.log constantly generates and prevents the
    CCM client on the machine from reporting back to configuration manager
.DESCRIPTION
    Stops the CCMExec process ->
    stops the CCMExec service ->
    deletes theccmstore.sdf file ->
    restarts the ccmexec service ->
    runs the machine policy retrieval action ->
    runs the user policy retrieval action ->
    runs the hardware inventory cycle action ->
    runs the application deployment evaluation cycle ->
    runs the software update scan cycle ->
    runs the software update eval cycle
.EXAMPLE
    Reset-CCMSQLCELog -ComputerName 5CD151MCTX
#>

function Reset-CCMSQLCELog {
    [CmdletBinding()]
    param (
        # ComputerName
        [Parameter(Mandatory=$true)]
        [string]
        $ComputerName
    )

    # variables
    $sleepTime = 1

    # test if machine is online and psremoting is working by testing invoke-command
    Invoke-Command -ComputerName $ComputerName -ScriptBlock {} -ErrorAction Ignore
    $machineOnlineTestFailed = (-not $?)
    if ($machineOnlineTestFailed) {
        throw "Machine is not online or PSRemoting is not working on the machine."
    } else {
        Invoke-Command -ComputerName $ComputerName -ScriptBlock {
            Get-Process CCMExec* | Stop-Process -Force
            Start-Sleep 2
            Get-Service CCMExec* | Set-Service -Status Stopped
            Get-ChildItem -Path "C:\Windows\CCM\CcmStore.sdf" | Remove-Item -Force
            Start-Service CCMExec
            if ((Get-Service CCMExec).Status -notlike 'Running') {
                $errorMsg = "Attempt to restart CcmExec.exe failed. "
                $errorMsg += "Machine needs manual investigation."
                throw $errorMsg
            }
        }
    }

    Start-Sleep -Seconds $sleepTime
    # retrieve machine policy
    Invoke-WmiMethod -ComputerName $ComputerName `
    -Namespace root\ccm `
    -Class SMS_CLIENT `
    -Name TriggerSchedule "{00000000-0000-0000-0000-000000000021}" `
    -ErrorAction SilentlyContinue
    Start-Sleep -Seconds $sleepTime
    # retrieve user policy
    Invoke-WmiMethod -ComputerName $ComputerName `
    -Namespace root\ccm `
    -Class SMS_CLIENT `
    -Name TriggerSchedule "{00000000-0000-0000-0000-000000000026}" `
    -ErrorAction SilentlyContinue
    Start-Sleep -Seconds $sleepTime
    # hardware inventory
    Invoke-WmiMethod -ComputerName $ComputerName `
    -Namespace root\ccm `
    -Class SMS_CLIENT `
    -Name TriggerSchedule "{00000000-0000-0000-0000-000000000001}" `
    -ErrorAction SilentlyContinue
    Start-Sleep -Seconds $sleepTime
    # application deployment evaluation
    Invoke-WmiMethod -ComputerName $ComputerName `
    -Namespace root\ccm `
    -Class SMS_CLIENT `
    -Name TriggerSchedule "{00000000-0000-0000-0000-000000000121}" `
    -ErrorAction SilentlyContinue
    Start-Sleep -Seconds $sleepTime
    # software update scan cycle
    Invoke-WmiMethod -ComputerName $ComputerName `
    -Namespace root\ccm `
    -Class SMS_CLIENT `
    -Name TriggerSchedule "{00000000-0000-0000-0000-000000000113}" `
    -ErrorAction SilentlyContinue
    Start-Sleep -Seconds $sleepTime
    # software update eval cycle
    Invoke-WmiMethod -ComputerName $ComputerName `
    -Namespace root\ccm `
    -Class SMS_CLIENT `
    -Name TriggerSchedule "{00000000-0000-0000-0000-000000000114}" `
    -ErrorAction SilentlyContinue
    Start-Sleep -Seconds $sleepTime
}
