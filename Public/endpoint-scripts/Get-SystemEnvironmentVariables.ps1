function Get-SystemEnvironmentVariables {
    [CmdletBinding()]
    param (
        # ComputerName
        [Parameter(Mandatory=$false)]
        [string]$ComputerName
    )

    if ($PSBoundParameters["ComputerName"]) {
        try {
            Invoke-Command -ComputerName $ComputerName -ScriptBlock {
                [Environment]::GetEnvironmentVariables("Machine")
            }
        } catch {
            throw $_
        }
    } else {
        [Environment]::GetEnvironmentVariables("Machine")
        return
    }
}
