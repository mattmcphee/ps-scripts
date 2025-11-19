function Get-PSADTTemplateLatest {
    [CmdletBinding()]
    param (
        # DestinationFolder
        [Parameter(Mandatory)]
        [string]
        $DestinationFolder
    )
    
    $repo = "PSAppDeployToolkit"
    $githubUrl = "https://api.github.com/repos/$repo/$repo/releases/latest"
    
    $fileName = "PSAppDeployToolkit_Template_v4.zip"
    $outFile = Split-Path -Path $DestinationFolder -Parent | Join-Path -ChildPath $fileName


    # if folder exists, rename it to timestamp
    if (Test-Path -Path $DestinationFolder) {
        try {
            $timestamp = Get-Date -Format "yyyyMMddhhmmss"
            $newName = "$timestamp-psadt"
            Write-Host "Path already exists. Renaming folder to $newName"
            Rename-Item -Path $DestinationFolder -NewName $newName -Force
        } catch {
            throw $_
        }
    }

    # create destination folder if it doesn't exist
    if (-not (Test-Path -Path $DestinationFolder)) {
        Write-Host "Creating directory: $DestinationFolder"
        $null = New-Item -Path $DestinationFolder -ItemType Directory
    }

    # get latest release info from github
    Write-Host "Querying github for latest release..."
    try {
        $ProgressPreference = 'SilentlyContinue'

        $releaseInfo = Invoke-RestMethod -Uri $githubUrl

        $asset = $releaseInfo.assets | Where-Object { $_.name -eq $fileName }

        if ($asset) {
            $downloadUrl = $asset.browser_download_url
            Write-Host "Found latest release $($releaseInfo.tag_name) with download URL $downloadUrl"
        } else {
            throw "Could not find $fileName in the latest release."
        }
    } catch {
        throw "Failed to connect to github or parse response: $_"
    }

    # remove zip if it exists
    if (Test-Path $outFile) {
        Remove-Item -Path $outFile -Force
    }
    
    # download the file
    Write-Host "Downloading $fileName from $downloadUrl..."
    try {
        Invoke-WebRequest -Uri $downloadUrl -OutFile $outFile
        Write-Host "Download saved to $outFile"
    } catch {
        throw "Failed to download file: $_"
    }

    # extract the file
    Write-Host "Extracting $fileName to $DestinationFolder..."
    try {
        $7zArgs = "x `"$outFile`" -o`"$DestinationFolder`""
        Start-Process -FilePath "C:\Program Files\7-Zip\7z.exe" -ArgumentList $7zArgs -WindowStyle Hidden -Wait
        Write-Host "Successfully extracted $fileName to $DestinationFolder"
    } catch {
        throw "Error encountered when attempting to extract: $_"
    }
}