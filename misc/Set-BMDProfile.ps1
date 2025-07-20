function Set-BMDProfile {
    Rename-Item -Path "$env:USERPROFILE\Documents\PowerShell\profileBMD.ps1" -NewName "profile.ps1"
    Rename-Item -Path "$env:USERPROFILE\Documents\WindowsPowerShell\profileBMD.ps1" -NewName "profile.ps1"
}
