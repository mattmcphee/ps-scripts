function Copy-BypassAppsToSource {
    $appList = @(
        'addinprocess.exe',
        'addinprocess32.exe',
        'addinutil.exe',
        'aspnet_compiler.exe',
        'bash.exe',
        'bginfo.exe',
        'cdb.exe',
        'cscript.exe',
        'csi.exe',
        'dbghost.exe',
        'dbgsvc.exe',
        'dbgsrv.exe',
        'dnx.exe',
        'dotnet.exe',
        'fsi.exe',
        'fsiAnyCpu.exe',
        'infdefaultinstall.exe',
        'kd.exe',
        'kill.exe',
        'lxssmanager.dll',
        'lxrun.exe',
        'Microsoft.Build.dll',
        'Microsoft.Workflow.Compiler.exe',
        'msbuild.exe',
        'msbuild.dll',
        'mshta.exe',
        'ntkd.exe',
        'ntsd.exe',
        'powershellcustomhost.exe',
        'rcsi.exe',
        'runscripthelper.exe',
        'texttransform.exe',
        'visualuiaverifynative.exe',
        'system.management.automation.dll',
        'webclnt.dll/davsvc.dll',
        'wfc.exe',
        'windbg.exe',
        'wmic.exe',
        'wscript.exe',
        'wsl.exe',
        'wslconfig.exe',
        'wslhost.exe'
    )

    foreach ($app in $appList) {
        $result = Get-ChildItem -Path 'C:\Windows' -Filter "*$app" -Recurse -Depth 2 -ErrorAction SilentlyContinue |
        Select-Object -First 1
        Write-Log -Message $result.FullName -Level Info -Path "C:\source\log\Copy-BypassAppsToSource.log"
        $result | Copy-Item -Destination "C:\source\bypassapps"
    }

    $apps = Get-ChildItem

    foreach ($app in $apps) {
        Start-Process $app.FullName
        Read-Host -Prompt "Enter to continue"
    }
}
