function New-Point {
    param(
        # x coordinate
        [Parameter(Mandatory)]
        [int32]
        $x,
        # y coordinate
        [Parameter(Mandatory)]
        [int32]
        $y
    )

    return [System.Drawing.Point]::New($x, $y)
}

Add-Type -AssemblyName System.Windows.Forms
Add-Type -AssemblyName System.Drawing
Add-Type -AssemblyName PresentationCore, PresentationFramework

$bmdLogo = [System.Drawing.Image]::FromFile("$PSScriptRoot\Images\bmd-logo.png")
$font = [System.Drawing.Font]::New("Segoe UI", 11, [System.Drawing.FontStyle]::Bold)
$transparent = [System.Drawing.Color]::FromName("Transparent")

$mainForm = [System.Windows.Forms.Form]::New()
$mainForm.clientSize = '500,270'
$mainForm.Text = 'HEICtoJPG Converter'
$mainForm.BackColor = "#ffffff"
$mainForm.TopMost = $true # force window to stay on top
$mainForm.FormBorderStyle = 'Fixed3D' # fixed three-dimensional border
$mainForm.MaximizeBox = $false # disables maximise option
$mainForm.BackgroundImage = $bmdLogo
$mainForm.BackgroundImageLayout = "Center"

$labelTitle = [System.Windows.Forms.Label]::New()
$labelTitle.Text = "Select file:"
$labelTitle.AutoSize = $true
$labelTitle.Font = $font
$labelTitle.BackColor = $transparent
$labelTitle.Location = New-Point 75, 100

$btnSelectFile = [System.Windows.Forms.Button]::New()
$btnSelectFile.

# add components to main form
$mainForm.Controls.AddRange(@($labelTitle))

# display form
$mainForm.ShowDialog()

# clean up form
$mainForm.Dispose()
