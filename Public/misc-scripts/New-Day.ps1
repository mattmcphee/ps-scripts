function New-Day {
    [CmdletBinding()]
    param (
        # Day
        [Parameter(Mandatory)]
        [ValidateSet("Monday","Tuesday","Wednesday","Thursday","Friday")]
        [string]
        $Day
    )

    $date = Get-Date -Format "yyyy-MM-dd"
    $dateLong = Get-Date -Format "dd-MMM-yyyy"
    $dateArr = $date -split "-"
    $dateYear = $dateArr[0]
    # $dateMonth = $dateArr[1]
    # $dateDay = $dateArr[2]
    $notePath = "$env:systemdrive\sources\repos\weekly-notepad\weeklynotepad$dateYear\$date.txt"

    if (-not ($notePath)) {
        New-Item -Path $notePath -Force
    }

    Get-BlockLetters $Day | Add-Content -Path $notePath
    Get-BlockLetters $dateLong | Add-Content -Path $notePath
    Add-Content -Path $notePath -Value ""
}
