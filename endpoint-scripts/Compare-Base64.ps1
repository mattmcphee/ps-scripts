$executionTime = Measure-Command {
    $imagePath = "C:\sources\bmd-wallpaper-base64.txt"
    $correctBase64String = Get-Content $imagePath

    $localImagePath = "C:\sources\BMD.jpg"
    $localImageBytes = [System.IO.File]::ReadAllBytes($localImagePath)
    $localBase64String = [Convert]::ToBase64String($localImageBytes)

    if ($correctBase64String -eq $localBase64String) {
        Write-Host "Image base64 string has correct value. Local image is the same as image on file share."
    } else {
        Write-Host "Image base64 string does not have correct value. Local image is NOT the same as image on file share."
    }
}

$executionTime

