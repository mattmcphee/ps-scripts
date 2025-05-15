<#
.SYNOPSIS
Input the name of an application e.g. Illustrator and this function
will output a list of machines with vulnerable software versions
along with install locations, uninstallstrings and lastloggedon
user
#>
function Get-VulnerabilitiesBySoftwareName {
    param(
        # SoftwareName
        [Parameter(Mandatory)]
        [string]
        $SoftwareName,
        # CsvPath
        [Parameter(Mandatory)]
        [string]
        $CsvPath
    )

    function Invoke-CustomQuery {
        param(
            # extra
            [Parameter(Mandatory)]
            [string]
            $ResourceUrl
        )

        $baseUrl = 'https://api-us.securitycenter.microsoft.com'
        $uri = $baseUrl + $ResourceUrl

        $headers = @{
            Authorization = ""
        }

        $res = Invoke-RestMethod `
        -Method GET `
        -Uri $uri `
        -ContentType "application/json" `
        -Headers $headers

        return $res
    }

    $res = Invoke-CustomQuery -ResourceUrl "/api/machines/SoftwareVulnerabilitiesByMachine"

    $softwareVulnInfo = $res.value |
    Where-Object { $_.id -like "*$SoftwareName*" } |
    Select-Object -Unique -CaseInsensitive -Property deviceName,deviceId,
    osPlatform,osVersion,softwareVendor,softwareName,softwareVersion,
    @{n="Disk Paths";e={$_.diskPaths -join ', '}},
    @{n="Registry Paths";e={$_.registryPaths -join ', '}} |
    Sort-Object deviceName

    foreach($item in $softwareVulnInfo) {
        $deviceId = $item.deviceId
        $res = Invoke-CustomQuery -ResourceUrl "/api/machines/$deviceId/logonusers"
        $logonUsers = $res.value | Where-Object { $_.logonTypes -like 'Interactive' }
        $item | Add-Member -MemberType NoteProperty -Name 'Logon Users' -Value ($logonUsers.accountName -join ', ')
        $item | Add-Member -MemberType NoteProperty -Name 'Last Seen' -Value ($logonUsers.lastSeen -join ', ')
    }

    $softwareVulnInfo | Export-Csv -Path $CsvPath -Force -NoTypeInformation -Append
}
