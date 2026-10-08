function Restart-IntuneService {
    [CmdletBinding()]
    param (
        # ComputerName
        [Parameter(Mandatory=$false,ValueFromPipeline)]
        [string[]]$ComputerName = $env:COMPUTERNAME
    )

    begin {
        $scriptBlock = {
            Get-Service -Name "IntuneManagementExtension" | Restart-Service -Force
        }
    }

    process {
        foreach ($computer in $computerName) {
            Invoke-Command -ComputerName $computer -ScriptBlock $scriptBlock
            Write-Host "Restarted IntuneManagementExtension service on $computer."
        }
    }
}
