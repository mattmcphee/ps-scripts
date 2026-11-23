function Set-IntunePrimaryUser {
    [CmdletBinding(SupportsShouldProcess)]
    param(
        # ComputerName
        [Parameter(Mandatory)]
        [string]$ComputerName,

        # PrimaryUserName
        [Parameter(Mandatory)]
        [string]$PrimaryUserName
    )

    # Get-IntuneDevice/Get-IntuneUser treat these as wildcards, which could silently match the wrong object
    foreach ($value in $ComputerName, $PrimaryUserName) {
        if ([WildcardPattern]::ContainsWildcardCharacters($value)) {
            Write-Error "Wildcard characters are not allowed: '$value'."
            return
        }
    }

    try {
        $intuneDevice = @(Get-IntuneDevice -DeviceName $ComputerName)

        if ($intuneDevice.Count -lt 1) {
            Write-Warning "Could not find device with name '$ComputerName'."
            return
        } elseif ($intuneDevice.Count -gt 1) {
            Write-Warning "Found more than 1 device when searching for '$ComputerName'. Skipping..."
            return
        }

        $deviceId = $intuneDevice[0].ID

        $user = @(Get-IntuneUser -UserPrincipalName $PrimaryUserName)

        if ($user.Count -lt 1) {
            Write-Warning "Could not find user with name '$PrimaryUserName'."
            return
        } elseif ($user.Count -gt 1) {
            Write-Warning "Found more than 1 user when searching for '$PrimaryUserName'. Skipping..."
            return
        }

        $userId = $user[0].id

        # Primary user is only exposed on the beta endpoint
        $usersUri = "https://graph.microsoft.com/beta/deviceManagement/managedDevices/$deviceId/users"
        $previousUser = @((Invoke-MgGraphRequest -Method GET -Uri $usersUri -ErrorAction Stop).value)[0].userPrincipalName

        $action = "Set primary user to '$($user[0].userPrincipalName)' (current: '$previousUser')"
        if (-not $PSCmdlet.ShouldProcess($intuneDevice[0].DeviceName, $action)) {
            return
        }

        $uri = "$usersUri/`$ref"
        $body = @{ '@odata.id' = "https://graph.microsoft.com/beta/users/$userId" }

        Invoke-MgGraphRequest -Method POST -Uri $uri -Body $body -ErrorAction Stop | Out-Null

        [PSCustomObject]@{
            ComputerName      = $intuneDevice[0].DeviceName
            DeviceId          = $deviceId
            PreviousUser      = $previousUser
            NewPrimaryUser    = $user.userPrincipalName
            Status            = 'Primary user updated'
        }
    } catch {
        Write-Error "Failed to set primary user on ${ComputerName}: $($_.Exception.Message)"
    }
}
