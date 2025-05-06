function Repair-ConfigMGRClient {
    <#
    .SYNOPSIS
    Runs health check on ConfigMGR Client
    #>

    param (
        [Parameter(Mandatory = $true)]
        [string]
        $ComputerName
    )

    # variables
    $sleepTime = 1

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
}
