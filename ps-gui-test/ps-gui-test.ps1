Add-Type -AssemblyName System.Windows.Forms
Add-Type -AssemblyName System.Drawing

function New-Button {
    param (
        # text to display on button
        [Parameter(Mandatory=$true)]
        [string]
        $Text,
        # positionX
        [Parameter(Mandatory=$true)]
        [int]
        $PosX,
        # positionY
        [Parameter(Mandatory=$true)]
        [int]
        $PosY
    )
    $btn = [System.Windows.Forms.Button]::New()
    $btn.Text = $Text
    $btn.AutoSize = $true
    $btn.BackColor = "#aed6f1"
    $btn.ForeColor = "#000000"
    $btn.Font = 'Consolas,12'
    $btn.Location = [System.Drawing.Point]::New($PosX,$PosY)
    return $btn
}

function New-Label {
    param (
        # text
        [Parameter(Mandatory=$true)]
        [string]
        $Text,
        # x position
        [Parameter(Mandatory=$true)]
        [int]
        $PosX,
        # y position
        [Parameter(Mandatory=$true)]
        [int]
        $PosY
    )
    $label = [System.Windows.Forms.Label]::New()
    $label.text = $Text
    $label.AutoSize = $true
    $label.location = [System.Drawing.Point]::New($PosX,$PosY)
    $label.font = 'Consolas,13'
    return $label
}

function New-TextBox {
    param (
        # x position
        [Parameter(Mandatory=$true)]
        [int]
        $PosX,
        # y position
        [Parameter(Mandatory=$true)]
        [int]
        $PosY
    )
    $textbox = [System.Windows.Forms.TextBox]::New()
    $textbox.Width = 460
    $textbox.Height = 300
    $textbox.Text = 'Choose a file'
    $textbox.BackColor = '#FFFFFF'
    $textbox.Location = [System.Drawing.Point]::New($PosX,$PosY)
    return $textbox
}

$launchPage = [System.Windows.Forms.Form]::New()
$launchPage.ClientSize = '500,600'
$launchPage.StartPosition = 'CenterScreen'
$launchPage.Text = "PowerShell GUI"
$launchPage.BackColor = "#E5E4E2"

$title = New-Label -Text "PowerShell GUI" -PosX 20 -PosY 20
$filePickerBtn = New-Button -Text "Choose file" -PosX 20 -PosY 50
$textbox = New-TextBox -PosX 20 -PosY 100

$launchPage.Controls.AddRange(@($title,$filePickerBtn,$textbox))
[void]$launchPage.ShowDialog()

