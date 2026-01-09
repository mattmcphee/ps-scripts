<#
.SYNOPSIS
    Creates a new Win32 application in Microsoft Intune.

.DESCRIPTION
    This function packages an application installer as a .intunewin file and uploads it to Microsoft Intune as a Win32 app.
    It creates detection rules based on file existence and registry version, sets requirement rules for x64 architecture
    and Windows 10 20H2 or later, and configures the application with metadata like display name, publisher, description,
    icon, and installation behavior.

.PARAMETER SourcePath
    The file path to the main installer executable (.exe file). This file will be packaged into a .intunewin file.

.PARAMETER DisplayName
    The display name for the application as it will appear in the Company Portal.

.PARAMETER Publisher
    The publisher name of the application.

.PARAMETER Description
    The description of the application that will appear in the Company Portal.

.PARAMETER ApplicationExePath
    The full path to the main executable on the client machine. Used for file-based detection rule.

.PARAMETER RegKeyPath
    The registry key path that contains the DisplayVersion value on the client machine. Used for registry-based detection rule.

.PARAMETER DisplayVersion
    The application version value from the registry on the client machine. Used for version comparison in detection rules.

.PARAMETER IconPath
    The file path to the application icon image (.png or .jpg file).

.PARAMETER AppVersion
    The application version that will appear in the Company Portal. Defaults to the DisplayVersion parameter value.

.PARAMETER Developer
    The developer/author of the application that appears in the Company Portal. Defaults to the Publisher parameter value.

.PARAMETER Owner
    The product owner of the application within the organization. Defaults to an empty string.

.PARAMETER Notes
    Additional notes about the application. Defaults to an empty string.

.PARAMETER InformationURL
    A URL link to a knowledge base or information page about the application. Defaults to an empty string.

.PARAMETER PrivacyURL
    A URL link to the application's privacy policy. Defaults to an empty string.

.PARAMETER CompanyPortalFeaturedApp
    Specifies whether the application should be featured in the Company Portal. Defaults to $false.

.PARAMETER CategoryName
    One or more category names to organize the application in Intune. Optional parameter.

.PARAMETER RestartBehavior
    Defines the restart behavior after installation. Valid values are "allow", "basedOnReturnCode", "suppress", or "force". Defaults to "suppress".

.PARAMETER InstallExperience
    Specifies the installation context. Valid values are "SYSTEM" or "User". Defaults to "SYSTEM".

.PARAMETER InstallCommandLine
    The command line used to install the application. Defaults to "[SourceFileName] -DeploymentType Install".

.PARAMETER UninstallCommandLine
    The command line used to uninstall the application. Defaults to "[SourceFileName] -DeploymentType Uninstall".

.EXAMPLE
    New-IntuneApp -SourcePath "C:\Installers\MyApp\Deploy-Application.exe" `
                  -DisplayName "My Application" `
                  -Publisher "Contoso Ltd" `
                  -Description "My application for business users" `
                  -ApplicationExePath "C:\Program Files\MyApp\MyApp.exe" `
                  -RegKeyPath "HKEY_LOCAL_MACHINE\SOFTWARE\MyApp" `
                  -DisplayVersion "1.0.0" `
                  -IconPath "C:\Installers\MyApp\icon.png"

    Creates a new Intune Win32 app using the specified parameters with default installation behavior.

.EXAMPLE
    New-IntuneApp -SourcePath "C:\Installers\MyApp\Deploy-Application.exe" `
                  -DisplayName "My Application" `
                  -Publisher "Contoso Ltd" `
                  -Description "My application for business users" `
                  -ApplicationExePath "C:\Program Files\MyApp\MyApp.exe" `
                  -RegKeyPath "HKEY_LOCAL_MACHINE\SOFTWARE\MyApp" `
                  -DisplayVersion "2.0.0" `
                  -IconPath "C:\Installers\MyApp\icon.png" `
                  -CategoryName "Productivity", "Business Apps" `
                  -CompanyPortalFeaturedApp $true `
                  -RestartBehavior "allow"

    Creates a featured Intune Win32 app with multiple categories and allows restart after installation.

.NOTES
    Author: Matt McPhee
    Requires: IntuneWin32App PowerShell module
    Requires: Microsoft Graph authentication with appropriate permissions
    The function expects PSAppDeployToolkit-style command line parameters by default.
    The function creates detection rules based on both file existence and registry version.
    Created: 7-Jan-2026
    Updated: 8-Jan-2026

    Version History:
    1.0.0 - 8-Jan-2026 - Function created

.LINK
    https://github.com/MSEndpointMgr/IntuneWin32App
#>
function New-IntuneApp {
    [CmdletBinding(SupportsShouldProcess)]
    param (
        # SourcePath - path to the main installer exe
        [Parameter(Mandatory)]
        [ValidateScript({
            if (-not (Test-Path -Path $_ -PathType Leaf)) {
                throw "$_ could not be found or is not a path to a file."
            } elseif ( ($_ -notlike "*.exe") -and ($_ -notlike "*.msi") ) {
                throw "The file '$_' must have an .exe or .msi extension."
            } else {
                return $true
            }
        })]
        [string]$SourcePath,

        # InstalledApplicationSizeMB
        [Parameter(Mandatory)]
        [int]$InstalledApplicationSizeMB,

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

        # InformationURL - link to a knowledge base item with further info (optional)
        [Parameter(Mandatory = $false)]
        [string]$InformationURL,

        # PrivacyURL - link to the app's privacy policy (optional)
        [Parameter(Mandatory = $false)]
        [string]$PrivacyURL,

        # CompanyPortalFeaturedApp - whether to feature the app in company portal (optional, defaults to false)
        [Parameter(Mandatory = $false)]
        [bool]$CompanyPortalFeaturedApp = $false,

        # CategoryName - specify a single or multiple categories categorize the app (optional)
        [Parameter(Mandatory = $false)]
        [string[]]$CategoryName,

        # RestartBehavior - restart behavior if app requires restart (optional, defaults to basedOnReturnCode)
        [Parameter(Mandatory = $false)]
        [ValidateSet("allow", "basedOnReturnCode", "suppress", "force")]
        [string]$RestartBehavior = "basedOnReturnCode",

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

    # Check for module
    $minVersion = [version]"1.5.0"
    $module = Get-Module -Name "IntuneWin32App" |
            Where-Object { $_.Version -ge $minVersion } |
            Sort-Object Version -Descending |
            Select-Object -First 1

    if (-not $module) {
        throw "IntuneWin32App module is missing. Please install and import it first."
    }

    # Package as .intunewin file
    $sourceFolder = $SourcePath | Split-Path -Parent
    $setupFile = $SourcePath | Split-Path -Leaf
    $setupFileNoExtension = [System.IO.Path]::GetFileNameWithoutExtension($setupFile)
    $outputFolder = ($SourcePath | Split-Path -Parent) + " Intune"
    if (-not (Test-Path $outputFolder -PathType Container)) {
        New-Item -Path $outputFolder -ItemType Directory -Force
    }
    $intunewinPath = "$outputFolder\$setupFileNoExtension.intunewin"
    if (Test-Path $intunewinPath) {
        $win32AppPackage = @{
            Path = $intunewinPath
        }
    } else {
        try {
            $win32AppPackage = New-IntuneWin32AppPackage -SourceFolder $sourceFolder -SetupFile $setupFile -OutputFolder $outputFolder -Force -ErrorAction "Stop"
        } catch {
            throw "Error occurred when creating .intunewin package: $_"
        }
    }

    # calculate how much disk space is required
    # add 1.5x the installed app size as overhead
    # add 100MB on top just in case
    try {
        $sourceFolderSizeMB = [int]((Get-ChildItem -Path $sourceFolder -Recurse -Force | Measure-Object -Property Length -Sum).Sum / 1MB)
        $intunewinSizeMB = [int]((Get-ChildItem -Path $intunewinPath -Force | Measure-Object -Property Length -Sum).Sum / 1MB)
        $installedAppSizeWithOverhead = [int]($InstalledApplicationSizeMB * 1.5)
        $minFreeDiskSpaceMB = $sourceFolderSizeMB + $intunewinSizeMB + $installedAppSizeWithOverhead + 100
        # round up to the nearest 100MB just in case in case
        $minFreeDiskSpaceMB = $minFreeDiskSpaceMB + (100 - ($minFreeDiskSpaceMB % 100))
    } catch {
        throw "Error encountered when calculating minimum free disk space."
    }

    # Create requirement rule for Intel/AMD platforms and Windows 10 20H2
    try {
        $reqRule = New-IntuneWin32AppRequirementRule `
            -Architecture "x64" `
            -MinimumSupportedWindowsRelease "W10_20H2" `
            -MinimumFreeDiskSpaceInMB $minFreeDiskSpaceMB `
            -ErrorAction "Stop"
    } catch {
        throw "Error occurred when creating requirement rule: $_"
    }

    # Create exe file detection rule - checking for file's existence
    $appExeFolder = $ApplicationExePath | Split-Path -Parent
    $appExe = $ApplicationExePath | Split-Path -Leaf

    try {
        $detRuleExe = New-IntuneWin32AppDetectionRuleFile `
            -Existence `
            -Path $appExeFolder `
            -FileOrFolder $appExe `
            -DetectionType "exists" `
            -ErrorAction "Stop"
    } catch {
        throw "Error occurred when creating file existence detection rule: $_"
    }

    # Create registry version detection rule
    # if version has only numbers and periods then use greater than or equal
    # else use string comparison equal
    if ($DisplayVersion -match "^(\d+(\.\d+){0,3})$") {
        $detRuleReg = New-IntuneWin32AppDetectionRuleRegistry `
            -VersionComparison `
            -KeyPath $RegKeyPath `
            -ValueName "DisplayVersion" `
            -VersionComparisonOperator "greaterThanOrEqual" `
            -VersionComparisonValue $DisplayVersion `
            -ErrorAction "Stop"
    } else {
        $detRuleReg = New-IntuneWin32AppDetectionRuleRegistry `
            -StringComparison `
            -KeyPath $RegKeyPath `
            -ValueName "DisplayVersion" `
            -StringComparisonOperator "equal" `
            -StringComparisonValue $DisplayVersion `
            -ErrorAction "Stop"
    }

    # Convert image file to icon
    try {
        $icon = New-IntuneWin32AppIcon -FilePath $IconPath -ErrorAction "Stop"
    } catch {
        throw "Error occurred when creating icon image: $_"
    }

    # Add new MSI Win32 app
    #-ScopeTagName "Endpoint Team-au_it_level_2_sccm_access_usg", "Dept-001-H07-Corporate-IT", "OU-au_computers_sccm_2012" `
    try {
        $addIntuneWin32AppArgs = @{
            FilePath                    = $win32AppPackage.Path
            DisplayName                 = $DisplayName
            Description                 = $Description
            Publisher                   = $Publisher
            AppVersion                  = $AppVersion
            Developer                   = $Developer
            Owner                       = $Owner
            Notes                       = $Notes
            CompanyPortalFeaturedApp    = $CompanyPortalFeaturedApp
            InstallExperience           = $InstallExperience
            InstallCommandLine          = $InstallCommandLine
            UninstallCommandLine        = $UninstallCommandLine
            RestartBehavior             = $RestartBehavior
            DetectionRule               = $detRuleExe, $detRuleReg
            RequirementRule             = $reqRule
            AllowAvailableUninstall     = $true
            Icon                        = $icon
            UseAzCopy                   = $true
            AzCopyWindowStyle           = "Hidden"
        }

        if ($PSBoundParameters["CategoryName"]) {
            $addIntuneWin32AppArgs.Add("CategoryName", $CategoryName)
        }

        if ($PSBoundParameters["PrivacyURL"]) {
            $addIntuneWin32AppArgs.Add("PrivacyURL", $PrivacyURL)
        }

        if ($PSBoundParameters["InformationURL"]) {
            $addIntuneWin32AppArgs.Add("InformationURL", $InformationURL)
        }

        if ($PSCmdlet.ShouldProcess($addIntuneWin32AppArgs, "Adding app to Intune using this information.")) {
            Add-IntuneWin32App @addIntuneWin32AppArgs
        }
    } catch {
        throw "Error occurred when adding app to intune: $_"
    }
}
