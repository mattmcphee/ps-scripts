function Get-SCCMWmiQueryResult {
    [CmdletBinding()]
    param (
        # ComputerName
        [Parameter(Mandatory)]
        [string]
        $ComputerName,
        # Class - wmi class to use in the query
        [Parameter(Mandatory)]
        [string]
        $Class
    )

    $sccmComputerName = "bnesccm01"
    $sccmWmiNamespace = "root\SMS\site_A00"
    $resId = (Get-CMDevice -Name $ComputerName -Fast).ResourceID

    Get-WmiObject -ComputerName $sccmComputerName `
        -Namespace $sccmWmiNamespace `
        -Class $Class |
    Where-Object { $_.ResourceID -eq $resId } |
    Select-Object -First 1
}
