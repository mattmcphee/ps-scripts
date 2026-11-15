# Requires Pester and ImageMagick 7. Run in a separate PowerShell process: the FTP
# fixture registers an in-memory handler for BOM requests for that process.
. "$PSScriptRoot/../src/Public/misc-scripts/Get-BOMRadarGif.ps1"
$MagickPath = (Get-Command magick -CommandType Application -ErrorAction Stop).Source

if (-not ('BomRadarTests.Request' -as [type])) {
    Add-Type -IgnoreWarnings -WarningAction SilentlyContinue -TypeDefinition @'
using System;
using System.Collections.Generic;
using System.IO;
using System.Net;

namespace BomRadarTests {
    public class Factory : IWebRequestCreate {
        public WebRequest Create(Uri uri) { return new Request(uri); }
    }

    public class Request : WebRequest {
        public static readonly Dictionary<string, byte[]> Files =
            new Dictionary<string, byte[]>(StringComparer.Ordinal);
        public static readonly List<string> Downloads = new List<string>();
        private readonly Uri uri;
        public Request(Uri uri) { this.uri = uri; }
        public bool UseBinary { get; set; }
        public bool UsePassive { get; set; }
        public override string Method { get; set; }
        public override ICredentials Credentials { get; set; }
        public override IWebProxy Proxy { get; set; }
        public override Uri RequestUri { get { return uri; } }
        public override void Abort() { }
        public override WebResponse GetResponse() {
            Downloads.Add(uri.AbsolutePath);
            byte[] bytes;
            if (!Files.TryGetValue(uri.AbsolutePath, out bytes))
                throw new WebException("Fixture file not found: " + uri.AbsolutePath);
            return new Response(uri, bytes);
        }
    }

    public class Response : WebResponse {
        private readonly Uri uri;
        private readonly byte[] bytes;
        private readonly MemoryStream stream;
        public Response(Uri uri, byte[] bytes) {
            this.uri = uri;
            this.bytes = bytes;
            stream = new MemoryStream(bytes);
        }
        public override long ContentLength { get { return bytes.Length; } }
        public override Uri ResponseUri { get { return uri; } }
        public override WebHeaderCollection Headers { get { return new WebHeaderCollection(); } }
        public override Stream GetResponseStream() { return stream; }
        public override void Close() { stream.Dispose(); }
    }
}
'@
    $null = [Net.WebRequest]::RegisterPrefix('ftp://ftp.bom.gov.au/', [BomRadarTests.Factory]::new())
}

Describe 'Get-BOMRadarGif' {
    BeforeAll {
        $script:Images = @{}
        foreach ($Color in 'none', 'white', 'red', 'lime', 'blue') {
            $ImagePath = Join-Path $TestDrive "$Color.png"
            & $MagickPath -size 2x2 "xc:$Color" "PNG32:$ImagePath"
            if ($LASTEXITCODE -ne 0) { throw 'Could not create test images.' }
            $script:Images[$Color] = [IO.File]::ReadAllBytes($ImagePath)
        }
    }

    BeforeEach {
        Mock Get-Date { '20261103_120000' } -ParameterFilter { $Format -eq 'yyyyMMdd_HHmmss' }
        [BomRadarTests.Request]::Files.Clear()
        [BomRadarTests.Request]::Downloads.Clear()
        [BomRadarTests.Request]::Files['/anon/gen/radar/'] = [Text.Encoding]::UTF8.GetBytes(@"
IDR664.T.202611030010.png
IDR663.T.202611030020.png
IDR664.T.202611030000.png
IDR664.T.202611030005.png
IDR664.T.202611030015.gif
"@)
        [BomRadarTests.Request]::Files['/anon/gen/radar_transparencies/IDR664.background.png'] = $script:Images.white
        [BomRadarTests.Request]::Files['/anon/gen/radar_transparencies/IDR664.topography.png'] = $script:Images.none
        [BomRadarTests.Request]::Files['/anon/gen/radar_transparencies/IDR664.locations.png'] = $script:Images.none
        [BomRadarTests.Request]::Files['/anon/gen/radar/IDR664.T.202611030000.png'] = $script:Images.red
        [BomRadarTests.Request]::Files['/anon/gen/radar/IDR664.T.202611030005.png'] = $script:Images.lime
        [BomRadarTests.Request]::Files['/anon/gen/radar/IDR664.T.202611030010.png'] = $script:Images.blue
        $script:WorkDirectories = @()
        Mock New-Item {
            param($Path)
            $null = [IO.Directory]::CreateDirectory($Path)
            if ($script:WorkDirectories.Count -eq 0) {
                $script:WorkDirectories += $Path
            }
        } -ParameterFilter { $ItemType -eq 'Directory' }
    }

    AfterEach {
        foreach ($Directory in $script:WorkDirectories) {
            Test-Path -LiteralPath $Directory | Should Be $false
        }
    }

    It 'selects the newest frames, composes oldest first, rounds delay, and loops forever' {
        $Result = Get-BOMRadarGif -FrameCount 2 -DelayMs 555 -OutputFolder "$TestDrive/ordered"
        $Result -is [IO.FileInfo] | Should Be $true
        @($Result).Count | Should Be 1
        (& $MagickPath identify -format '%m %T\n' $Result.FullName) -join ';' | Should Be 'GIF 56;GIF 56'
        (& $MagickPath $Result.FullName -format '%[pixel:p{0,0}]\n' info:) -join ';' |
            Should Be 'srgb(0,255,0);srgb(0,0,255)'
        (& $MagickPath identify -verbose $Result.FullName) -join "`n" | Should Match 'Iterations: 0'
        ([BomRadarTests.Request]::Downloads | Where-Object { $_ -match '/radar/.+png$' }) -join ';' |
            Should Be '/anon/gen/radar/IDR664.T.202611030005.png;/anon/gen/radar/IDR664.T.202611030010.png'
    }

    It 'accepts lowercase product IDs' {
        $Result = Get-BOMRadarGif -ProductId idr664 -FrameCount 2 -OutputFolder "$TestDrive/lowercase"
        $Result.Exists | Should Be $true
    }

    It 'supports spaces and brackets in the destination and replaces an existing GIF' {
        $OutputFolder = Join-Path $TestDrive 'maps [test]'
        $Destination = Join-Path $OutputFolder '20261103_120000_bomradar.gif'
        $null = [IO.Directory]::CreateDirectory($OutputFolder)
        [IO.File]::WriteAllText($Destination, 'previous output')
        $Result = Get-BOMRadarGif -FrameCount 2 -OutputFolder $OutputFolder
        $Result.FullName | Should Be $Destination.Replace('/', [IO.Path]::DirectorySeparatorChar)
        (& $MagickPath identify -format '%m' $Result.FullName) | Should Be 'GIFGIF'
    }

    It 'writes the default output to the current directory' {
        Push-Location $TestDrive
        try {
            $Result = Get-BOMRadarGif -FrameCount 2
            Test-Path -LiteralPath (Join-Path $TestDrive $Result.Name) | Should Be $true
            $Result.Name | Should Match '^\d{8}_\d{6}_bomradar\.gif$'
        }
        finally { Pop-Location }
    }

    It 'creates a relative output folder and uses a timestamped GIF filename' {
        Push-Location $TestDrive
        try {
            $Result = Get-BOMRadarGif -FrameCount 2 -OutputFolder './new maps [test]/nested'
            $Result.Name | Should Be '20261103_120000_bomradar.gif'
            Test-Path -LiteralPath "$TestDrive/new maps [test]/nested/$($Result.Name)" | Should Be $true
        }
        finally { Pop-Location }
    }

    It 'rejects an empty output folder' {
        { Get-BOMRadarGif -OutputFolder '' -ErrorAction Stop } | Should Throw 'null or empty'
        [BomRadarTests.Request]::Downloads.Count | Should Be 0
    }

    It 'warns when fewer frames are available than requested and uses those available' {
        $Warnings = @()
        $Result = Get-BOMRadarGif -FrameCount 7 -OutputFolder "$TestDrive/short" -WarningVariable Warnings -WarningAction SilentlyContinue
        @($Warnings).Count | Should Be 1
        (& $MagickPath identify -format '%n' $Result.FullName) | Should Be '333'
    }

    It 'fails when fewer than two matching frames are available' {
        [BomRadarTests.Request]::Files['/anon/gen/radar/'] = [Text.Encoding]::UTF8.GetBytes('IDR664.T.202611030000.png')
        { Get-BOMRadarGif -OutputFolder "$TestDrive/insufficient" } | Should Throw 'need at least 2'
    }

    It 'cleans up after a failed download without replacing existing output' {
        $Destination = Join-Path $TestDrive '20261103_120000_bomradar.gif'
        [IO.File]::WriteAllText($Destination, 'previous output')
        $null = [BomRadarTests.Request]::Files.Remove('/anon/gen/radar/IDR664.T.202611030010.png')
        { Get-BOMRadarGif -FrameCount 2 -OutputFolder $TestDrive -ErrorAction Stop } | Should Throw 'Fixture file not found'
        [IO.File]::ReadAllText($Destination) | Should Be 'previous output'
    }

    It 'reports composition failures without replacing existing output' {
        $Destination = Join-Path $TestDrive '20261103_120000_bomradar.gif'
        [IO.File]::WriteAllText($Destination, 'previous output')
        [BomRadarTests.Request]::Files['/anon/gen/radar/IDR664.T.202611030005.png'] = [byte[]]@(0, 1, 2)
        $Failure = $null
        try { Get-BOMRadarGif -FrameCount 2 -OutputFolder $TestDrive -ErrorAction Stop 2>$null }
        catch { $Failure = $_ }
        ($null -ne $Failure) | Should Be $true
        [IO.File]::ReadAllText($Destination) | Should Be 'previous output'
    }

    It 'preserves existing output when GIF encoding fails after writing partial data' {
        $Destination = Join-Path $TestDrive '20261103_120000_bomradar.gif'
        [IO.File]::WriteAllText($Destination, 'previous output')
        $script:EncoderShimPath = Join-Path $TestDrive 'encoder.ps1'
        $EncoderSource = @'
if ($args[0] -eq '-delay') {
    [IO.File]::WriteAllText($args[-1], 'partial GIF')
    $global:LASTEXITCODE = 1
} else {
    & '__MAGICK__' @args
    $global:LASTEXITCODE = $LASTEXITCODE
}
'@
        Set-Content -LiteralPath $script:EncoderShimPath -Value $EncoderSource.Replace('__MAGICK__', $MagickPath.Replace("'", "''"))
        Mock Get-Command { [pscustomobject]@{ Source = $script:EncoderShimPath } } -ParameterFilter { $Name -eq 'magick' }
        { Get-BOMRadarGif -FrameCount 2 -OutputFolder $TestDrive } | Should Throw 'ImageMagick failed to generate the GIF.'
        [IO.File]::ReadAllText($Destination) | Should Be 'previous output'
    }
}
