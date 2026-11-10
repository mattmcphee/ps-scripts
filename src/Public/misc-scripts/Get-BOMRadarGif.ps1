
function Get-BOMRadarGif {
    <#
    .SYNOPSIS
        Creates an animated GIF from the latest BOM Mt Stapylton rain radar images.
    .DESCRIPTION
        Downloads radar frames and map layers from BOM's anonymous FTP service.
        Requires ImageMagick 7 (magick) on PATH and access to FTP, including passive data connections.
    .PARAMETER ProductId
        Radar range: IDR661 (512 km), IDR662 (256 km), IDR663 (128 km), or IDR664 (64 km).
    .PARAMETER FrameCount
        Maximum number of recent frames to include, oldest first. At least two must be available.
    .PARAMETER DelayMs
        Delay between frames in milliseconds, rounded to the nearest 10 milliseconds for GIF.
    .PARAMETER OutputFolder
        Destination folder, created if needed. Defaults to the current directory.
        The filename is yyyyMMdd_HHmmss_bomradar.gif. An existing file with the same
        name is replaced only after GIF encoding succeeds.
    .EXAMPLE
        Get-BOMRadarGif -ProductId IDR663 -FrameCount 10 -OutputFolder .\radar
    .OUTPUTS
        System.IO.FileInfo
    #>
    [CmdletBinding()]
    [OutputType([IO.FileInfo])]
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
        [ValidateNotNullOrEmpty()]
        [string]$OutputFolder = '.'
    )

    $ErrorActionPreference = 'Stop'

    $ProductId = $ProductId.ToUpperInvariant()
    $OutputFolder = $ExecutionContext.SessionState.Path.GetUnresolvedProviderPathFromPSPath($OutputFolder)
    $OutputPath = Join-Path $OutputFolder "$(Get-Date -Format 'yyyyMMdd_HHmmss')_bomradar.gif"

    $Magick = (Get-Command magick -CommandType Application -ErrorAction Stop).Source
    $RadarUrl = 'ftp://ftp.bom.gov.au/anon/gen/radar/'
    $OverlayUrl = 'ftp://ftp.bom.gov.au/anon/gen/radar_transparencies/'
    $TempPath = Join-Path ([IO.Path]::GetTempPath()) ([guid]::NewGuid().ToString())

    $Client = $null

    try {
        New-Item -Path $TempPath -ItemType Directory -Force | Out-Null
        $Client = [System.Net.WebClient]::new()
        $Client.Credentials = [System.Net.NetworkCredential]::new('anonymous', 'anonymous@example.com')

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
            throw "Not enough radar frames found for $ProductId (found $($Files.Count); need at least 2)."
        }

        if ($Files.Count -lt $FrameCount) {
            Write-Warning "Only $($Files.Count) radar frames are available for $ProductId; requested $FrameCount."
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

        New-Item -Path $OutputFolder -ItemType Directory -Force | Out-Null

        $GifPath = Join-Path $TempPath 'radar.gif'
        & $Magick -delay $Delay -loop 0 @FramePaths $GifPath

        if ($LASTEXITCODE -ne 0) {
            throw 'ImageMagick failed to generate the GIF.'
        }

        Move-Item -LiteralPath $GifPath -Destination $OutputPath -Force
        Get-Item -LiteralPath $OutputPath
    }
    finally {
        if ($null -ne $Client) {
            $Client.Dispose()
        }
        Remove-Item -LiteralPath $TempPath -Recurse -Force -ErrorAction SilentlyContinue
    }
}
