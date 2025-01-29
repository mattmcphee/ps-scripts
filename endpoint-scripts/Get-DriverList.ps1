function Get-DriverList {
    [CmdletBinding()]
    param (
        # ComputerName
        [Parameter(Mandatory=$true)]
        [string]
        $ComputerName
    )
    Invoke-Command -ComputerName $ComputerName -ScriptBlock {
        if (-not (Test-Path 'C:\source')) {
            New-Item -ItemType Directory -Path 'C:\source'
        }
        Get-CimInstance -ClassName Win32_PnPSignedDriver |
        Select-Object Description, DeviceName, DriverVersion, DriverDate |
        Export-Csv -NoTypeInformation -Path 'C:\source\drivers.csv'
    }
}