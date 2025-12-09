function Get-CCMCacheSize {
    param(
        # ComputerName
        [Parameter(Mandatory=$false)]
        [string]
        $ComputerName = ($env:ComputerName)
    )
    Invoke-Command -ComputerName $ComputerName (New-Object -ComObject UIResource.UIResourceMgr).GetCacheInfo().TotalSize = 100000
}
