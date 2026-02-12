function Get-SCCMAppInfo {
    [CmdletBinding()]
    param (
        # ApplicationName
        [Parameter(Mandatory=$true)]
        [string[]]$ApplicationName,

        # CsvOutPath
        [Parameter(Mandatory = $false)]
        [string]$CsvOutPath = "C:\sources\csv\$(Get-Date -Format 'yyyy-MM-dd-HHmmss')-appinfo.csv"
    )

    begin {
        # change drive logic
        $ogLoc = Get-Location
        Set-Location "A00:"
    }

    process {
        foreach ($appName in $ApplicationName) {
            # get app
            try {
                $app = Get-CMApplication -Name $appName
            } catch {
                throw "Encountered error when retrieving info about '$app': $_"
            }

            if ($null -eq $app) {
                throw "Could not find application named '$appName': $_"
            } elseif ($app.Count -gt 1) {
                throw "Found more than one app when searching for '$appName'. Be more specific."
            }

            # pull out info from sdmpackagexml into result object
            [xml]$appxml = $app.SDMPackageXml
            $appxmlDisplayInfo = $appxml.AppMgmtDigest.Application.DisplayInfo.Info
            $appxmlInstaller = $appxml.AppMgmtDigest.DeploymentType.Installer

            # this is an array containing install and uninstall if they are separate
            # if uninstall is present then separate them, if not then only return contentlocation
            $contentLocation = $appxmlInstaller.Contents.Content
            if ($contentLocation.Count -gt 1) {
                $installContentLocation = $contentLocation | 
                    Where-Object { $_.Location -like "*\install*" } |
                    Select-Object -ExpandProperty "Location"
                $uninstallContentLocation = $contentLocation | 
                    Where-Object { $_.Location -like "*\uninstall*" } |
                    Select-Object -ExpandProperty "Location"
            } else {
                $installContentLocation = $contentLocation.Location
                $uninstallContentLocation = $null
            }

            # handle cases where there are multiple registry key detection methods
            $appxmlRegistry = $appxmlInstaller.CustomData.EnhancedDetectionMethod.Settings.SimpleSetting.RegistryDiscoverySource
            if ($appxmlRegistry.Count -gt 1) {
                $registryHive0 = $appxmlRegistry[0].Hive
                $registryHive1 = $appxmlRegistry[1].Hive
                $registryKey0 = $appxmlRegistry[0].Key
                $registryKey1 = $appxmlRegistry[1].Key
                $registryValueName0 = $appxmlRegistry[0].ValueName
                $registryValueName1 = $appxmlRegistry[1].ValueName
            } else {
                $registryHive0 = $appxmlRegistry.Hive
                $registryKey0 = $appxmlRegistry.Key
                $registryValueName0 = $appxmlRegistry.ValueName
                $registryHive1 = $null
                $registryKey1 = $null
                $registryValueName1 = $null
            }

            $appxmlRegistryVersionValue = $appxmlInstaller.CustomData.EnhancedDetectionMethod.Rule.Expression.Operands.Expression.Operands.ConstantValue |
                Where-Object { $_.DataType -like "String" } |
                Select-Object -ExpandProperty "Value"
            if ($appxmlRegistryVersionValue.Count -gt 1) {
                $registryVersionValue0 = $appxmlRegistryVersionValue[0]
                $registryVersionValue1 = $appxmlRegistryVersionValue[1]
            } else {
                $registryVersionValue0 = $appxmlRegistryVersionValue
                $registryVersionValue1 = $null
            }

            # handle cases where msi detection info isn't in the standard location
            $msiProductCode = $appxmlInstaller.CustomData.ProductCode
            if ($null -eq $msiProductCode) {
                $msiProductCode = $appxmlInstaller.CustomData.EnhancedDetectionMethod.Settings.MSI.ProductCode
            }

            $msiProductVersion = $appxmlInstaller.CustomData.ProductVersion
            if ($null -eq $msiProductVersion) {
                $msiProductVersion = $appxmlInstaller.CustomData.EnhancedDetectionMethod.Rule.Expression.Operands.ConstantValue.Value
            }

            # handle cases where there are multiple msiproductcodes
            if ($msiProductCode.Count -gt 1) {
                $msiProductCode0 = $msiProductCode[0]
                $msiProductCode1 = $msiProductCode[1]
            } else {
                $msiProductCode0 = $msiProductCode
                $msiProductCode1 = $null
            }

            $appInfo = [pscustomobject]@{
                DisplayName                 = $appxmlDisplayInfo.Title
                Description                 = $appxmlDisplayInfo.Description
                Publisher                   = $appxmlDisplayInfo.Publisher
                AppVersion                  = $appxmlDisplayInfo.Version
                InstallContentLocation      = $installContentLocation
                UninstallContentLocation    = $uninstallContentLocation
                InstallCommandLine          = $appxmlInstaller.CustomData.InstallCommandLine
                UninstallCommandLine        = $appxmlInstaller.CustomData.UninstallCommandLine
                ExecutionContext            = $appxmlInstaller.InstallAction.Args.Arg |
                    Where-Object { $_.name -like "ExecutionContext" } |
                    Select-Object -ExpandProperty '#text'
                ExecuteTime                 = $appxmlInstaller.InstallAction.Args.Arg |
                    Where-Object { $_.name -like "ExecuteTime" } |
                    Select-Object -ExpandProperty '#text'
                MaxExecuteTime              = $appxmlInstaller.InstallAction.Args.Arg |
                    Where-Object { $_.name -like "MaxExecuteTime" } |
                    Select-Object -ExpandProperty '#text'
                RegistryHive0               = $registryHive0
                RegistryKey0                = $registryKey0
                RegistryValueName0          = $registryValueName0
                RegistryVersionValue0       = $registryVersionValue0
                RegistryHive1               = $registryHive1
                RegistryKey1                = $registryKey1
                RegistryValueName1          = $registryValueName1
                RegistryVersionValue1       = $registryVersionValue1
                InstalledFolder             = $appxmlInstaller.CustomData.EnhancedDetectionMethod.Settings.File.Path
                InstalledExe                = $appxmlInstaller.CustomData.EnhancedDetectionMethod.Settings.File.Filter
                MSIProductCode0             = $msiProductCode0
                MSIProductCode1             = $msiProductCode1
                MSIProductVersion           = $msiProductVersion
            }

            $appInfo | Export-Csv -Path $CsvOutPath -NoTypeInformation -Append
            $appInfo
        }
    }

    end {
        Set-Location $ogLoc
    }
}
