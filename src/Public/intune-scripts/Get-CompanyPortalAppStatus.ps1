function Get-CompanyPortalAppStatus {
    [CmdletBinding()]
    param (
        # ComputerName
        [Parameter(Mandatory=$false)]
        [string]$ComputerName = $env:COMPUTERNAME,

        # AppId
        [Parameter(Mandatory)]
        [string]$AppId
    )

    $results = Invoke-Command -ComputerName $ComputerName -ArgumentList $AppId,$ComputerName -ScriptBlock {
        $appId = $using:AppId
        $computerName = $using:ComputerName
        $regPath = "HKLM:\SOFTWARE\Microsoft\IntuneManagementExtension\Win32Apps\Reporting\00000000-0000-0000-0000-000000000000"

        $reportingState = Get-ChildItem $regPath | Where-Object PSChildName -eq $appId

        if ($null -eq $reportingState) {
            throw "Could not find any status for app with ID '$appId' on computer '$computerName'"
        }

        $reportingState | Get-ItemProperty | Select-Object -ExpandProperty ReportingState | ConvertFrom-Json
    }

    $results
}
