function Get-Nearest100 {
    param (
        # number
        [Parameter(Mandatory)]
        [ValidateRange(1, [int]::MaxValue)]
        [int]
        $Number
    )

    return ($Number + (100 - ($Number % 100)))
}
