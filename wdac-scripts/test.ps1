[Xml]$xml = Get-Content "C:\sources\Supplemental-EpicGamesLauncher-1570-V01.xml"
$settingsElement = $xml.CreateElement('Settings')