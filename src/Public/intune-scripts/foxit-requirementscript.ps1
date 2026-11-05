# in a 32-bit process HKLM\Software reads are redirected to WOW6432Node - exit with no output (not applicable)
if ([IntPtr]::Size -eq 4) {
    exit 0
}

$appName = 'Foxit PDF Editor'
$targetVersion = '2026.2.1.39815'
$uninstallPath = 'HKLM:\software\microsoft\windows\currentversion\uninstall\*'
$foxitRegistryPath = 'registry::HKEY_LOCAL_MACHINE\SOFTWARE\Foxit Software\Foxit PDF Editor'
$expectedFoxitGuid = '{ca7b7bf5-754e-11f0-b87b-54bf64a63c26}'
$versionPattern = '\d+(?:[-_.]\d+){0,3}'

function Write-RequirementLog {
    param(
        $Hive,
        $Found,
        $Message
    )

    $logFileName = 'PatchMyPC-SoftwareUpdateDetectionScript.log'

    if ($env:USERNAME -eq "${env:COMPUTERNAME}$") {
        $logDirectory = New-Item -Path "$env:ProgramData\PatchMyPCIntuneLogs" -ItemType Directory -Force -ErrorAction SilentlyContinue
        $logPath = "$logDirectory\$logFileName"
    } else {
        $logPath = "$env:TEMP\$logFileName"
    }

    # roll the log over once it reaches 5MB
    $logFile = Get-Item -Path $logPath -ErrorAction SilentlyContinue
    if ($logFile.Length -ge 5MB) {
        $archivedLogPath = $logFile.FullName.Replace('.log', '.lo_')
        Remove-Item -Path $archivedLogPath -Force -ErrorAction SilentlyContinue
        Rename-Item -Path $logFile -NewName $archivedLogPath
    }

    "$(Get-Date)~[$Message]~[Found:$Found]~[Purpose:Requirement]~[Context:$env:USERNAME)]~[Hive:$Hive]" |
        Out-File -FilePath $logPath -Append -Force
}

function ConvertTo-NormalizedVersion {
    param(
        [string]$VersionString
    )

    try {
        # pad to four parts so [version] parses e.g. '2026' or '2026.2'
        $dotCount = $VersionString.ToCharArray().Where({ $_ -eq '.' }).Count
        [version]($VersionString + '.0' * [Math]::Max(0, 3 - $dotCount))
    } catch {
        # fall back to splitting on any separator - non-numeric parts sort highest
        $versionParts = foreach ($part in $VersionString.Split([char[]]('.', '-', '_'))) {
            try {
                [int]$part
            } catch {
                [int]::MaxValue
            }
        }
        try {
            ConvertTo-NormalizedVersion ($versionParts -join '.')
        } catch {
            [version]'0.0.0.0'
        }
    }
}

try {
    # only applicable to the Foxit install identified by this GUID - skip the uninstall scan otherwise
    $foxitGuid = (Get-ItemProperty -Path $foxitRegistryPath -Name 'GUID' -ErrorAction SilentlyContinue).GUID

    if ($foxitGuid -eq $expectedFoxitGuid) {
        $minimumVersion = ConvertTo-NormalizedVersion $targetVersion

        $foxitInstalls = Get-ItemProperty -Path $uninstallPath -Name 'DisplayName', 'DisplayVersion' -ErrorAction SilentlyContinue |
            Where-Object { $_.DisplayName -eq $appName -and $null -ne ($_.PSChildName -as [guid]) }

        foreach ($install in $foxitInstalls) {
            $installedVersion = [regex]::Match($install.DisplayVersion, $versionPattern).Value

            if ($installedVersion -like '202*' -and (ConvertTo-NormalizedVersion $installedVersion) -lt $minimumVersion) {
                Write-RequirementLog $uninstallPath $true "$($install.DisplayName) $targetVersion"
                return 'Applicable'
            }
        }
    }

    Write-RequirementLog $uninstallPath $false "$appName $targetVersion"
} catch {
    Write-RequirementLog '' '' $_.Exception.Message
}