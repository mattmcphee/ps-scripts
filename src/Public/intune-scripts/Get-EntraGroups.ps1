function Get-EntraGroups {
    [CmdletBinding()]
    param (
        # ExportCsvPath
        [Parameter(Mandatory)]
        [string]
        $ExportCsvPath
    )
    
    # 2. Get all groups
    try {
        $allGroups = Get-MgGroup -All
    } catch {
        throw $_
    }
    
    # 3. Define the custom property to determine the detailed type
    $allGroups | Select-Object Id, DisplayName, Mail, MailNickname, Description, OnPremisesSyncEnabled, 
    @{
        N = 'GroupType';
        E = {
            # Start with a modifier, checking for DynamicMembership first
            $Modifier = if ($_.GroupTypes -contains 'DynamicMembership') { "Dynamic " } else { "" }
            
            # Determine the base group type
            $BaseType = ""
            
            # 1. Check for Microsoft 365 Group (which is always mail-enabled and security-enabled)
            if ($_.GroupTypes -contains 'Unified') {
                $BaseType = "Microsoft 365 (Unified)"
            }
            # 2. Check for Security Group (must be SecurityEnabled = True)
            elseif ($_.SecurityEnabled -eq $true) {
                # Is it mail-enabled too?
                if ($_.MailEnabled -eq $true) {
                    $BaseType = "Mail-Enabled Security"
                }
                # Just a standard Security Group
                else {
                    $BaseType = "Security"
                }
            }
            # 3. Fallback to Distribution List (MailEnabled = True, SecurityEnabled = False)
            elseif ($_.MailEnabled -eq $true) {
                $BaseType = "Distribution"
            }
            # 4. Final Fallback (Should be rare)
            else {
                $BaseType = "Other"
            }
    
            # Combine the modifier and the base type
            $Modifier + $BaseType
        }
    },
    @{N = 'IsSynced'; E = { $_.OnPremisesSyncEnabled -eq $true } } | 
    Export-Csv -Path $ExportCsvPath -NoTypeInformation -Force
    
    Write-Host "Export complete. Find the categorized list at $ExportCsvPath" -ForegroundColor Green
}
