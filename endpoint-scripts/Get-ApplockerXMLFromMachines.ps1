function Get-ApplockerXMLFromMachines {
    [CmdletBinding()]
    param (
        # Filepath to a list of test machines
        [Parameter(Mandatory=$true)]
        [ValidateScript({Test-Path $_})]
        [string]
        $MachineListPath
    )

    $machines = Get-Content $MachineListPath
    foreach($machine in $machines) {
        $machineXML = Invoke-Command -ComputerName $machine `
        -ScriptBlock {
            Get-AppLockerPolicy -Effective -Xml
        }

        $machineXML | Out-File "C:\sources\applocker-$machine.xml"
    }
}