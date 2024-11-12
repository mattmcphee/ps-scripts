
net stop winmgmt /y
%systemdrive%
cd %windir%\system32\wbem
for /f %%s in ('dir /b *.dll') do regsvr32 /s %%s
wmiprvse /regserver 
winmgmt /regserver 
sc config winmgmt start= auto
net start winmgmt
for /f %%s in ('dir /s /b *.mof *.mfl') do mofcomp %%s

Start-Process C:\Windows\System32\cmd.exe -ArgumentList {/c sc config winmgmt start=disabled}
Start-Process C:\Windows\System32\cmd.exe -ArgumentList {/c %systemdrive%}
Start-Process C:\Windows\System32\cmd.exe -ArgumentList {/c cd %windir%\system32\wbem}
Start-Process C:\Windows\System32\cmd.exe -ArgumentList {/c for /f %%s in ('dir /b *.dll') do regsvr32 /s %%s}
Start-Process C:\Windows\System32\cmd.exe -ArgumentList {/c wmiprvse /regserver}
Start-Process C:\Windows\System32\cmd.exe -ArgumentList {/c winmgmt /regserver}
Start-Process C:\Windows\System32\cmd.exe -ArgumentList {/c sc config winmgmt start= auto}
Start-Process C:\Windows\System32\cmd.exe -ArgumentList {/c net start winmgmt}
Start-Process C:\Windows\System32\cmd.exe -ArgumentList {/c for /f %%s in ('dir /s /b *.mof *.mfl') do mofcomp %%s}

