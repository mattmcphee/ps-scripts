<#
.SYNOPSIS
    Fixes the issue where the CCMSQLCE.log constantly generates and prevents the 
    CCM client on the machine from reporting back to configuration manager
.DESCRIPTION
    Stops the CCMExec process -> stops the CCMExec service -> deletes the
    ccmstore.sdf file -> restarts the ccmexec service
.NOTES
    Make sure to run the big 4 sccm actions or run check-memagenthealth on
    the machine afterwards to ensure the sccm client reports back
.EXAMPLE
    Reset-CCMSQLCELog -ComputerName 5CD151MCTX
#>

function Reset-CCMSQLCELog {
    [CmdletBinding()]
    param (
        # ComputerName
        [Parameter(Mandatory=$false)]
        [string]
        $ComputerName = $env:COMPUTERNAME
    )
    # test if machine is online and psremoting is working by testing invoke-command
    Invoke-Command -ComputerName $ComputerName -ScriptBlock {} -ErrorAction Ignore
    $machineOnlineTestFailed = (-not $?)
    if ($machineOnlineTestFailed) {
        throw "Machine is not online or PSRemoting is not working on the machine."
    } else {
        $session = New-PSSession -ComputerName $ComputerName
        Invoke-Command -Session $session -ScriptBlock {
            Get-Process CCMExec* | Stop-Process -Force
            Start-Sleep 5
            Get-Service CCMExec* | Set-Service -Status Stopped
            Get-ChildItem -Path "C:\Windows\CCM" CcmStore.sdf | Remove-Item -Force
            Start-Service CCMExec
            Start-Process 'C:\Windows\CCM\CCMExec.exe' -Wait
            if ((Get-Service CCMExec).Status -notlike 'Running') {
                $errorMsg = "Attempt to restart CcmExec.exe failed. "
                $errorMsg += "Machine needs manual investigation."
                throw $errorMsg
            }
        } # end invoke scriptblock
        Remove-PSSession $session
    }
}