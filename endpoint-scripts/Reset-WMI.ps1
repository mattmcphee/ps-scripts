# sc config winmgmt start=disabled
# net stop winmgmt /y
# %systemdrive%
# cd %windir%\system32\wbem
# for /f %%s in ('dir /b *.dll') do regsvr32 /s %%s
# wmiprvse /regserver 
# winmgmt /regserver 
# sc config winmgmt start= auto
# net start winmgmt
# for /f %%s in ('dir /s /b *.mof *.mfl') do mofcomp %%s

Set-Service -Name Winmgmt -StartupType Disabled
Stop-Service -Name Winmgmt -Force
Start-Sleep 5
$wmiDlls = Get-ChildItem -Path C:\Windows\system32\wbem\* -Include *.dll
$wmiDlls | ForEach-Object { 
    Start-Process -FilePath "C:\Windows\system32\regsvr32.exe" `
    -ArgumentList $_.FullName
    Write-Host "$($_.FullName) has been regsvr'd."
    Start-Sleep -Milliseconds 200
}
Start-Sleep 5
Start-Process -FilePath "C:\Windows\System32\wbem\WmiPrvSE.exe" `
    -ArgumentList "/regserver"
Start-Sleep 5
Start-Process -FilePath "C:\Windows\System32\wbem\winmgmt.exe" `
    -ArgumentList "/regserver"
Start-Sleep 5
Set-Service -Name Winmgmt -StartupType Automatic
Start-Service -Name Winmgmt
Start-Sleep 5
$wmiMofs = Get-ChildItem -Path C:\Windows\system32\wbem\* `
    -Include *.mof,*.mfl `
    -Recurse
$wmiMofs | ForEach-Object {
    Start-Process -FilePath "C:\Windows\System32\wbem\mofcomp.exe" `
        -ArgumentList $_.FullName
    Write-Host "$($_.FullName) has been recompiled."
    Start-Sleep -Milliseconds 200
}