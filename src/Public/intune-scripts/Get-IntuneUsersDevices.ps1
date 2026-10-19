function Get-IntuneUsersDevices {
    [CmdletBinding()]
    param (
        # UserName
        [Parameter(Mandatory)]
        [string]$UserName
    )

    # retrieve user
    $baseUri = 'https://graph.microsoft.com/v1.0'

    $property = if ($UserName -match '@') {
        'userPrincipalName'
    } else {
        'displayName'
    }

    $value = $UserName.TrimEnd('*').Replace("'", "''")

    if ($UserName.EndsWith('*')) {
        $filter = "startswith($property, '$value')"
    } else {
        $filter = "$property eq '$value'"
    }

    $uri = "$baseUri/users?`$filter=$([uri]::EscapeDataString($filter))&`$select=id,displayName,userPrincipalName"

    $response = Invoke-MgGraphRequest -Method GET -Uri $uri

    $users = $response.value

    if ($users.Count -lt 1) {
        Write-Warning "User '$UserName' not found."
        return
    }

    # retrieve devices associated with user
    foreach ($user in $users) {
        $uri = "$baseUri/users/$($user.id)/managedDevices?`$select=id,deviceName,lastSyncDateTime,operatingSystem,osVersion,complianceState,azureADDeviceId"

        while ($uri) {
            try {
                $response = Invoke-MgGraphRequest -Method GET -Uri $uri
            } catch {
                $statusCode = $_.Exception.Response.StatusCode
                if ($statusCode -eq [Net.HttpStatusCode]::NotFound) {
                    Write-Warning "Managed devices not found for user '$($user.displayName)' ($($user.id))."
                    break
                }
            }

            foreach ($device in $response.value) {
                [PSCustomObject]@{
                    UserName        = $User.displayName
                    DeviceName      = $Device.deviceName
                    OperatingSystem = $Device.operatingSystem
                    OSVersion       = $Device.osVersion
                    ComplianceState = $Device.complianceState
                    LastSync        = $Device.lastSyncDateTime
                    IntuneDeviceId  = $Device.id
                    EntraDeviceId   = $Device.azureADDeviceId
                }
            }

            $uri = $response.'@odata.nextLink'
        }
    }
}
