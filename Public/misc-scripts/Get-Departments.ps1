function Get-Departments {
    $initialLocation = Get-Location
    Set-Location -Path "C:\"
    $csvPath = "\\bmd\bmdapps\BI\JamesG\Departments.csv"
    $csvDestination = "$env:USERPROFILE\Downloads\Departments.csv"
    Copy-Item -Path $csvPath -Destination $csvDestination -Force
    Import-Csv -Path $csvDestination
    Set-Location -Path $initialLocation
}
