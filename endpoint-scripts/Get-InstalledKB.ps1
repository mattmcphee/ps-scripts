function Get-InstalledKB {
    [CmdletBinding()]
    param (
        # KB number
        [Parameter(Mandatory)]
        [string]
        $KB,
        # ComputerName
        [Parameter(Mandatory)]
        [object[]]
        $MachineList,
        # CsvPath
        [Parameter(Mandatory)]
        [string]
        $CsvPath
    )

    foreach ($machine in $MachineList) {
        $machineOnline = Test-Connection -ComputerName $machine -Count 2 -Quiet

        if ($machineOnline) {
            $hotfix = Invoke-Command -ComputerName $machine -ScriptBlock {
                Get-Hotfix | Where-Object { $_.HotfixID -eq $KB }
            }
        } else {
            Write-Host "$machine offline. Skipping..."
            continue
        }

        $hotfixFiltered = $hotfix |
        Select-Object @{n="ComputerName";e={$machine}},description,hotfixid,installedby,installedon

        $hotfixFiltered | Export-Csv -Path $CsvPath -Encoding utf8 -Append -NoTypeInformation
    }
}
