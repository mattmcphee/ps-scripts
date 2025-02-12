function New-SuppAppControlPolicy {
    param (
        # FriendlyName
        [Parameter(Mandatory=$true)]
        [string]
        $FriendlyName,
        # ScanPath
        [Parameter(Mandatory=$true)]
        [string]
        $ScanPath,
        # Desired output location of the policy xml file
        [Parameter(Mandatory=$true)]
        [string]
        $FilePath,
        # BasePolicyGUID - must be surrounded by curly braces
        [Parameter(Mandatory=$false)]
        [string]
        $BasePolicyGUID = "{488E7D72-DA1E-4219-BB58-22EEBCBB2CFE}"
    )
    # create the policy
    $arguments = @{
        ScanPath = $ScanPath
        FilePath = $FilePath
        Level = "WHQLFilePublisher"
        Fallback = "FilePublisher","Publisher","Hash"
        NoShadowCopy = $true
        UserPEs = $true
        UserWriteablePaths = $true
        MultiplePolicyFormat = $true
    }
    New-CIPolicy @arguments

    # get xml and put it in xml type variable
    [Xml]$xml = Get-Content $FilePath
    # remove all rule options
    $xml.SiPolicy.Rules.RemoveAll()
    # change policytype from base policy to supplemental policy
    $xml.SiPolicy.PolicyType = "Supplemental Policy"
    # change base policy ID
    $xml.SiPolicy.BasePolicyID = $BasePolicyGUID
    # save the xml file
    $xml.Save($FilePath)
    # add unsigned system integrity policy rule option
    Set-RuleOption -FilePath $FilePath -Option 6
    # add friendly name policy setting to the policy
    $todaysDate = Get-Date -Format "dd-MM-yyyy"
    $arguments = @{
        FilePath = $FilePath
        Provider = "PolicyInfo"
        ValueName = "Name"
        Value = "$FriendlyName - $todaysDate"
        Key = "Information"
        ValueType = "String"
    }
    Set-CIPolicySetting @arguments
}
