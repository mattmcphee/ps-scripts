function Get-WindowsUpdates {
    $searcher = (New-Object -ComObject 'Microsoft.Update.Session').CreateUpdateSearcher()
    $result = $searcher.Search('IsInstalled=0 and IsHidden=0')

    foreach ($update in $result.Updates) {
        [PSCustomObject]@{
            Title          = $update.Title
            Description    = $update.Description
            KB             = ($update.KBArticleIDs | ForEach-Object { "KB$_" }) -join ', '
            Severity       = $update.MsrcSeverity
            Categories     = ($update.Categories | ForEach-Object { $_.Name }) -join ', '
            MaxSizeMB      = [math]::Round($update.MaxDownloadSize / 1MB, 2)
            IsDownloaded   = $update.IsDownloaded
            IsMandatory    = $update.IsMandatory
            RebootRequired = $update.RebootRequired
            ReleaseDate    = $update.LastDeploymentChangeTime
        }
    }
}
