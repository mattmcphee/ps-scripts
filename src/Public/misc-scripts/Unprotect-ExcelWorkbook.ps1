function Unprotect-ExcelWorkbook {
    <#
    .SYNOPSIS
    Removes sheet and workbook structure protection from an .xlsx file.

    .DESCRIPTION
    Extracts the .xlsx archive, searches workbook.xml and all sheet.xml files 
    for the <workbookProtection> and <sheetProtection> tags, removes them, 
    and re-compresses the file into a new unprotected document.
    #>
    param (
        [Parameter(Mandatory=$true)]
        [string]$FilePath
    )

    # 1. Validate File
    if (-not (Test-Path $FilePath)) {
        throw "File not found: $FilePath"
    }

    $fileInfo = Get-Item $FilePath
    if ($fileInfo.Extension -ne '.xlsx') {
        throw "This script only works on .xlsx files."
    }

    # 2. Setup Paths
    $directory = $fileInfo.DirectoryName
    $baseName = $fileInfo.BaseName
    $newFilePath = Join-Path $directory "$($baseName)_Unprotected.xlsx"
    $tempZipPath = Join-Path $directory "$($baseName)_temp.zip"
    $tempExtractPath = Join-Path $directory "$($baseName)_temp_extract"

    # Clean up any residual temp folders from previous failed runs
    if (Test-Path $tempExtractPath) { Remove-Item $tempExtractPath -Recurse -Force }
    if (Test-Path $tempZipPath) { Remove-Item $tempZipPath -Force }

    try {
        Write-Host "Creating working copy and extracting..." -ForegroundColor Cyan
        Copy-Item $FilePath $tempZipPath
        Expand-Archive -Path $tempZipPath -DestinationPath $tempExtractPath -Force

        # Excel requires UTF-8 without a Byte Order Mark (BOM). 
        # Standard Out-File/Set-Content can corrupt the XML, so we use .NET directly.
        $utf8NoBom = New-Object System.Text.UTF8Encoding $false

        # 3. Process workbook.xml (Workbook Structure Protection)
        $workbookPath = Join-Path $tempExtractPath "xl\workbook.xml"
        if (Test-Path $workbookPath) {
            $xmlContent = Get-Content $workbookPath -Raw
            if ($xmlContent -match '<workbookProtection[^>]*>') {
                Write-Host " -> Removing workbook protection..."
                $xmlContent = $xmlContent -replace '<workbookProtection[^>]*>', ''
                [System.IO.File]::WriteAllText($workbookPath, $xmlContent, $utf8NoBom)
            }
        }

        # 4. Process sheet*.xml files (Sheet Edit Protection)
        $sheetsPath = Join-Path $tempExtractPath "xl\worksheets"
        if (Test-Path $sheetsPath) {
            $sheetFiles = Get-ChildItem -Path $sheetsPath -Filter "*.xml"
            foreach ($sheet in $sheetFiles) {
                $sheetPath = $sheet.FullName
                $xmlContent = Get-Content $sheetPath -Raw
                if ($xmlContent -match '<sheetProtection[^>]*>') {
                    Write-Host " -> Removing protection from $($sheet.Name)..."
                    $xmlContent = $xmlContent -replace '<sheetProtection[^>]*>', ''
                    [System.IO.File]::WriteAllText($sheetPath, $xmlContent, $utf8NoBom)
                }
            }
        }

        # 5. Re-compress the file
        Write-Host "Re-compressing file into new .xlsx..." -ForegroundColor Cyan
        # Note: We zip the contents of the folder (\*), not the folder itself.
        Compress-Archive -Path "$tempExtractPath\*" -DestinationPath $tempZipPath -Force
        Copy-Item -Path $tempZipPath -Destination $newFilePath -Force

        Write-Host "Success! Unprotected file saved to: $newFilePath" -ForegroundColor Green

    }
    catch {
        Write-Error "An error occurred: $_"
    }
    finally {
        # 6. Cleanup Temp Files
        Write-Host "Cleaning up temporary files..."
        if (Test-Path $tempExtractPath) { Remove-Item $tempExtractPath -Recurse -Force }
        if (Test-Path $tempZipPath) { Remove-Item $tempZipPath -Force }
    }
}
