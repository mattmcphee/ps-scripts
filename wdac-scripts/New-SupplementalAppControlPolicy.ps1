function New-SupplementalAppControlPolicy {
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
        $OutputXmlPath,
        # BasePolicyGUID - must be surrounded by curly braces
        [Parameter(Mandatory=$false)]
        [string]
        $BasePolicyGUID = "{488E7D72-DA1E-4219-BB58-22EEBCBB2CFE}"
    )

    # create the policy
    $arguments = @{
        ScanPath = $ScanPath
        OutputXmlPath = $OutputXmlPath
        Level = "Publisher"
        Fallback = "Hash"
    }

    New-CIPolicy @arguments

    # get xml and put it in xml type variable
    [Xml]$xml = Get-Content $OutputXmlPath
    # remove all rule options
    $xml.SiPolicy.Rules.RemoveAll()
    # change policytype to supplemental policy
    $xml.SiPolicy.PolicyType = "Supplemental Policy"
    # change base policy ID
    $xml.SiPolicy.BasePolicyID = $BasePolicyGUID
    # save the xml file
    $xml.Save($OutputXmlPath)
    # add unsigned system integrity policy rule option
    Set-RuleOption -FilePath $OutputXmlPath -Option 6

    # add info to the policy
    $todaysDate = Get-Date -Format "dd-MM-yyyy"

    $arguments = @{
        OutputXmlPath = $OutputXmlPath
        Provider = "PolicyInfo"
        ValueName = "Name"
        Value = "$FriendlyName - $todaysDate"
        Key = "Information"
        ValueType = "String"
    }

    Set-CIPolicySetting @arguments

    # convert the xml to cip
    ConvertFrom-CIPolicy -XmlFilePath $OutputXmlPath -BinaryFilePath "$OutputXmlPath.cip"
}
