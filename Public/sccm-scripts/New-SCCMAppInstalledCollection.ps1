function New-SCCMAppInstalledCollection {
    [CmdletBinding()]
    param (
        # AppString - the string the query will use
        # make sure you include the % wildcard
        # % at the start is slow, % at the end is fast
        [Parameter(Mandatory)]
        [ValidateNotNullOrEmpty()]
        [string]
        $AppString,
        # CollectionName - the name of the collection to be created
        # must be in the format '<application> Installed'
        [Parameter(Mandatory)]
        [ValidateNotNullOrEmpty()]
        [string]
        $CollectionName
    )

    # schedule collection update to happen between 1am and 2am every 7 days
    try {
        $schedule = New-CMSchedule -Start (Get-Date -Hour 1) `
            -RecurInterval Days `
            -RecurCount 7
        
        Write-Host "Creating collection: '$CollectionName'..."
        $null = New-CMDeviceCollection -Name $CollectionName `
            -LimitingCollectionName "All Windows 10 and higher" `
            -RefreshSchedule $schedule `
            -RefreshType Periodic `
            -Comment "All devices with $CollectionName" `
            -ErrorAction Stop
        Write-Host "Success!" -ForegroundColor Green

        $sb = New-Object -TypeName System.Text.StringBuilder
        $null = $sb.Append("select SMS_R_SYSTEM.ResourceID,SMS_R_SYSTEM.Name ")
        $null = $sb.Append("from SMS_R_System inner join SMS_G_System_INSTALLED_SOFTWARE ")
        $null = $sb.Append("on SMS_G_System_INSTALLED_SOFTWARE.ResourceId = SMS_R_System.ResourceId ")
        # {0} these three chars get replaced by whatever's in $AppString
        $null = $sb.AppendFormat('where SMS_G_System_INSTALLED_SOFTWARE.ARPDisplayName like "{0}"', $AppString)
        $query = $sb.ToString()

        Write-Host "Adding wql query to collection..."
        Add-CMDeviceCollectionQueryMembershipRule -CollectionName $CollectionName `
            -RuleName $CollectionName `
            -QueryExpression $query `
            -ErrorAction Stop
        Write-Host "Success!" -ForegroundColor Green

        Write-Host "Moving collection to Software Installed folder..."
        $coll = Get-CMCollection -Name $CollectionName
        $coll | Move-CMObject -FolderPath 'A00:\DeviceCollection\Software Installed'
        Write-Host "Success!" -ForegroundColor Green
        
        Write-Host "Add this change to the changes spreadsheet :^)" -ForegroundColor Green
    } catch {
        throw $_
    }
}
