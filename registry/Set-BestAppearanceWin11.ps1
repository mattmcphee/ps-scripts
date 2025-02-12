function Set-BestAppearanceWin11 {
    param (
        # ComputerName
        [Parameter(Mandatory=$true)]
        [string]
        $ComputerName
    )

    Invoke-Command -ComputerName $ComputerName -ScriptBlock {
        New-PSDrive -PSProvider Registry -Name HKU -Root HKEY_USERS

        $themePath = 'HKU:\S-1-5-21-36468863-1111239545-1232828436-70408\Software\Microsoft\Windows\CurrentVersion\Themes\Personalize'
        $explorerPath = 'HKU:\S-1-5-21-36468863-1111239545-1232828436-70408\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced'
        $searchPath = 'HKU:\S-1-5-21-36468863-1111239545-1232828436-70408\Software\Microsoft\Windows\CurrentVersion\Search'

        Set-ItemProperty -Path $themePath -Name AppsUseLightTheme -Value 0
        Set-ItemProperty -Path $themePath -Name SystemUsesLightTheme -Value 0

        Set-ItemProperty -Path $explorerPath -Name DontPrettyPath -Value 1
        Set-ItemProperty -Path $explorerPath -Name ShowTaskViewButton -Value 0
        Set-ItemProperty -Path $explorerPath -Name TaskbarAl -Value 0
        Set-ItemProperty -Path $explorerPath -Name TaskGlomLevel -Value 2
        Set-ItemProperty -Path $explorerPath -Name TaskbarSn -Value 0
        Set-ItemProperty -Path $explorerPath -Name TaskbarSd -Value 0
        Set-ItemProperty -Path $explorerPath -Name SearchboxTaskbarMode -Value 0
        Set-ItemProperty -Path $explorerPath -Name Start_Layout -Value 1

        Set-ItemProperty -Path $searchPath -Name SearchboxTaskbarMode -Value 0
    }
}
