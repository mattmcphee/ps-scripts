$symlinkSitePackageSource = "C:\Users\MATMCP1\Appdata\Roaming\Blender Foundation\Blender\4.5\extensions\.local\lib\python3.11\site-packages"
$symlinkSitePackageTarget = "$env:PROGRAMFILES\Blender Foundation\Blender 4.5\site-packages"

$symlinkBlenderOrgSource = "C:\Users\MATMCP1\Appdata\Roaming\Blender Foundation\Blender\4.5\extensions\blender_org"
$symlinkBlenderOrgTarget = "$env:PROGRAMFILES\Blender Foundation\Blender 4.5\blender_org"

if (Test-Path -Path $symlinkSitePackageSource) {
    Rename-Item -Path $symlinkSitePackageSource -NewName "$symlinkSitePackageSource-BACKUP"
}

if (-not (Test-Path -Path $symlinkSitePackageTarget)) {
    New-Item -ItemType Directory -Path $symlinkSitePackageTarget -Force
}

if (Test-Path -Path $symlinkBlenderOrgSource) {
    Rename-Item -Path $symlinkBlenderOrgSource -NewName "$symlinkBlenderOrgSource-BACKUP"
}

if (-not (Test-Path -Path $symlinkBlenderOrgTarget)) {
    New-Item -ItemType Directory -Path $symlinkBlenderOrgTarget -Force
}

New-Item -ItemType SymbolicLink -Path $symlinkSitePackageSource -Target $symlinkSitePackageTarget
New-Item -ItemType SymbolicLink -Path $symlinkBlenderOrgSource -Target $symlinkBlenderOrgTarget
