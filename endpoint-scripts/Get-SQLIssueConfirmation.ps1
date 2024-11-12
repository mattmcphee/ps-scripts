function Get-SQLIssueConfirmation {
    param(
        # ComputerName
        [Parameter(Mandatory=$true)]
        [string]
        $ComputerName
    )
    # test if machine is online and psremoting is working by testing invoke-command
    Invoke-Command -ComputerName $ComputerName -ScriptBlock {} -ErrorAction Ignore
    $machineOnlineTestFailed = (-not $?)
    if ($machineOnlineTestFailed) {
        throw "Machine is offline or psremoting/winrm is cooked."
    }
    $sql = Invoke-Command -ComputerName $ComputerName -ScriptBlock {
        Get-Content 'C:\Windows\CCM\Logs\CCMSQLCE.log'
    }
    ([regex]::matches($sql,"active concurrent sessions")).count
}