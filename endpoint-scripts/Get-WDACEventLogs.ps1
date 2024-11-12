function Get-WDACEventLogs {
  [CmdletBinding()]
  param (
    # Number of minutes to go back in time to retrieve logs
    [Parameter(Mandatory=$true)]
    [string]
    $MinutesBackInTime,
    # Whether or not to include exe and dll logs (many many of these)
    [Parameter()]
    [switch]
    $IncludeExeDll
  )

  $PastDate = (Get-Date).AddMinutes(-$MinutesBackInTime)

  Write-Host "===CodeIntegrity Operational Logs===" -ForegroundColor Green
  Get-WinEvent -LogName "Microsoft-Windows-CodeIntegrity/Operational" |
  Where-Object {$_.TimeCreated -gt $PastDate} |
  Format-Table -AutoSize | Out-String -Width 10000 #

  Write-Host "===MSI and Script Logs===" -ForegroundColor Green
  Get-WinEvent -LogName "Microsoft-Windows-AppLocker/MSI and Script" |
  Where-Object {$_.TimeCreated -gt $PastDate} |
  Format-Table -AutoSize | Out-String -Width 10000 #

  if ($IncludeExeDll) {
    Write-Host "===EXE and DLL Logs===" -ForegroundColor Green
    Get-WinEvent -LogName "Microsoft-Windows-AppLocker/EXE and DLL" |
    Where-Object {$_.TimeCreated -gt $PastDate} |
    Format-Table -AutoSize | Out-String -Width 10000 #
  }
}