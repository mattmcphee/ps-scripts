function Resize-Image {
    [CmdletBinding()]
    param (
        # input image file
        [Parameter(Mandatory=$true)]
        [string]
        $InputFile,
        # output image file
        [Parameter(Mandatory=$true)]
        [string]
        $OutputFile,
        # a value in percentage to scale the image
        [Parameter(Mandatory=$true)]
        [Int32]
        $Scale
    )
    # add drawing assembly
    Add-Type -AssemblyName System.Drawing

    # open the image file
    $img = [System.Drawing.Image]::FromFile((Get-Item $InputFile))

    # define new res
    [Int32]$newWidth = $img.Width * ($Scale / 100)
    [Int32]$newHeight = $img.Height * ($Scale / 100)

    # create empty canvas for the new image
    $imgNew = New-Object System.Drawing.Bitmap($newWidth,$newHeight)

    # draw image on canvas
    $graphic = [System.Drawing.Graphics]::FromImage($imgNew)
    $graphic.DrawImage($img, 0, 0, $newWidth, $newHeight)

    # dispose and save
    $graphic.Dispose()
    $img.Dispose()
    $imgNew.Save($OutputFile)
    $imgNew.Dispose()
}