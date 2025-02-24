function New-IntuneAppControlPolicy {
    [CmdletBinding()]
    param (
        # Required parameter for policy name
        [Parameter(Mandatory = $true)]
        [string]$DisplayName,

        # Path to the custom policy XML file
        [Parameter(Mandatory = $true)]
        [ValidateScript({Test-Path $_})]
        [string]$PolicyXmlPath,

        # Optional description with empty default
        [Parameter(Mandatory = $false)]
        [string]$Description = ""
    )

    # Check if required module is installed
    if (-not (Get-Module -Name Microsoft.Graph.Beta.DeviceManagement -ListAvailable)) {
        Write-Error "Microsoft.Graph.Beta.DeviceManagement module is required."
        Write-Error "Please install it using 'Install-Module -Name Microsoft.Graph.Beta.DeviceManagement'."
        return
    }

    # Import the module
    Import-Module Microsoft.Graph.Beta.DeviceManagement

    try {
        # Read the XML file and convert to base64
        $policyXml = Get-Content -Path $PolicyXmlPath -Raw
        $policyBase64 = [Convert]::ToBase64String([System.Text.Encoding]::UTF8.GetBytes($policyXml))

        # find the policy template
        $policyTemplates = Get-MgBetaDeviceManagementConfigurationPolicyTemplate
        $policyTemplate = $policyTemplates | Where-Object { $_.Name -eq "Application Control Template" }
        $policyTemplateId = $policyTemplate.Id

        # construct the uri for fetching template IDs
        $uri = "https://graph.microsoft.com/beta/deviceManagement/configurationPolicies('$policyTemplateId')?`$expand=settings"

        # fetch the policy details with expanded settings
        $template = Invoke-MgGraphRequest -Method GET -Uri $uri |
        Select-Object -Property name, description, settings, platforms, technologies, templateReference
        $templateJson = $template | ConvertTo-Json -Depth 100
        $RAWJson = $templateJson

        # get all configuration policies
        $intunePolicies = Get-MgBetaDeviceManagementConfigurationPolicy -All

        # find policy with name

        # Create hashtable for policy parameters
        $params = @{
            '@odata.type' = "#microsoft.graph.windowsDefenderApplicationControl"
            DisplayName = $DisplayName
            Description = $Description
            PolicyContent = $policyBase64
        }

        # Create the policy using Graph API
        $response = New-MgBetaDeviceManagementConfigurationPolicy -BodyParameter $params
        Write-Output $response  # Return the created policy object
    } catch {
        Write-Error "Failed to create app control policy: $_"  # Error handling
    }
}
