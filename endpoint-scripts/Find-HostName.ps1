$txtFiles = Get-ChildItem "C:\temp\folders" -Recurse -File
foreach ($txtFile in $txtFiles) {
  $content = Get-Content $txtFile
  if ($content.contains("mmtask")) {
    Write-Host $txtFile
    Break
  }
}