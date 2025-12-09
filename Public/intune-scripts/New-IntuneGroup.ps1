function New-IntuneGroup {
    param (
        # DisplayName
        [Parameter(Mandatory)]
        [string]
        $DisplayName,
        # MailNickname
        [Parameter(Mandatory)]
        [string]
        $MailNickname,
        # Description
        [Parameter(Mandatory=$false)]
        [string]
        $Description,
        # MailEnabled
        [Parameter()]
        [switch]
        $MailEnabled,
        # SecurityEnabled
        [Parameter()]
        [switch]
        $SecurityEnabled,
        # Visibility
        [ValidateSetAttribute("Private","Public","HiddenMembership")]
        [Parameter(Mandatory)]
        [string]
        $Visibility
    )

    # test vars
    $DisplayName = "test group"
    $MailNickname = "testgroup"
    $MailEnabled = $false
    $SecurityEnabled = $true
    $Description = "This is a test group."
    $Visibility = "Private"

    $groupParams = @{
        displayName = $DisplayName
        mailNickname = $MailNickname
        visibility = $Visibility
    }

    # ternary operators to check if switch is on
    $groupParams.mailEnabled = $MailEnabled ? $true : $false
    $groupParams.securityEnabled = $SecurityEnabled ? $true : $false
    $groupParams.description = $Description ? $Description : ""

    New-MgGroup -BodyParameter $groupParams
}
