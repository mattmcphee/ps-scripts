$source = Join-Path $PSScriptRoot 'src'
$output = Join-Path $PSScriptRoot 'ps-scripts.psm1'

$content = @(
    '# ============================================================================'
    '# GENERATED FILE - DO NOT EDIT'
    '# Run .\build.ps1 to regenerate this file from .\src'
    "# This file was built on $((Get-Date).ToString("dd-MMM-yyyy HH:mm:ss"))"
    '# ============================================================================'
    ''
)

$files = @(
    Get-ChildItem "$source\Private\*.ps1" -Recurse
    Get-ChildItem "$source\Public\*.ps1" -Recurse
)

foreach ($file in $files) {
    $content += "#region $($file.Name)"
    $content += Get-Content $file.FullName -Raw
    $content += "#endregion"
    $content += ''
}

$content -join "`r`n" | Set-Content $output -Encoding UTF8
