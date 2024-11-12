function Set-AppLockerXMLForMachines {
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
        Invoke-Command -ComputerName $machine -ScriptBlock {
            Set-AppLockerPolicy -XmlPolicy "C:\sources\xml\applocker.xml"
        }
    }
}