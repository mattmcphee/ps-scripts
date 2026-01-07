function New-IntuneApp {
    [CmdletBinding()]
    param (
        # SourcePath - path to the main installer exe
        [Parameter(Mandatory)]
        [ValidateScript({
            if (-not (Test-Path -Path $_ -PathType Leaf)) {
                throw "$_ could not be found or is not a path to a file."
            } elseif ($_ -notlike "*.exe") {
                throw "The file '$_' must have an .exe extension."
            } else {
                return $true
            }
        })]
        [string]$SourcePath,

        # DisplayName - desired displayname for the application in company portal
        [Parameter(Mandatory)]
        [string]$DisplayName,

        # Publisher - publisher of the application
        [Parameter(Mandatory)]
        [string]$Publisher,

        # Description - description that appears in company portal
        [Parameter(Mandatory)]
        [string]$Description,

        # ApplicationExePath - path to main exe on the client machine (will be used for detection)
        [Parameter(Mandatory)]
        [string]$ApplicationExePath,

        # RegKeyPath - registry path that holds displayversion value name on the client machine (will be used for detection)
        [Parameter(Mandatory)]
        [string]$RegKeyPath,

        # DisplayVersion - the version value that appears in the registry on the client machine (will be used for detection)
        [Parameter(Mandatory)]
        [string]$DisplayVersion,

        # IconPath - path to icon image file
        [Parameter(Mandatory)]
        [ValidateScript({
            if (-not (Test-Path -Path $_ -PathType Leaf)) {
                throw "$_ not found or is a folder instead of a file."
            } elseif ($_ -notlike "*.png" -and $_ -notlike "*.jpg") {
                throw "$_ is not a valid image file path ending in png or jpg."
            } else {
                return $true
            }
        })]
        [string]$IconPath,

        # AppVersion - version that appears in company portal (optional, defaults to registry version)
        [Parameter(Mandatory = $false)]
        [string]$AppVersion = $DisplayVersion,

        # Developer - author of the application (appears in company portal, optional, defaults to publisher)
        [Parameter(Mandatory = $false)]
        [string]$Developer = $Publisher,

        # Owner - product owner of the application within the organization (optional, defaults to empty string)
        [Parameter(Mandatory = $false)]
        [string]$Owner = [string]::Empty,

        # Notes - optional, defaults to empty string
        [Parameter(Mandatory = $false)]
        [string]$Notes = [string]::Empty,

        # InformationURL - link to a knowledge base item with further info (optional, defaults to empty string)
        [Parameter(Mandatory = $false)]
        [string]$InformationURL = [string]::Empty,

        # PrivacyURL - link to the app's privacy policy (optional, defaults to empty string)
        [Parameter(Mandatory = $false)]
        [string]$PrivacyURL = [string]::Empty,

        # CompanyPortalFeaturedApp - whether to feature the app in company portal (optional, defaults to false)
        [Parameter(Mandatory = $false)]
        [bool]$CompanyPortalFeaturedApp = $false,

        # CategoryName - specify a single or multiple categories categorize the app (optional, defaults to empty string)
        [Parameter(Mandatory = $false)]
        [string[]]$CategoryName = [string]::Empty,
        
        # RestartBehavior - restart behavior if app requires restart (optional, defaults to suppress)
        [Parameter(Mandatory = $false)]
        [ValidateSet("allow", "basedOnReturnCode", "suppress", "force")]
        [string]$RestartBehavior = "suppress",

        # InstallExperience - install as system or user (optional, default SYSTEM)
        [Parameter(Mandatory = $false)]
        [ValidateSet("SYSTEM", "User")]
        [string]$InstallExperience = "SYSTEM",

        # InstallCommandLine - install command line (optional, defaults to psadt install)
        [Parameter(Mandatory = $false)]
        [string]$InstallCommandLine = ($SourcePath | Split-Path -Leaf) + " -DeploymentType Install",

        # UninstallCommandLine - uninstall command line (optional, defaults to psadt uninstall)
        [Parameter(Mandatory = $false)]
        [string]$UninstallCommandLine = ($SourcePath | Split-Path -Leaf) + " -DeploymentType Uninstall"
    )

    # Authenticate to Microsoft Graph (edit these for the appropriate tenant and appreg)
    Connect-MSIntuneGraph -TenantID "cab2b5b9-c306-4307-a8ae-402a7693c71e" -ClientID "215826c0-87c0-4e1a-8a8a-7d85fc395b0f"

    # Package as .intunewin file
    $sourceFolder = $SourcePath | Split-Path -Parent
    $setupFile = $SourcePath | Split-Path -Leaf
    $outputFolder = ($SourcePath | Split-Path -Parent) + " Output"
    $win32AppPackage = New-IntuneWin32AppPackage -SourceFolder $sourceFolder -SetupFile $setupFile -OutputFolder $outputFolder -Force

    # Create requirement rule for Intel/AMD platforms and Windows 10 20H2
    $reqRule = New-IntuneWin32AppRequirementRule -Architecture "x64" -MinimumSupportedWindowsRelease "W10_20H2"

    # Create exe file detection rule - checking for file's existence
    $appExeFolder = $ApplicationExePath | Split-Path -Parent
    $appExe = $ApplicationExePath | Split-Path -Leaf

    $detRuleExe = New-IntuneWin32AppDetectionRuleFile `
    -Existence `
    -Path $appExeFolder `
    -FileOrFolder $appExe `
    -DetectionType "exists"

    # Create registry version detection rule
    $detRuleReg = New-IntuneWin32AppDetectionRuleRegistry `
    -VersionComparison `
    -KeyPath $RegKeyPath `
    -ValueName "DisplayVersion" `
    -VersionComparisonOperator "greaterThanOrEqual" `
    -VersionComparisonValue $DisplayVersion

    # Convert image file to icon
    $icon = New-IntuneWin32AppIcon -FilePath $IconPath

    # Add new MSI Win32 app
    $win32App = Add-IntuneWin32App `
    -FilePath $win32AppPackage.Path `
    -DisplayName $DisplayName `
    -Description $Description `
    -Publisher $Publisher `
    -InstallExperience $InstallExperience `
    -InstallCommandLine $InstallCommandLine `
    -UninstallCommandLine $UninstallCommandLine `
    -RestartBehavior suppress `
    -DetectionRule $detRuleExe, $detRuleReg `
    -RequirementRule $reqRule `
    -AllowAvailableUninstall `
    -Icon $icon `
    -ScopeTagName "Endpoint Team-au_it_level_2_sccm_access_usg", "Dept-001-H07-Corporate-IT", "OU-au_computers_sccm_2012" `
    -UseAzCopy

    # Add assignment for all devices (this can be changed to a group assignment)
    Add-IntuneWin32AppAssignmentAllDevices `
    -ID $win32App.id`
    -Intent available `
    -Notification showAll `
    -DeliveryOptimizationPriority foreground
}
