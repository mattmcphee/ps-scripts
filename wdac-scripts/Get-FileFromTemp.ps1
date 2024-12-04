# where we will move the file once it is free
$destination = "C:\sources\"

$watcher = New-Object System.IO.FileSystemWatcher
$watcher.Path = "C:\Users\MATTES4\AppData\Local\Temp\"
$watcher.Filter = "*StdUtils*"
$watcher.IncludeSubdirectories = $true
$watcher.EnableRaisingEvents = $true

$action = {
    $path = $Event.SourceEventArgs.FullPath
    $changeType = $Event.SourceEventArgs.ChangeType
    $logline = "$(Get-Date -f o), $changeType, $path"
    Add-Content "C:\sources\log.txt" -Value $logline
    Write-Host $logline

    # if($changeType -eq "Renamed" -and $path.Split(".")[-1] -ne "crdownload") {
    #     Write-Host -ForegroundColor Green "Found the file we need! $path"
    #     Add-content "C:\log.txt" -value "Found the file we need! $path"
    #     $global:files += $path
    # }

    if ($changeType -eq "Created") {
        Move-Item -Path $path -Destination $destination -Force
        Add-Content "C:\sources\log.txt" -Value "Attempted to move item: $path to $destination"
    }
}

Register-ObjectEvent $watcher "Created" -Action $action
# Register-ObjectEvent $watcher "Changed" -Action $action
# Register-ObjectEvent $watcher "Deleted" -Action $action
# Register-ObjectEvent $watcher "Renamed" -Action $action

# while ($true) {

#     # if there are any files to process, check if they are locked
#     if($global:files) {

#         $global:files | % {

#             $file = $_
#             # assume the file is locked
#             $fileFree = $false

#             Write-Host -ForegroundColor Yellow "Checking if the file is locked... ($file)"
#             Add-content "C:\log.txt" -value "Checking if the file is locked... ($_)"

#             # true  = file is free
#             # false = file is locked
#             try {
#                 [IO.File]::OpenWrite($file).close();Write-Host -ForegroundColor Green "File is free! ($file)"
#                 Add-content "C:\log.txt" -value "File is free! ($file)"
#                 $fileFree = $true
#             }
#             catch {
#                 Write-Host -ForegroundColor Red "File is Locked ($file)"
#                 Add-content "C:\log.txt" -value "File is Locked ($file)"
#             }

#             if($fileFree) {

#                 # do what we want with the file, since it is free
#                 Move-Item $file $destination
#                 Write-Host -ForegroundColor Green "Moving file ($file)"
#                 Add-content "C:\log.txt" -value "Moving file ($file)"

#                 # make sure we don't progress until the file has finished moving
#                 while(Test-Path $file) {
#                     Sleep 1
#                 }

#                 # remove the current file from the array
#                 Write-Host -ForegroundColor Green "Done processing this file. ($file)"
#                 Add-content "C:\log.txt" -value "Done processing this file. ($file)"
#                 $global:files = $global:files | ? { $_ -ne $file }
#             }

#         }
#     }

#     sleep 2
# }