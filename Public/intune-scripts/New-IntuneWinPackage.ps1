function New-IntuneWinPackage {
    [CmdletBinding()]
    param (
        # SourceFolder
        [Parameter(Mandatory)]
        [string]
        $SourceFolder
    )

    $headers = @{ "User-Agent" = "PowerShell" }
    $url = "https://github.com/Microsoft/Microsoft-Win32-Content-Prep-Tool/archive/refs/heads/master.zip"
    $targetDir = "C:\sources\tools"
    $exePath = Join-Path -Path $targetDir -ChildPath "intunewinapputil.exe"
    $tempZipPath = Join-Path -Path $env:TEMP -ChildPath "IntuneWinAppUtil_Master.zip"
    $tempExtractPath = Join-Path -Path $env:TEMP -ChildPath "IntuneWinAppUtil_Master"
    $ProgressPreference = 'SilentlyContinue'
    
    try {
        # create folder if it doesn't exist
        if (-not (Test-Path -Path $targetDir)) {
            Write-Host "Creating target directory: $targetDir" -ForegroundColor Green
            New-Item -Path $targetDir -ItemType Directory | Out-Null
        }

        # download the ZIP file
        Write-Host "Downloading latest version from GitHub..." -ForegroundColor Cyan
        try {
            Invoke-WebRequest -Uri $url -OutFile $tempZipPath -Headers $headers -ErrorAction Stop
            Write-Host "Download successful." -ForegroundColor Green
        } catch {
            throw "Failed to download the file from $url. Error: $($_.Exception.Message)"
        }

        # extract the ZIP file
        Write-Host "Extracting files to temporary directory..." -ForegroundColor Cyan
        try {
            Expand-Archive -Path $tempZipPath -DestinationPath $tempExtractPath -Force
            Write-Host "Extraction successful." -ForegroundColor Green
        } catch {
            throw "Failed to extract the ZIP file. Error: $($_.Exception.Message)"
        }

        # copy the executable to the target path
        Write-Host "Copying intunewinapputil.exe to $targetDir..." -ForegroundColor Cyan

        # the executable is typically located inside a folder named 'Microsoft-Win32-Content-Prep-Tool-master'
        $sourceExePath = Get-ChildItem -Path "$tempExtractPath\*" -Filter "IntuneWinAppUtil.exe" -Recurse | Select-Object -ExpandProperty FullName -First 1

        if (-not $sourceExePath) {
            throw "Could not find IntuneWinAppUtil.exe in the extracted content."
        }

        try {
            Copy-Item -Path $sourceExePath -Destination $exePath -Force -ErrorAction Stop
            Write-Host "Successfully placed IntuneWinAppUtil.exe at $exePath" -ForegroundColor Green
        } catch {
            throw "Failed to copy the executable. Error: $($_.Exception.Message)"
        }

        # clean up temporary files
        Write-Host "Cleaning up temporary files..." -ForegroundColor Cyan
        Remove-Item -Path $tempZipPath -Force -ErrorAction SilentlyContinue
        Remove-Item -Path $tempExtractPath -Recurse -Force -ErrorAction SilentlyContinue
        Write-Host "Cleanup complete." -ForegroundColor Green

        # create dummy exe file
        $SourceFolderName = $SourceFolder | Split-Path -Leaf
        $dummyExePath = "$SourceFolder\$SourceFolderName"
        New-Item -Path $dummyExePath -ItemType File -Force | Out-Null

        # run intunewinapputil.exe
        $intunewinFileName = ($SourceFolder | Split-Path -Leaf) + ".intunewin"
        Write-Host "Packaging $SourceFolder into $targetDir\$intunewinFileName" -ForegroundColor Cyan
        $exeArgs = "-c `"$SourceFolder`" -s `"$dummyExePath`" -o `"$targetDir`" -qq"

        try {
            Start-Process $exePath -ArgumentList $exeArgs -Wait -WindowStyle Hidden
        } catch {
            throw "Failed to run $exePath. Error: $($_.Exception.Message)"
        }

        # remove dummy exe file
        Remove-Item $dummyExePath -Force -ErrorAction SilentlyContinue
        
        Write-Host "Packaging complete." -ForegroundColor Green
    } catch {
        throw $_
    }
}
