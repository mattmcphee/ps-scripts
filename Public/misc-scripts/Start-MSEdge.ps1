function Start-MSEdge {
    [CmdletBinding()]
    param (
        # FilePath
        [Parameter(Mandatory=$false,ValueFromPipeline)]
        [ValidateScript({ Test-Path $_ })]
        [string[]]
        $FilePath
    )
    
    begin {
        $edgePath = "${env:ProgramFiles(x86)}\Microsoft\Edge\Application\msedge.exe"
        if (-not (Test-Path $edgePath)) {
            throw "Could not find msedge.exe at $edgePath"
        }
    }
    
    process {
        if ($FilePath) {
            foreach ($path in $FilePath) {
                Start-Process 'msedge' -ArgumentList $path -Wait
            }
        } else {
            Start-Process 'msedge' -Wait
        }
    }
    
    end {
        
    }
}