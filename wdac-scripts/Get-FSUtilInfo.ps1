function Get-FSUtilInfo {
    [CmdletBinding()]
    param (
        # remote computer name
        [Parameter(Mandatory=$false)]
        [string]
        $ComputerName = $env:COMPUTERNAME,
        # file path
        [Parameter(Mandatory=$true)]
        [string]
        $FilePath
    )
    Invoke-Command -ComputerName $ComputerName -ScriptBlock {
        & fsutil file queryea $FilePath
    }
}