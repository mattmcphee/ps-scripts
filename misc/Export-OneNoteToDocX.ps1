# Requires the OneNote desktop application to be running
# Run this script with a user account that has access to the OneNote notebooks

Add-Type -AssemblyName "Microsoft.Office.Interop.OneNote"

$oneNoteApp = New-Object -ComObject OneNote.Application

# Define your export settings
$exportPath = "C:\OneNoteExports" # Change this to your desired export directory
$format = [Microsoft.Office.Interop.OneNote.PublishFormat]::pfWord # Export as .docx

# Ensure the export directory exists
if (-not (Test-Path $exportPath)) {
    New-Item -Path $exportPath -ItemType Directory -Force
}

# Get the XML hierarchy of all OneNote notebooks
$hierarchyXml = ""
$oneNoteApp.GetHierarchy("", [Microsoft.Office.Interop.OneNote.HierarchyScope]::hsNotebooks, [ref]$hierarchyXml)

# Load the XML into an XML object for easier parsing
$xmlDoc = [xml]$hierarchyXml

# Loop through each Notebook
foreach ($notebook in $xmlDoc.OneNote.Notebooks.Notebook) {
    Write-Host "Processing Notebook: $($notebook.name)"
    $notebookPath = Join-Path $exportPath $($notebook.name)
    if (-not (Test-Path $notebookPath)) {
        New-Item -Path $notebookPath -ItemType Directory -Force
    }

    # Get sections within this notebook
    $sectionHierarchyXml = ""
    $oneNoteApp.GetHierarchy($notebook.ID, [Microsoft.Office.Interop.OneNote.HierarchyScope]::hsSections, [ref]$sectionHierarchyXml)
    $sectionXmlDoc = [xml]$sectionHierarchyXml

    # Loop through each Section (and optionally Section Groups)
    foreach ($sectionNode in $sectionXmlDoc.SelectSingleNode("//Sections").ChildNodes) {
        if ($sectionNode.Name -eq "Section") {
            $section = $sectionNode
            Write-Host "`tProcessing Section: $($section.name)" -ForegroundColor Cyan
            $sectionCleanName = $($section.name -replace "[\\/:*?`"<>()|]", "_") # Clean section name for folder path
            $sectionPath = Join-Path $notebookPath $sectionCleanName
            if (-not (Test-Path $sectionPath)) {
                New-Item -Path $sectionPath -ItemType Directory -Force
            }

            # Get pages within this section
            $pageHierarchyXml = ""
            $oneNoteApp.GetHierarchy($section.ID, [Microsoft.Office.Interop.OneNote.HierarchyScope]::hsPages, [ref]$pageHierarchyXml)
            $pageXmlDoc = [xml]$pageHierarchyXml

            # Loop through each Page
            foreach ($page in $pageXmlDoc.SelectSingleNode("//Pages").Page) {
                Write-Host "`t`tExporting Page: $($page.name)" -ForegroundColor Green

                # Clean page name for filename
                $pageCleanName = $($page.name -replace "[\\/:*?`"<>()|]", "_")
                $outputFilePath = Join-Path $sectionPath "$pageCleanName.docx"

                # Export the page
                try {
                    $oneNoteApp.Publish($page.ID, $outputFilePath, $format, "")
                    Write-Host "`t`t-> Exported to $outputFilePath" -ForegroundColor DarkGreen
                } catch {
                    Write-Error "Error exporting page '$($page.name)': $($_.Exception.Message)"
                }
            }
        } elseif ($sectionNode.Name -eq "SectionGroup") {
            # You can extend this script to handle Section Groups if needed
            # This would require another nested GetHierarchy call
            Write-Warning "Skipping Section Group: $($sectionNode.name). Script not configured to export nested section groups."
        }
    }
}

Write-Host "OneNote export process complete!" -ForegroundColor Yellow

# Release the COM object
[System.Runtime.InteropServices.Marshal]::ReleaseComObject($oneNoteApp) | Out-Null
Remove-Variable oneNoteApp
