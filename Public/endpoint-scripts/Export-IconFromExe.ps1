function Export-IconFromExe {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$true)]
        [string]$ExePath,

        [Parameter(Mandatory=$false)]
        [string]$OutputFolder
    )

    if (-not $PSBoundParameters["OutputFolder"]) {
        $OutputFolder = $ExePath | Split-Path -Parent
    }

    # load the required .NET assembly
    Add-Type -AssemblyName System.Drawing

    # ensure the output directory exists
    if (-not (Test-Path $OutputFolder)) {
        New-Item -ItemType Directory -Path $OutputFolder | Out-Null
    }

    try {
        # 3. Extract the icon associated with the file
        # Note: This usually pulls the default large icon (32x32 or 48x48)
        $icon = [System.Drawing.Icon]::ExtractAssociatedIcon($ExePath)
        $bitmap = $icon.ToBitmap()

        # 4. Create a new 512x512 canvas (Bitmap)
        $newBitmap = New-Object System.Drawing.Bitmap(512, 512)
        $graphics = [System.Drawing.Graphics]::FromImage($newBitmap)

        # 5. Set high-quality resizing options
        $graphics.InterpolationMode = [System.Drawing.Drawing2D.InterpolationMode]::HighQualityBicubic
        $graphics.SmoothingMode = [System.Drawing.Drawing2D.SmoothingMode]::HighQuality
        $graphics.PixelOffsetMode = [System.Drawing.Drawing2D.PixelOffsetMode]::HighQuality

        # 6. Draw the original icon onto the new 512x512 canvas
        $graphics.DrawImage($bitmap, 0, 0, 512, 512)

        # 7. Define file names
        $baseName = [System.IO.Path]::GetFileNameWithoutExtension($ExePath)
        $pngPath = Join-Path $OutputFolder "$baseName.png"
        $icoPath = Join-Path $OutputFolder "$baseName.ico"

        # 8. Save as PNG
        $newBitmap.Save($pngPath, [System.Drawing.Imaging.ImageFormat]::Png)
        Write-Verbose "Success: Saved PNG to $pngPath"

        # 9. Save as ICO
        # We convert the bitmap back to an icon handle to save in .ico format
        $hIcon = $newBitmap.GetHicon()
        $newIcon = [System.Drawing.Icon]::FromHandle($hIcon)
        $fileStream = [System.IO.File]::OpenWrite($icoPath)
        $newIcon.Save($fileStream)
        $fileStream.Close()
        
        Write-Verbose "Success: Saved ICO to $icoPath"
    } catch {
        Write-Error "Failed to extract or save icon: $($_.Exception.Message)"
    } finally {
        # Cleanup to prevent memory leaks
        if ($graphics) { $graphics.Dispose() }
        if ($newBitmap) { $newBitmap.Dispose() }
        if ($bitmap) { $bitmap.Dispose() }
        if ($icon) { $icon.Dispose() }
    }
}
