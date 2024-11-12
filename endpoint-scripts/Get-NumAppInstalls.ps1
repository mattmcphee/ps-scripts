# $collectionName = 'BMD - Consulting - Civil*'
# $applicationName = 'Vehicle Tracking 2022'
# $depDetails = Get-CMDeployment -CollectionName $collectionName -SoftwareName $applicationName
# $appDep = Get-CMApplicationDeployment -DeploymentID $depDetails.DeploymentID
# $appDepSummary = Get-CMApplicationDeploymentStatus -InputObject $appDep
# $configItem = Get-CMConfigurationItem -Fast -Id $appDepSummary[0].AppCI
# $appDepStatusDetails = Get-CMDeploymentStatusDetails -InputObject $appDepSummary[0]

# Function to convert StatusType integer to description
Function Get-CmStatusType ($statusNumber) {
    switch ($statusNumber) {
        1 {$getStatusDesc = "Success"}
        2 {$getStatusDesc = "InProgress"}
        3 {$getStatusDesc = "RequirementsNotMet"}
        4 {$getStatusDesc = "Unknown"}
        5 {$getStatusDesc = "Error"}
        Default {$getStatusDesc = $statusNumber}
    }
    return $getStatusDesc
}

# Connect to ConfigurationManager - Requires Console to be installed
# Refer to Getting Started article for more information how to configure the module
# https://learn.microsoft.com/en-us/powershell/sccm/overview?view=sccm-ps
Update-FormatData "C:\sources\mecmFormats.ps1xml"
Set-Location A00:

# Targeted Collection & Software Name
$collectionName = "BMD - Consulting - Civil*"
$applicationName = "Vehicle Tracking 2022"

# Get Per-Server Deployment Details by Collection Name
# $deploymentDetails = Get-CMDeployment -CollectionName $collectionName -SoftwareName $applicationName
$appDeployment = Get-CMApplicationDeployment -ApplicationName $applicationName
$appDeploymentStatus = $appDeployment | Get-CMApplicationDeploymentStatus
$deploymentStatusDetails = $appDeploymentStatus | Get-CMDeploymentStatusDetails
$deploymentStatusDetails | Select-Object DeviceName, IsCompliant, StatusTime, @{expression = {Get-CmStatusType $_.StatusType}; label="StatusType"}, StatusDescription, AssignmentName | Format-Table

