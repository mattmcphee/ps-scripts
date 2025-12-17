function New-Day {
    [CmdletBinding()]
    param (
        # Day
        [Parameter(Mandatory)]
        [ValidateSet("Monday","Tuesday","Wednesday","Thursday","Friday")]
        [string]
        $Day
    )

    $homeLaptop = "5cd3155227"
    $workLaptop = "5cd5152rbl"
    $date = Get-Date -Format "yyyy-MM-dd"
    $dateLong = Get-Date -Format "dd-MMM-yyyy"
    $dateArr = $date -split "-"
    $dateYear = $dateArr[0]
    # $dateMonth = $dateArr[1]
    # $dateDay = $dateArr[2]
    $workLaptopPath = "\\$workLaptop\C$\Users\matmcp1\OneDrive - B.M.D. Holdings Pty. Limited\Documents\weeklynotepad$dateYear\$date.txt"
    $homeLaptopPath = "\\$homeLaptop\C$\Users\matmcp1\OneDrive - B.M.D. Holdings Pty. Limited\Documents\weeklynotepad$dateYear\$date.txt"
    
    if ($Day -like "Wednesday" -or $Day -like "Thursday") {
        # home laptop
        if (-not ($homeLaptopPath)) {
            New-Item -Path $homeLaptopPath -Force
        }
        Get-BlockLetters $Day | Add-Content -Path $homeLaptopPath
        Get-BlockLetters $dateLong | Add-Content -Path $homeLaptopPath
        Add-Content -Path $homeLaptopPath -Value ""
    } else {
        # work laptop
        if (-not ($workLaptopPath)) {
            New-Item -Path $workLaptopPath -Force
        }
        Get-BlockLetters $Day | Add-Content -Path $workLaptopPath
        Get-BlockLetters $dateLong | Add-Content -Path $workLaptopPath
        Add-Content -Path $workLaptopPath -Value ""
    }
}
