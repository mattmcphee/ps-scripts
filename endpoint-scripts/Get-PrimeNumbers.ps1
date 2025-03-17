function Get-PrimeNumbers {
    param(
        # max number to check
        [Parameter(Mandatory)]
        [int]
        $Max
    )
    for ($n = 3; $n -lt $Max; $n++) {
        try {
            for ($d = 2; $d -le [Math]::Sqrt($n); $d++) {
                if ($n % $d -eq 0) {
                    throw
                }
            }
            Write-Host -NoNewLine "$n "
        }
        catch { }
    }
}
