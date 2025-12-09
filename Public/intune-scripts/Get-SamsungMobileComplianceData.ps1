function Get-SamsungMobileComplianceData {
    $driver = Start-SeEdge
    sleep 5
    Enter-SeUrl -Driver $driver -Url "https://doc.samsungmobile.com/SM-A525F/XSA/doc.html"
    sleep 5
    Stop-SeDriver -Driver $driver
}
