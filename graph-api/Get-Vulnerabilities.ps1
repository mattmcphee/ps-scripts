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
            Authorization = "Bearer eyJ0eXAiOiJKV1QiLCJhbGciOiJSUzI1NiIsIng1dCI6IkNOdjBPSTNSd3FsSEZFVm5hb01Bc2hDSDJYRSIsImtpZCI6IkNOdjBPSTNSd3FsSEZFVm5hb01Bc2hDSDJYRSJ9.eyJhdWQiOiJodHRwczovL3NlY3VyaXR5Y2VudGVyLm1pY3Jvc29mdC5jb20vbXRwIiwiaXNzIjoiaHR0cHM6Ly9zdHMud2luZG93cy5uZXQvOWEyYTRhZTUtOGFjMS00NjBiLTkwZjAtYmIzYzg1MTZkZjM1LyIsImlhdCI6MTc0Nzg4NDExMSwibmJmIjoxNzQ3ODg0MTExLCJleHAiOjE3NDc4ODg1ODQsImFjciI6IjEiLCJhaW8iOiJBV1FCbS80WkFBQUFqR0tlZlZJRkpOMWlCVmRHQnQxcllOcHFvaHVLUjdBdUdZOXNnNko4ay9TOWRzVUhEV1hEZGsvMXlLK0tGaHlqSGtJZ1kzM1UraXRkcFd5Qk4zMXJreGNSR2VjM3pjck1rOHBFbkZEanBOZUFFNFJFMWwzTDh6Z1I4Y1pKbEJya1pHWGc0UXBxejdWaFR6ZnQ0ajltMVVTbFArcDloODducmpUcFZETUVxeWx3Mi9FdWRZYnkyRjVsSnU4Ymk2TUdRTk5nV3FzQXYrMWV6aEx2a3VEeWJoR3hpa3BNSEhkbXdSNThKcVlUb0RLSXlFRHJtTUs4VnlXT0NQdUxEajNHcTBoTTU3R1JnWVdkNy9LUkNrSHkzSitBRSt3VkNJcDZoaWdoYVYzQ0w4MzRMNUZIV3g3dk5uNkYzVmJDSTJyRm5mRzU4Y1IrU1Y5V1B4azZwQkJXaGZqa2o1ckZtaDdUcmtmSzBUc1hJdzhTWnE3d3BFdmhYa1pseWswWlk1RnV5b1dURkJObi9ScXFhR0V5S2NjQlhkRUxBak8xSFlUTnB4NXU5aE1oSHhlWTBWbG5zZytiRVh3RGZTblZjZGVSZy9TR21qVGRxM1owTUkvWXcvUU9IQT09IiwiYW1yIjpbInB3ZCIsImZpZG8iLCJyc2EiLCJtZmEiXSwiYXBwX2Rpc3BsYXluYW1lIjoiTWljcm9zb2Z0IDM2NSBTZWN1cml0eSBhbmQgQ29tcGxpYW5jZSBDZW50ZXIiLCJhcHBpZCI6IjgwY2NjYTY3LTU0YmQtNDRhYi04NjI1LTRiNzljNGRjNzc3NSIsImFwcGlkYWNyIjoiMiIsImRldmljZWlkIjoiNWU1N2ZiNjgtY2M4Mi00Zjc4LTliMjUtYTFlYzI5NzM4N2NjIiwiaWR0eXAiOiJ1c2VyIiwiaXBhZGRyIjoiMjAyLjEzNy4xNjIuMTEwIiwibmFtZSI6Im1hdG1jcDEuc3Uub25ibWQiLCJvaWQiOiIyZDk1ZmEzOC1mZjE4LTQzZGUtYjllYi0wMWYzOTBjNWNjOTkiLCJwdWlkIjoiMTAwMzIwMDM0QjRDOUJFRSIsInJoIjoiMS5BV2NBNVVvcW1zR0tDMGFROExzOGhSYmZOV1VFZVB3WElOUkFvTVV3Y0NKSEc1Sm5BQWRuQUEuIiwic2NwIjoidXNlcl9pbXBlcnNvbmF0aW9uIiwic2lkIjoiOTgwNjhmOWYtZmJmOC00YjI4LWE0ZWMtNDYwYzNmNmY5M2RiIiwic3ViIjoiVFhYbTM0ME5tRFlzcEFONjhLQnV4YVFER00tc0E3TnRwTVd3cEZCN0RhbyIsInRlbmFudF9yZWdpb25fc2NvcGUiOiJPQyIsInRpZCI6IjlhMmE0YWU1LThhYzEtNDYwYi05MGYwLWJiM2M4NTE2ZGYzNSIsInVuaXF1ZV9uYW1lIjoibWF0bWNwMS5zdS5vbmJtZEBvbmJtZC5vbm1pY3Jvc29mdC5jb20iLCJ1cG4iOiJtYXRtY3AxLnN1Lm9uYm1kQG9uYm1kLm9ubWljcm9zb2Z0LmNvbSIsInV0aSI6ImFJc0ZnbUk0bjA2TWtCSklOV0ttQUEiLCJ2ZXIiOiIxLjAiLCJ3aWRzIjpbIjRhNWQ4ZjY1LTQxZGEtNGRlNC04OTY4LWUwMzViNjUzMzljZiIsImYwMjNmZDgxLWE2MzctNGI1Ni05NWZkLTc5MWFjMDIyNjAzMyIsIjVkNmI2YmI3LWRlNzEtNDYyMy1iNGFmLTk2MzgwYTM1MjUwOSIsIjc5MGMxZmI5LTdmN2QtNGY4OC04NmExLWVmMWY5NWMwNWMxYiIsImI3OWZiZjRkLTNlZjktNDY4OS04MTQzLTc2YjE5NGU4NTUwOSJdLCJ4bXNfZnRkIjoiVWpnZUhtV2lKdVNkOTFVbUlPTEZDYnE5V3BERDNZNlh0N2d0cnRaNlhCRUJZWFZ6ZEhKaGJHbGhaV0Z6ZEMxa2MyMXoiLCJ4bXNfaWRyZWwiOiIxIDI0In0.ZPuRocITR-98bq-LbMotwi0LD1SwyAnpZcT6tU5y9POqSizwucYAmjnYPUtEOU3fZ7qLgwnd_8ODWcz04fNd6zqX1QUK5hsTQid7JM7k4AKPCLcDiUk29r86NXCnhJUi1HuqovXCbu8duNMTqBSzD9i6bww6zb_RcLwr-ISq4EBxvctX00q5H8mW4CseCRplo2qnGU5ufvT1UdnWisZ0PwGYiB_JExMzefO07cDKKgbY-975ANBnWJvE11-7K9ibIduxGQboW7tHL_29TPZrfDHFYCCtJgZu5KAUt3m9OS2okUc-7nbkCvG3rhmVPQN97XpM-w00505Qe526Fug01w"
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
