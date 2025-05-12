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
            Authorization = "Bearer eyJ0eXAiOiJKV1QiLCJhbGciOiJSUzI1NiIsIng1dCI6IkNOdjBPSTNSd3FsSEZFVm5hb01Bc2hDSDJYRSIsImtpZCI6IkNOdjBPSTNSd3FsSEZFVm5hb01Bc2hDSDJYRSJ9.eyJhdWQiOiJodHRwczovL3NlY3VyaXR5Y2VudGVyLm1pY3Jvc29mdC5jb20vbXRwIiwiaXNzIjoiaHR0cHM6Ly9zdHMud2luZG93cy5uZXQvOWEyYTRhZTUtOGFjMS00NjBiLTkwZjAtYmIzYzg1MTZkZjM1LyIsImlhdCI6MTc0NzAyNDgyMCwibmJmIjoxNzQ3MDI0ODIwLCJleHAiOjE3NDcwMjk1MzgsImFjciI6IjEiLCJhaW8iOiJBVFFCeS80WkFBQUFYVEZnSVpTS3BGUHhWR2VmR1Y0VDRudUZjeC9nK3ZmZWJ4TFQwQit0TzBxOUJZRVVybVNacFF0ZExYNDJtZ2JmV3FSd1JBZTVWOWVXQTNkVml1Q3dDR3Rla0wwMW1GT3ZTS2VWd2dBYVNpOWxKMGQ4clk1MHlCTEZGZy9DeXovaGhYeXlHOGhtUTMyb1p2dURQQTR3UDdKVnY0b2xHUElFck03Q0ZDaERuRjRYcjF2aklBWWo0MzhYbjBJUnJMcW9ManVnZmdWOFpRRHB1eDBVTlBieHVRbWNzR2RyOUhYdklGUHJWQmFCTUZBQkRwbE9wTFFzZFhBeERnNU85eWl1ZlVjZFB1NUhITWZFalVYaEVOVmJzQzRkZHFSZVI2ZnQ0c2hveXJTRDVYMGVNS3hlWjRFSkdBOFM2SVdHTmgvQlpzZ0RCSTgzdDB5T0dwSnVJY28vc0N2OGVhSXovcjRKYmVHeGMvVkNyc3lqT1RjRzFzM2FlM3lGRE9Mc241Y2RiTVgyNUk1U2JjTjdCU1NTaXVDZWxnPT0iLCJhbXIiOlsicHdkIiwiZmlkbyIsInJzYSIsIm1mYSJdLCJhcHBfZGlzcGxheW5hbWUiOiJNaWNyb3NvZnQgMzY1IFNlY3VyaXR5IGFuZCBDb21wbGlhbmNlIENlbnRlciIsImFwcGlkIjoiODBjY2NhNjctNTRiZC00NGFiLTg2MjUtNGI3OWM0ZGM3Nzc1IiwiYXBwaWRhY3IiOiIyIiwiZGV2aWNlaWQiOiI1ZTU3ZmI2OC1jYzgyLTRmNzgtOWIyNS1hMWVjMjk3Mzg3Y2MiLCJpZHR5cCI6InVzZXIiLCJpcGFkZHIiOiIyMDIuMTM3LjE2Mi4xMTAiLCJuYW1lIjoibWF0bWNwMS5zdS5vbmJtZCIsIm9pZCI6IjJkOTVmYTM4LWZmMTgtNDNkZS1iOWViLTAxZjM5MGM1Y2M5OSIsInB1aWQiOiIxMDAzMjAwMzRCNEM5QkVFIiwicmgiOiIxLkFXY0E1VW9xbXNHS0MwYVE4THM4aFJiZk5XVUVlUHdYSU5SQW9NVXdjQ0pIRzVKbkFBZG5BQS4iLCJzY3AiOiJ1c2VyX2ltcGVyc29uYXRpb24iLCJzaWQiOiI5ODA2OGY5Zi1mYmY4LTRiMjgtYTRlYy00NjBjM2Y2ZjkzZGIiLCJzdWIiOiJUWFhtMzQwTm1EWXNwQU42OEtCdXhhUURHTS1zQTdOdHBNV3dwRkI3RGFvIiwidGVuYW50X3JlZ2lvbl9zY29wZSI6Ik9DIiwidGlkIjoiOWEyYTRhZTUtOGFjMS00NjBiLTkwZjAtYmIzYzg1MTZkZjM1IiwidW5pcXVlX25hbWUiOiJtYXRtY3AxLnN1Lm9uYm1kQG9uYm1kLm9ubWljcm9zb2Z0LmNvbSIsInVwbiI6Im1hdG1jcDEuc3Uub25ibWRAb25ibWQub25taWNyb3NvZnQuY29tIiwidXRpIjoiZ0hTcmlsX0Ria3VlY0hOVXZqMHdBQSIsInZlciI6IjEuMCIsIndpZHMiOlsiNGE1ZDhmNjUtNDFkYS00ZGU0LTg5NjgtZTAzNWI2NTMzOWNmIiwiZjAyM2ZkODEtYTYzNy00YjU2LTk1ZmQtNzkxYWMwMjI2MDMzIiwiNWQ2YjZiYjctZGU3MS00NjIzLWI0YWYtOTYzODBhMzUyNTA5IiwiNzkwYzFmYjktN2Y3ZC00Zjg4LTg2YTEtZWYxZjk1YzA1YzFiIiwiYjc5ZmJmNGQtM2VmOS00Njg5LTgxNDMtNzZiMTk0ZTg1NTA5Il0sInhtc19pZHJlbCI6IjEgOCJ9.MFTij5Y4ApTp4I3O_OADdgOpD5i4eJvIwnX05a3J8NvWxSYWBEiXpGGrNfj8tKBTN2W1Dh2syWivLwskEj6Nj9HaklAp8atBMZQuVXoSbVAO22QnP9egpwpVcaPr3Jb0MUYdg-qWKgASLrlomARvTG6oFuVqHKDp6lxoqSkzq758SKQdTdo2PHYFO0NyEJvMoXFjopKsfumyEz0s1ABIuzxLya945RGewGIp-iiPKkdzj2ZDcTWDb5XWeJMkZvf_-oqFdzYqdIppY8dAsdH5Mjnv2Zmt8Y-NrA96iw-GQ2E3Y2lJMIsHbfia-MQwSJFAlRCMGKfYDma2PKQ4jBQxQg"
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
