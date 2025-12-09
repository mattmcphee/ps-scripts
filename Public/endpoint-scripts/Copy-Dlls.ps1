function Copy-Dlls {
    [CmdletBinding()]
    param (
        # DestinationFolder
        [Parameter(Mandatory)]
        [string]
        $DestinationFolder,
        # RemoteMachineFolder
        [Parameter(Mandatory)]
        [string]
        $RemoteMachineDllUncFolder
    )
    
    if (-not (Test-Path -Path $DestinationFolder -PathType Container)) {
        New-Item -Path $DestinationFolder -ItemType Directory -Force
    }

    $dymoDlls = Get-ChildItem -Path "$RemoteMachineDllUncFolder\*.dll" -File

    if ($dymoDlls.Count -lt 1) {
        throw "No dlls were found in this folder. Ya dun goofed!"
    }

    $dymoDlls | Copy-Item -Destination $DestinationFolder -Force 
}
