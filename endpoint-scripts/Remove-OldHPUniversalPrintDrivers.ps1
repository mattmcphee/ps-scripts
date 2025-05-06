Start-Transcript -Path "C:\Windows\Logs\Software\Remove-OldHPUniversalPrintDrivers.log"

# https://stackoverflow.com/questions/66580801/pnputil-retrieve-each-driver-and-add-to-array-with-psobject
function Get-DriversFromDriverStore {
    $List = New-Object System.Collections.ArrayList

    $driverInfo = PNPUtil.exe /Enum-Drivers | Select-String -Pattern 'Published Name:' -Context 0,7

    foreach ($driver in $driverInfo) {
        # some drivers have a class version attribute - do some string manip to cater for this
        if($driver.Context.PostContext[4] -like "*Class Version:*"){
            $ClassVersion = $driver.Context.PostContext[4] -replace '.*:\s+'
            $DriverVersion = $driver.Context.PostContext[5] -replace '.*:\s+'
            $SignerName = $driver.Context.PostContext[6] -replace '.*:\s+'
        } else {
            $ClassVersion = "N/A"
            $DriverVersion = $driver.Context.PostContext[4] -replace '.*:\s+'
            $SignerName = $driver.Context.PostContext[5] -replace '.*:\s+'
        }

        # Split the DriverVersion attribute into date and version
        $splitDateVersion = $DriverVersion -split " "
        $DriverDate = $splitDateVersion[0]
        $DriverVersionNumber = $splitDateVersion[1]

        # add info from pnputil /enum-drivers to pscustomobject then add it to the list
        $listItem = New-Object PSCustomObject
        $listItem | Add-Member -Membertype NoteProperty -Name PublishedName -Value (($driver | Select-String -Pattern 'Published Name:') -replace '.*:\s+')
        $listItem | Add-Member -Membertype NoteProperty -Name OriginalName -Value (($driver.Context.PostContext[0]) -replace '.*:\s+')
        $listItem | Add-Member -Membertype NoteProperty -Name ProviderName -Value (($driver.Context.PostContext[1]) -replace '.*:\s+')
        $listItem | Add-Member -Membertype NoteProperty -Name ClassName -Value (($driver.Context.PostContext[2]) -replace '.*:\s+')
        $listItem | Add-Member -Membertype NoteProperty -Name ClassGUID -Value (($driver.Context.PostContext[3]) -replace '.*:\s+')
        $listItem | Add-Member -Membertype NoteProperty -Name ClassVersion -Value $ClassVersion
        $listItem | Add-Member -Membertype NoteProperty -Name DriverVersionDate -Value $DriverDate
        $listItem | Add-Member -Membertype NoteProperty -Name DriverVersionNumber -Value $DriverVersionNumber
        $listItem | Add-Member -Membertype NoteProperty -Name SignerName -Value $SignerName

        $List.Add($listItem)
    }

    return $List
}

# print out driver info before the script makes changes
Write-Host "Before:"
# Version 17171305019303231 == 7.3.0
# get print management drivers
$prtMgmtDrivers = Get-PrinterDriver | Where-Object {
    ( $_.Name -like 'HP Universal Printing*' ) -and `
    ( $_.Name -notlike "HP Universal Printing PCL 5*" ) -and `
    ( $_.DriverVersion -lt 17171305019303231 )
}

Write-Host "Print management:"
$prtMgmtDrivers | Select-Object Name | Out-Host
# remove print management drivers
$prtMgmtDrivers | Remove-PrinterDriver -RemoveFromDriverStore

# get driver list using function above
$List = Get-DriversFromDriverStore

$driverStoreDrivers = $List | Where-Object {
    ( $_.ProviderName -eq "HP" ) -and `
    ( [version]$_.DriverVersionNumber -lt [version]"61.310.1.25919" ) -and `
    ( $_.OriginalName -like "*hpcu*" ) -and `
    ( $_.OriginalName -ne "hpcu180t.inf" )
}

Write-Host "Windows Driver Store:"
$driverStoreDrivers | Out-Host

# remove drivers using pnputil
foreach ($driverStoreDriver in $driverStoreDrivers) {
    pnputil.exe /delete-driver $driverStoreDriver.PublishedName /uninstall /force
}

# get driver registry keys - this will be used to remove from registry in cases where driver file locks
$registryPathItems = Get-ChildItem -Path "HKLM:\SYSTEM\CurrentControlSet\Control\Print\Environments\Windows x64\Drivers\Version-3"

$registryDrivers = $registryPathItems | Where-Object {
    ( $_.Name -like "*HP Universal Printing*" ) -and ( $_.Name -notlike "*HP Universal Printing PCL 5*" )
}

# create an array of registry items to delete and populate based on driver version number
$regEntriesToDelete = @()
foreach ($entry in $registryDrivers) {
    $driverVersion = (Get-ItemProperty -Path $entry.PSPath).DriverVersion
    if ([version]$driverVersion -lt [version]"61.310.1.25919") {
        $regEntriesToDelete += $entry
    }
}

# if array contains registry items to delete, remove registry items then restart the spooler service
if ($regEntriesToDelete.Length -gt 0) {
    Write-Host "Manual delete from registry..." -Foregroundcolor yellow
    $regEntriesToDelete | Out-Host

    $regEntriesToDelete | Remove-Item -Force

    Restart-Service -Name "Spooler" -Force

    # remove universal drivers from driver store
    # Version 17171305019303231 == 7.3.0
    Get-PrinterDriver | Where-Object {
        ( $_.Name -like 'HP Universal Printing*' ) -and `
        ( $_.Name -notlike "HP Universal Printing PCL 5*" ) -and `
        ( $_.DriverVersion -lt 17171305019303231 )
    } | Remove-PrinterDriver -RemoveFromDriverStore

    # remove print management drivers from driver store
    $prtMgmtDrivers = Get-DriversFromDriverStore | Where-Object {
        ( $_.ProviderName -eq "HP" ) -and `
        ( [version]$_.DriverVersionNumber -lt [version]"61.310.1.25919" ) -and `
        ( $_.OriginalName -like "*hpcu*" ) -and `
        ( $_.OriginalName -ne "hpcu180t.inf" )
    }

    foreach ($prtMgmtDriver in $prtMgmtDrivers) {
        pnputil.exe /delete-driver $prtMgmtDriver.PublishedName /uninstall /force
    }
}

# display the driver list after script has made changes
Write-Host " "
Write-Host "After:"
# Versjon 17171305019303231 == 7.3.0
$prtMgmtDrivers = Get-PrinterDriver | Where-Object {
    ( $_.Name -like 'HP Universal Printing*' ) -and `
    ( $_.Name -notlike "HP Universal Printing PCL 5*" ) -and `
    ( $_.DriverVersion -lt 17171305019303231 )
}
Write-Host "Print management:"
$prtMgmtDrivers | Select-Object Name | Out-Host
$List = Get-DriversFromDriverStore
$prtMgmtDrivers = $List | Where-Object {
    ( $_.ProviderName -eq "HP" ) -and `
    ( [version]$_.DriverVersionNumber -lt [version]"61.310.1.25919" ) -and `
    ( $_.OriginalName -like "*hpcu*" ) -and `
    ( $_.OriginalName -ne "hpcu180t.inf" )
}
Write-Host "Windows Driver Store: "
$prtMgmtDrivers | Out-Host

# Stop logging
Stop-Transcript
