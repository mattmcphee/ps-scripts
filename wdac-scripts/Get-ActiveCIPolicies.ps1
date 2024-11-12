function Get-ActiveCIPolicies {
    param (
        # ComputerName
        [Parameter(Mandatory=$false)]
        [string]
        $ComputerName = $env:COMPUTERNAME,
        # only show policies being enforced
        [Parameter(Mandatory=$false)]
        [switch]
        $EnforcedOnly
    )
    if ($EnforcedOnly) {
        Invoke-Command -ComputerName $ComputerName -ScriptBlock {
            (citool --list-policies -json | ConvertFrom-Json).Policies |
            Where-Object {$_.IsEnforced -eq "True"} |
            Select-Object PolicyID,BasePolicyID,FriendlyName, `
                IsSystemPolicy,IsOnDisk,IsEnforced,IsAuthorized
        }
    } else {
        Invoke-Command -ComputerName $ComputerName -ScriptBlock {
            (citool --list-policies -json | ConvertFrom-Json).Policies |
            Select-Object PolicyID,BasePolicyID,FriendlyName, `
                IsSystemPolicy,IsOnDisk,IsEnforced,IsAuthorized
        }
    }
}