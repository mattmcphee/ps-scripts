
function Get-BOMRadarGif {
    [CmdletBinding()]
    param(
        [Parameter()]
        [ValidateSet('IDR663', 'IDR664', 'IDR662', 'IDR661')]
        [string]$ProductId = 'IDR664',

        [Parameter()]
        [ValidateRange(2, 20)]
        [int]$FrameCount = 7,

        [Parameter()]
        [ValidateRange(50, 5000)]
        [int]$DelayMs = 500,

        [Parameter()]
        [string]$OutputPath = "C:\sources\bomradar\$(Get-Date -Format 'yyyyMMdd_HHmmss')_bomradar.gif"
    )

    $ErrorActionPreference = 'Stop'

    $Magick = (Get-Command magick -ErrorAction Stop).Source
    $RadarUrl = 'ftp://ftp.bom.gov.au/anon/gen/radar/'
    $OverlayUrl = 'ftp://ftp.bom.gov.au/anon/gen/radar_transparencies/'
    $TempPath = Join-Path ([IO.Path]::GetTempPath()) ([guid]::NewGuid().ToString())

    New-Item -Path $TempPath -ItemType Directory -Force | Out-Null

    $Client = [System.Net.WebClient]::new()
    $Client.Credentials = [System.Net.NetworkCredential]::new('anonymous', 'anonymous@example.com')

    try {
        # List available radar images.
        $Request = [System.Net.FtpWebRequest]::Create($RadarUrl)
        $Request.Method = [System.Net.WebRequestMethods+Ftp]::ListDirectory
        $Request.Credentials = $Client.Credentials
        $Request.UseBinary = $true
        $Request.UsePassive = $true

        $Response = $Request.GetResponse()

        try {
            $Reader = [IO.StreamReader]::new($Response.GetResponseStream())
            try {
                $Listing = $Reader.ReadToEnd() -split '\r?\n'
            }
            finally {
                $Reader.Dispose()
            }
        }
        finally {
            $Response.Dispose()
        }

        # Select newest timestamped PNGs, then sort oldest first.
        $Pattern = '^' + [regex]::Escape($ProductId) + '\.T\.\d{12}\.png$'

        $Files = @(
            $Listing |
                ForEach-Object { $_.Trim() } |
                Where-Object { $_ -match $Pattern } |
                Sort-Object -Descending |
                Select-Object -First $FrameCount |
                Sort-Object
        )

        if ($Files.Count -lt 2) {
            throw "Not enough radar frames found for $ProductId."
        }

        # Download static map layers.
        $Layers = @('background', 'topography', 'locations')
        $LayerPaths = @{}

        foreach ($Layer in $Layers) {
            $Name = "$ProductId.$Layer.png"
            $Path = Join-Path $TempPath $Name

            $Client.DownloadFile("$OverlayUrl$Name", $Path)
            $LayerPaths[$Layer] = $Path
        }

        # Download radar images and create composite frames.
        $FramePaths = @()
        $Index = 0

        foreach ($File in $Files) {
            $Index++

            $RadarPath = Join-Path $TempPath $File
            $FramePath = Join-Path $TempPath ('frame-{0:D2}.png' -f $Index)

            Write-Verbose "Downloading $File"
            $Client.DownloadFile("$RadarUrl$File", $RadarPath)

            & $Magick `
                $LayerPaths['background'] `
                $LayerPaths['topography'] `
                -compose Over -composite `
                $RadarPath `
                -compose Over -composite `
                $LayerPaths['locations'] `
                -compose Over -composite `
                $FramePath

            if ($LASTEXITCODE -ne 0) {
                throw "Failed to compose frame $Index."
            }

            $FramePaths += $FramePath
        }

        # Generate looping animated GIF.
        $Delay = [math]::Max(1, [int][math]::Round($DelayMs / 10))

        $OutputPath = $ExecutionContext.SessionState.Path.GetUnresolvedProviderPathFromPSPath($OutputPath)

        $Parent = Split-Path $OutputPath -Parent
        New-Item -Path $Parent -ItemType Directory -Force | Out-Null

        & $Magick -delay $Delay -loop 0 @FramePaths $OutputPath

        if ($LASTEXITCODE -ne 0) {
            throw 'ImageMagick failed to generate the GIF.'
        }

        Get-Item $OutputPath
    }
    finally {
        $Client.Dispose()
        Remove-Item $TempPath -Recurse -Force -ErrorAction SilentlyContinue
    }
}
