function Get-GPOFromADGroupName {
    param (
        # GroupName
        [Parameter(Mandatory = $true)]
        [string]
        $GroupName
    )
    
    try {
        # Get the actual group name
        $actualGroupName = (Get-ADGroup -Filter { Name -like $GroupName }).Name
        if ($actualGroupName.Count -lt 1) {
            throw "Could not find AD group with name: $GroupName"
        }
        if ($actualGroupName.Count -gt 1) {
            throw "Found more than one group name. Be more specific."
        }

        # Find all GPOs in the Domain
        $allGPOs = Get-GPO -All

        # Loop through each GPO and check its security filtering
        foreach ($GPO in $allGPOs) {
            # Get the security filtering settings for the current GPO
            $GPOPermissions = Get-GPPermission -Guid $GPO.Id -All

            # Check if the group is listed in the security permissions
            if ($GPOPermissions.Trustee.Name -contains $actualGroupName) {
                Write-Host "Found GPO: $($GPO.DisplayName)"
                Write-Host "It is linked to:"
        
                # Find the OUs the GPO is linked to
                Get-GPO -Guid $GPO.Id | Get-GPOReport -ReportType Xml | ConvertTo-Xml | Select-String '<LinksFrom>'
            }
        }
    } catch {
        throw $_
    }
}
