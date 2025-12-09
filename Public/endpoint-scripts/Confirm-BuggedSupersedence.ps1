function Confirm-BuggedSupersedence {
    [CmdletBinding()]
    param (
        # ComputerName
        [Parameter(Mandatory, ValueFromPipeline)]
        [string]
        $ComputerName
    )

    begin {
        # requires filesystem provider
        $startLoc = Get-Location
        Set-Location "C:\"

        $timestamp = Get-Date -Format 'yyyyMMdd_HHmmss'
        $csvFileName = "C:\sources\csv\12d-ss-bug-$timestamp.csv"
        $null = New-Item -Path $csvFileName -Force
    }

    process {
        $result = [PSCustomObject]@{
            ComputerName      = $null
            "Has The Issue?"  = $null
            "Last Error Date" = $null
            "Last Error Time" = $null
        }
        
        if (-not (Test-Connection $ComputerName -Quiet -Count 2)) {
            $result = [PSCustomObject]@{
                ComputerName   = $ComputerName
                "HasTheIssue?" = "Machine is offline"
            }
            Write-Host "$ComputerName is offline" -ForegroundColor Yellow
            $result | Export-Csv -Path $csvFileName -Append -NoTypeInformation
            return
        }

        $appIntentLogPath = "\\$ComputerName\c$\Windows\CCM\Logs\AppIntentEval.log"

        if (-not (Test-Path $appIntentLogPath)) {
            $result = [PSCustomObject]@{
                ComputerName   = $ComputerName
                "HasTheIssue?" = "AppIntentEval.log not found"
            }
            Write-Host "AppIntentEval.log not found on $ComputerName" -ForegroundColor Yellow
            $result | Export-Csv -Path $csvFileName -Append -NoTypeInformation
            return
        }

        # this is the error we are searching for
        $pattern = "Superseded DT ScopeId_CAB634EA-40F0-4556-B4B6-A21E63677A80/DeploymentType_030e37ca-ed56-42dc-8380-e74a2be79fe2/2 selected for installation. Returning error 0x87d00266"

        $lastLogLineMatch = Get-Content $appIntentLogPath |
        Sort-Object -Descending |
        Select-String -Pattern $pattern |
        Select-Object -First 1

        if ($lastLogLineMatch) {
            $lastLogLineWithError = $lastLogLineMatch.ToString()

            $datePattern = 'date="(\d{2})-(\d{2})-(\d{4})"'
            $dateMatch = $lastLogLineWithError | Select-String -Pattern $datePattern
            $day = $dateMatch.Matches.Groups[2].Value
            $month = $dateMatch.Matches.Groups[1].Value
            $year = $dateMatch.Matches.Groups[3].Value
            $formattedDate = "$year-$month-$day"

            $timePattern = 'time="(\d{2}:\d{2}:\d{2})\.\d+-\d+"'
            $timeMatch = $lastLogLineWithError | Select-String -Pattern $timePattern
            $formattedTime = $timeMatch.Matches.Groups[1].Value

            $result = [PSCustomObject]@{
                ComputerName    = $ComputerName
                "HasTheIssue?"  = "Yes"
                "Last Log Date" = $formattedDate
                "Last Log Time" = $formattedTime
            }
            Write-Host "$ComputerName has the issue!" -ForegroundColor Red
            $result | Export-Csv -Path $csvFileName -Append -NoTypeInformation
        } else {
            $result = [PSCustomObject]@{
                ComputerName   = $ComputerName
                "HasTheIssue?" = "No"
            }
            Write-Host "$ComputerName does not have the issue. Phew!" -ForegroundColor Green
            $result | Export-Csv -Path $csvFileName -Append -NoTypeInformation
        }
    }

    end {
        Set-Location $startLoc
    }
}
