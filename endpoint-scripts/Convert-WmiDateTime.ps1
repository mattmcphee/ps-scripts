function Convert-WmiDateTime {
    param (
        # WmiDateTime string
        [Parameter(Mandatory)]
        [string]
        $WmiDateTime
    )
    # 20250402133057.000000+***
    $dotIndex = $WmiDateTime.IndexOf(".")
    $WmiDateTime = $WmiDateTime.Substring(0,$dotIndex)
    $year = $WmiDateTime.Substring(0,4)
    $month = $WmiDateTime.Substring(4,2)
    $day = $WmiDateTime.Substring(6,2)
    $hour = $WmiDateTime.Substring(8,2)
    $minute = $WmiDateTime.Substring(10,2)
    $second = $WmiDateTime.Substring(12,2)

    return "$year/$month/$day $($hour):$($minute):$($second)"
}
