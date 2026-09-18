function Get-DeviceEntraGroups {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true, ValueFromPipeline = $true)]
        [string]$DeviceId
    )

    process {
        # 1. Look up the device in Entra ID.
        # Checks both the hardware 'deviceId' and the directory 'id' to be safe.
        $device = Get-MgDevice -Filter "deviceId eq '$DeviceId'" -ErrorAction SilentlyContinue
        if (-not $device) {
            $device = Get-MgDevice -DeviceId $DeviceId -ErrorAction SilentlyContinue
        }

        if (-not $device) {
            Write-Error "Device '$DeviceId' could not be found in Entra ID."
            return
        }

        # 2. Grab flat memberships. 
        # We explicitly ask for 'displayName' and 'groupTypes' so Graph populates them.
        $memberships = Get-MgDeviceMemberOf -DeviceId $device.Id -All -Property "id,displayName,groupTypes"

        if (-not $memberships) {
            Write-Host "The device is not a direct member of any Entra groups."
            return
        }

        # 3. Filter for groups and parse their membership styles
        $results = foreach ($member in $memberships) {
            $odataType = $member.AdditionalProperties['@odata.type']

            # Exclude other directory object types like Administrative Units
            if ($odataType -eq '#microsoft.graph.group') {
                $groupTypes = $member.AdditionalProperties['groupTypes']
                $isDynamic = $false

                if ($null -ne $groupTypes) {
                    # Safely evaluate array vs string element types from the Graph response
                    if ($groupTypes -is [System.Collections.IEnumerable] -and $groupTypes -isnot [string]) {
                        if ($groupTypes -contains 'DynamicMembership') {
                            $isDynamic = $true
                        }
                    } else {
                        if ($groupTypes.ToString() -like "*DynamicMembership*") {
                            $isDynamic = $true
                        }
                    }
                }

                $membershipType = if ($isDynamic) {
                    "Dynamic"
                } else {
                    "Static (Assigned)"
                }

                [PSCustomObject]@{
                    GroupName   = $member.AdditionalProperties['displayName']
                    GroupId     = $member.Id
                    GroupType   = $membershipType
                }
            }
        }

        return $results
    }
}
