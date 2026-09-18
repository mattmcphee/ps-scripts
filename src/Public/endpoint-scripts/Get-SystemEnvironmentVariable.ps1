function Get-SystemEnvironmentVariable {
    [CmdletBinding()]
    param (
        # Name
        [Parameter(Mandatory)]
        [string]$Name,

        # ComputerName
        [Parameter(Mandatory=$false)]
        [string]$ComputerName
    )

    if ($PSBoundParameters["ComputerName"]) {
        try {
            Invoke-Command -ComputerName $ComputerName -ScriptBlock {
                [Environment]::GetEnvironmentVariable($using:Name, "Machine")
            }
        } catch {
            throw $_
        }
    } else {
        [Environment]::GetEnvironmentVariable($Name, "Machine")
    }
}
