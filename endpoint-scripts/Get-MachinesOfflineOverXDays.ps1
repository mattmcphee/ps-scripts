<#
.SYNOPSIS
    A short one-line action-based description, e.g. 'Tests if a function is valid'
.DESCRIPTION
    A longer description of the function, its purpose, common use cases, etc.
.NOTES
    Information or caveats about the function e.g. 'This function is not supported in Linux'
.LINK
    Specify a URI to a help page, this will show when Get-Help -Online is used.
.EXAMPLE
    Test-MyTestFunction -Verbose
    Explanation of the function or its result. You can include multiple examples with additional .EXAMPLE lines
#>

function Get-MachinesOfflineOverXDays {
    param(
        # days
        [Parameter(Mandatory=$false)]
        [int32]
        $Days = 14
    )
    Get-CMDevice -Fast | Where-Object {
        ($null -ne $_.LastDDR) -and `
        ((New-TimeSpan -Start $_.LastDDR -End (Get-Date)).Days -ge $Days) -and `
        (Test-Connection -ComputerName $_.Name -Count 2 -Quiet)
    } | Select-Object Name,LastDDR,ADLastLogonTime
}