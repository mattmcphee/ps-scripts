function Get-EdgeDriver {
    [CmdletBinding()]
    param (
        # UrlList
        [Parameter(ValueFromPipeline)]
        [string]
        $UrlList = "https://doc.samsungmobile.com/SM-S931B/XSA/doc.html"
    )

    function Expand-NupkgArchive {
        param (
            # Path
            [Parameter(Mandatory)]
            [string]
            $Path,
            # DestinationPath
            [Parameter(Mandatory)]
            [string]
            $DestinationPath
        )

        Invoke-Expression "7z x $Path -o`"$DestinationPath`"" | Out-Null
    }

    # TESTING - REMOVE THIS
    $UrlList = @("https://doc.samsungmobile.com/SM-S931B/XSA/doc.html")

    # set progress preference
    $initialProgressPreference = $global:ProgressPreference
    $global:ProgressPreference = 'SilentlyContinue'

    # set script folder variable
    $scriptFolder = "$PSScriptRoot\Get-EdgeDriver"
    if (-not (Test-Path -Path $scriptFolder)) {
        New-Item -ItemType Directory -Path $scriptFolder -Force | Out-Null
    }

    # pull out edge path from registry -> edge version from msedge.exe
    $edgeRegPath = 'HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\App Paths\msedge.exe'
    $edgeExePath = (Get-ItemProperty -Path $edgeRegPath).'(default)'
    $edgeItem = Get-Item -Path $edgeExePath
    $edgeVersion = $edgeItem.VersionInfo.ProductVersion
    $edgeDriverFolder = $scriptFolder
    $edgeDriverPath = "$scriptFolder\msedgedriver.exe"
    $edgeDriverDownloadURL = "https://msedgedriver.microsoft.com/$edgeVersion/edgedriver_win64.zip"
    $edgeDriverZipPath = "$scriptFolder\edgedriver_win64.zip"

    # check if edge driver is in msedge.exe folder
    if (Test-Path -Path $edgeDriverPath) {
        Write-Verbose "msedgedriver.exe found at $edgeDriverPath"
    } else {
        Write-Verbose "msedgedriver.exe not found. Attempting to download..."

        try {
            Invoke-WebRequest -Uri $edgeDriverDownloadURL -OutFile $edgeDriverZipPath
        } catch {
            throw $_
        }

        if (Test-Path -Path $edgeDriverZipPath) {
            Write-Verbose "msedgedriver.zip download completed. msedgedriver.zip exists at $edgeDriverZipPath"
            Write-Verbose "Extracting..."
        } else {
            throw "msedgedriver.zip not found - something went wrong with downloading..."
        }

        Expand-Archive -Path $edgeDriverZipPath -DestinationPath $scriptFolder -Force
        Remove-Item -Path $edgeDriverZipPath -Force

        if (Test-Path -Path $edgeDriverPath) {
            Write-Verbose "Extraction complete."
            Write-Verbose "msedgedriver.exe exists at $edgeDriverPath"
        } else {
            throw "msedgedriver.exe not found - something went wrong with extracting..."
        }
    }

    # create selenium folder if not found
    $seleniumFolder = "$scriptFolder\Selenium"
    if (-not (Test-Path $seleniumFolder)) {
        New-Item -ItemType Directory -Path $seleniumFolder -Force | Out-Null
    }

    Write-Verbose "Fetching latest Selenium .NET release info..."
    $releaseInfo = Invoke-RestMethod -Uri "https://api.github.com/repos/SeleniumHQ/selenium/releases/latest"
    $dotnetAsset = $releaseInfo.assets | Where-Object { $_.name -match "selenium-dotnet-\d+(\.\d+)*\.zip$" }

    if (-not $dotnetAsset) {
        throw "Could not find selenium-dotnet zip in the latest release."
    }

    # download selenium zip
    $seleniumZipPath = Join-Path -Path $seleniumFolder -ChildPath $dotnetAsset.name
    if (-not (Test-Path -Path $seleniumZipPath)) {
        Write-Verbose "Downloading $($dotnetAsset.name) ..."
        Invoke-WebRequest -Uri $dotnetAsset.browser_download_url -OutFile $seleniumZipPath
    }

    # extract zip contents to selenium folder
    if (-not (Test-Path -Path "$seleniumFolder\Selenium.WebDriver.*.nupkg")) {
        Write-Verbose "Extracting $seleniumZipPath ..."
        Expand-Archive -Path $seleniumZipPath -DestinationPath $seleniumFolder -Force
    }

    # extract webdriver nupkg contents to selenium folder
    $seleniumWebDriverNupkg = (Get-Item -Path "$seleniumFolder\Selenium.WebDriver.*.nupkg").FullName
    $seleniumDriverPath = "$seleniumFolder\WebDriver\lib\netstandard2.0\WebDriver.dll"
    if (-not (Test-Path -Path $seleniumDriverPath)) {
        Write-Verbose "Extracting $seleniumWebDriverNupkg ..."
        Expand-NupkgArchive -Path $seleniumWebDriverNupkg -DestinationPath "$seleniumFolder\WebDriver"
    }

    # extract webdriver support nupkg contents to selenium folder
    $seleniumSupportNupkg = (Get-Item -Path "$seleniumFolder\Selenium.Support.*.nupkg").FullName
    $seleniumSupportPath = "$seleniumFolder\Support\lib\netstandard2.0\WebDriver.Support.dll"
    if (-not (Test-Path -Path $seleniumSupportPath)) {
        Write-Verbose "Extracting $seleniumSupportNupkg ..."
        Expand-NupkgArchive -Path $seleniumSupportNupkg -DestinationPath "$seleniumFolder\Support"
    }

    # load dlls
    try {
        Add-Type -Path $seleniumDriverPath
        Add-Type -Path $seleniumSupportPath
    } catch {
        throw $_
    }

    $edgeService = [OpenQA.Selenium.Edge.EdgeDriverService]::CreateDefaultService($edgeDriverFolder,"msedgedriver.exe")
    $edgeService.HideCommandPromptWindow = $true

    # restore progress preference
    $global:ProgressPreference = $initialProgressPreference
}
