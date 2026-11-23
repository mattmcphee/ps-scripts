function Get-IntuneGroupMembership {
    [CmdletBinding()]
    param(
        # Id - Entra user object id or Intune managed device id
        [Parameter(Mandatory)]
        [guid]$Id,

        # ShowNesting - output a tree of the groups each group is nested in
        [Parameter(Mandatory=$false)]
        [switch]$ShowNesting
    )

    $baseUri = 'https://graph.microsoft.com/v1.0'

    # Returns every item in a Graph collection, following paging links
    function Get-GraphCollection([string]$Uri) {
        while ($Uri) {
            $response = Invoke-MgGraphRequest -Method GET -Uri $Uri -ErrorAction Stop
            $response.value
            $Uri = $response.'@odata.nextLink'
        }
    }

    # The microsoft.graph.group cast excludes directory roles and administrative units
    function Get-DirectGroups([string]$ObjectPath) {
        Get-GraphCollection "$baseUri/$ObjectPath/memberOf/microsoft.graph.group?`$select=id,displayName" |
            Sort-Object { $_.displayName }
    }

    try {
        $object = Invoke-MgGraphRequest -Method GET -ErrorAction Stop `
            -Uri "$baseUri/users/$Id`?`$select=id,displayName"
    } catch {
        # Not found just means the id isn't a user; anything else (auth, throttling) is a real failure
        if ("$_" -notmatch 'Request_ResourceNotFound') { throw }
        $object = $null
    }
    $collection = 'users'
    $objectLabel = 'user'

    if (-not $object) {
        try {
            $managedDevice = Invoke-MgGraphRequest -Method GET -ErrorAction Stop `
                -Uri "$baseUri/deviceManagement/managedDevices/$Id`?`$select=id,deviceName,azureADDeviceId"
        } catch {
            Write-Warning "Could not find an Entra user or Intune device with id '$Id'. $_"
            return
        }

        # Group membership belongs to the Entra device object, linked via its deviceId property
        $entraDeviceId = $managedDevice.azureADDeviceId
        if (-not $entraDeviceId -or $entraDeviceId -eq [guid]::Empty) {
            Write-Warning "Intune device '$($managedDevice.deviceName)' has no linked Entra device."
            return
        }

        $object = @(Get-GraphCollection "$baseUri/devices?`$filter=deviceId eq '$entraDeviceId'&`$select=id,displayName")[0]
        $collection = 'devices'
        $objectLabel = 'device'

        if (-not $object) {
            Write-Warning "Could not find Entra device '$entraDeviceId' for Intune device '$($managedDevice.deviceName)'."
            return
        }
    }

    $directGroups = @(Get-DirectGroups "$collection/$($object.id)")

    if (-not $ShowNesting) {
        foreach ($group in $directGroups) {
            [PSCustomObject]@{
                GroupName = $group.displayName
                GroupId   = $group.id
            }
        }
        return
    }

    # Groups can appear on several branches; only query each group's parents once
    $parentCache = @{}

    # Emits a line per group, then recurses into the groups that group is nested in
    function Format-GroupTree([object[]]$Groups, [string]$Indent, [string[]]$Path) {
        for ($i = 0; $i -lt $Groups.Count; $i++) {
            $group = $Groups[$i]
            $isLast = $i -eq ($Groups.Count - 1)
            $line = $Indent + $(if ($isLast) { '\-- ' } else { '|-- ' }) + $group.displayName

            if ($group.id -in $Path) {
                "$line (circular nesting)"
                continue
            }

            $line

            if (-not $parentCache.ContainsKey($group.id)) {
                $parentCache[$group.id] = @(Get-DirectGroups "groups/$($group.id)")
            }

            $childIndent = $Indent + $(if ($isLast) { '    ' } else { '|   ' })
            Format-GroupTree -Groups $parentCache[$group.id] -Indent $childIndent -Path ($Path + $group.id)
        }
    }

    "$($object.displayName) ($objectLabel)"
    Format-GroupTree -Groups $directGroups -Indent '' -Path @()
}
