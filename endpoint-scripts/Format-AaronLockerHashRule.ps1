function Format-AaronLockerHashRule {
    <#
    .SYNOPSIS
       Create HashRules
    .DESCRIPTION
       Create HashRules for AaronLocker HashRuleData.ps1 based on "Get-AppLockerFileInformation -Directory C:\Directory -Recurse | Export-Csv C:\FileName.csv -Encoding UTF8"
    .PARAMETER File
       Full path to the file to import
    .PARAMETER ExportLocation
       Location to export the results. The dxport location shouldn't incude final backslash as its automatically added.
    .PARAMETER Application
       Name of the Application the HashRules are for eg. "Photoshop"
    .PARAMETER Description
       Description of the HashRule eg. "for Department XYZ"
    .INPUTS
       N/A
    .OUTPUTS
       N/A
    .NOTES
       Version:        1.0
       Author:         Bryan Bultitude
       Creation Date:  22/02/2022
       Purpose/Change: 22/02/2022 - Bryan Bultitude - Initial script development
    .EXAMPLE
       PS> Format-AaronLockerHashRule -File "C:\Temp\HashFile.csv" -ExportLocation "C:\Temp" -Application "Bat Cave" -Description "for Bruce Wayne"
    .EXAMPLE
       PS> Format-AaronLockerHashRule "C:\Temp\HashFile.csv" "C:\Temp" "Bat Cave" "for Bruce Wayne"
    #>
    param (
        [Parameter(Mandatory = $true)]
        $File,
        [Parameter(Mandatory = $true)]
        $ExportLocation,
        [Parameter(Mandatory = $true)]
        $Application,
        [Parameter(Mandatory = $true)]
        $Description
    )
    $Hash = Import-Csv $File
    $outfile = "$ExportLocation\$Application - HashRules.txt"
    "#region $Application" | Out-File -FilePath $outfile
    foreach ($item in $Hash) {
        $File = Split-Path $item.Path -Leaf
        $RuleName = "$($application): $($File) - HASH RULE"
        $Desc = "$Application $Description"
        if (([System.IO.Path]::GetExtension($File)) -in ".ocx", ".dll" ) {
            $RuleType = "Dll"
        }
        elseif (([System.IO.Path]::GetExtension($File)) -in ".com", ".exe" ) {
            $RuleType = "Exe"
        }
        elseif (([System.IO.Path]::GetExtension($File)) -in ".vbs", ".js", ".ps1", ".bat", ".cmd" ) {
            $RuleType = "Script"
        }
        elseif (([System.IO.Path]::GetExtension($File)) -in ".msi", ".msp", "mst" ) {
            $RuleType = "Msi"
        }
        "@{" | Out-File -FilePath $outfile -Append
        "RuleCollection = `"$RuleType`";" | Out-File -FilePath $outfile -Append
        "RuleName = `"$RuleName`";" | Out-File -FilePath $outfile -Append
        "RuleDesc = `"$Desc`";" | Out-File -FilePath $outfile -Append
        "HashVal  = `"$($item.Hash.Split(" ")[1])`";" | Out-File -FilePath $outfile -Append
        "FileName = `"$($File)`";" | Out-File -FilePath $outfile -Append
        "}" | Out-File -FilePath $outfile -Append


    }
    "#endregion" | Out-File -FilePath $outfile -Append
}
