function Get-EventsByID {
    param(
        # EventIDs
        [Parameter(Mandatory)]
        [string[]]
        $EventIDs
    )

    Get-WinEvent | Where-Object { $_.Id -in $EventIDs }
}
