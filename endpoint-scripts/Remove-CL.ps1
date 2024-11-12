function Remove-CL {
    [CmdletBinding()]
    param (
        # ComputerName
        [Parameter(Mandatory=$true)]
        [string]
        $ComputerName
    )
    
    Invoke-Command -ComputerName $ComputerName -ScriptBlock {
        reg delete "HKLM\SYSTEM\CurrentControlSet\Control\Session Manager\Environment" /v "__PSLockdownPolicy" /f
    }
}

