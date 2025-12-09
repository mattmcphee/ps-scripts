function Get-SamsungMobileComplianceData {
    $driver = Start-SeEdge
    Start-Sleep 5
    Enter-SeUrl -Driver $driver -Url "https://doc.samsungmobile.com/SM-A525F/XSA/doc.html"
    Start-Sleep 5
    Stop-SeDriver -Driver $driver
}
