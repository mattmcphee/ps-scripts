function Write-DashLine {
    param(
        [string]$Text
    )

    $totalLength = 100
    $dashCount = $totalLength - $Text.Length
    $dashChar = "="
    $boundChar = "|"
    $boundStart = $boundChar + $dashChar * 3
    $boundEnd = $dashChar * 3 + $boundChar

    if ($dashCount -le 0) {
        $line = "$boundStart $Text $boundEnd"
    } else {
        $boundEndDynamic = $dashChar * ($dashCount) + $boundEnd
        $line = "$boundStart $Text $boundEndDynamic"
    }

    Write-Host $line -ForegroundColor Cyan
}
