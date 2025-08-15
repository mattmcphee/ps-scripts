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

    # download nuget.exe
    $nugetDownloadURL = "https://dist.nuget.org/win-x86-commandline/latest/nuget.exe"
    $nugetPath = "$scriptFolder\nuget.exe"
    if (Test-Path -Path $nugetPath) {
        Write-Verbose "nuget.exe found: $nugetPath"
    } else {
        Write-Verbose "nuget.exe not found. Downloading..."
        Invoke-WebRequest -Uri $nugetDownloadURL -OutFile $nugetPath
    }

    # install selenium driver using nuget
    if (Test-Path -Path "$scriptFolder\Selenium.WebDriver.*\lib\netstandard*\WebDriver.dll") {
        Write-Verbose "Selenium driver found"
    } else {
        "Selenium driver not found. Downloading..."
        Invoke-Expression "$nugetPath install Selenium.WebDriver -OutputDirectory `"$scriptFolder`"" | Out-Null
    }

    # import selenium
    Add-Type -Path (Get-Item -Path "$scriptFolder\Selenium.WebDriver.*\lib\netstandard*\WebDriver.dll").FullName

    [OpenQA.Selenium.Chromium.ChromiumDriver]$edgeDriver = New-Object OpenQA.Selenium.Edge.EdgeDriver($edgeDriverPath)

    Start-Sleep -Seconds 5

    $edgeDriver.Navigate().GoToUrl("https://doc.samsungmobile.com/SM-S931B/XSA/doc.html")

    Start-Sleep -Seconds 5

    $edgeDriver.Quit()

    # restore progress preference
    $global:ProgressPreference = $initialProgressPreference
}
