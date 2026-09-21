$moduleName = 'ps-scripts'
$source = Join-Path $PSScriptRoot 'src'
$moduleFile = Join-Path $PSScriptRoot "$moduleName.psm1"
$manifestFile = Join-Path $PSScriptRoot "$moduleName.psd1"
$privateFilter = "$source\Private\*.ps1"
$publicFilter = "$source\Public\*.ps1"

$psm1Content = @(
    '# ============================================================================'
    '# GENERATED FILE - DO NOT EDIT'
    '# Run .\build.ps1 to regenerate this file from .\src'
    "# This file was built on $((Get-Date).ToString("dd-MMM-yyyy HH:mm:ss"))"
    '# ============================================================================'
    ''
)

$files = @(
    Get-ChildItem $privateFilter -Recurse
    Get-ChildItem $publicFilter -Recurse
)

foreach ($file in $files) {
    $psm1Content += "#region $($file.Name)"
    $psm1Content += Get-Content $file.FullName -Raw
    $psm1Content += "#endregion"
    $psm1Content += ''
}

# specifically export only public functions via export-modulemember
$public = (Get-ChildItem $publicFilter -Recurse).BaseName
$psm1Content += "#region Export Functions"
$psm1Content += "Export-ModuleMember -Function @(`r`n    '$($public -join "'`r`n    '")'`r`n)"
$psm1Content += "#endregion"
$psm1Content -join "`r`n" | Set-Content $moduleFile -Encoding UTF8

# target the FunctionsToExport line and add public functions to it
Update-ModuleManifest -Path $manifestFile -FunctionsToExport $public
