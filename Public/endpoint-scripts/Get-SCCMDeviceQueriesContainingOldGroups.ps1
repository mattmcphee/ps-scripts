function Get-SCCMQueriesContainingOldGroups {
    $groupList = @(
        "GW_ANZ_Online_cgs",
        "gw_microsoft_office_2007_deny_gs",
        "GW_IBM_Tivoli_CDP_ugs",
        "GW_GFI_Endpoint_Security_gs",
        "GW_BMD_Terminal_Server_gs",
        "CM_Jobpac_PR_usg",
        "CM_Asta_POBM_GS",
        "CM_Jobpac_PB_gs",
        "CM_Jobpac_TC_gs",
        "CM_Asta_PowerProject_gs",
        "CM_Asta_BMD_gs",
        "CM_Asta_Transcity_gs",
        "CM_Jobpac_T2_gs",
        "CM_IBM_Tivoli_Fastback_Workstations_gs",
        "CM_Asta_Tilos_gs",
        "CM_Expert_Terminal_server_gs",
        "CM_IBM_Iseries_Access_File_transfer_gs",
        "CM_ANZ_Gemsafe_64bit_gs",
        "CM_Estate_Master_gs",
        "CM_Asta_4178_gs",
        "CM_Asta_J005_gs",
        "CM_Exactal_CostX_gs",
        "ADLSCCM01_Administrators",
        "ADLSCCM02_Administrators",
        "au_computers_sccm_2012_deny_group_policy",
        "au_it_laps_authorized_decryptors_au_computers_sccm_2012_usg",
        "au_it_level_2_sccm_sql_ro_access_usg",
        "_Administrators",
        "BNESCCM01_Administrators",
        "BNESCCM02_Administrators",
        "BNESCCM03_Administrators",
        "BNESCCM04_Administrators",
        "BNESCCM05_Administrators",
        "BNESCCM10_Administrators",
        "certificate_template_SCCMBootMediaCertificate-1YearValidity_usg",
        "certificate_template_SCCMClient-5YearValidity_gs",
        "certificate_template_SCCMClientDPCertificate-5Year_gs",
        "certificate_template_SCCMWebServerCertificate-5YearValidity_gs",
        "gp_firewall_server_SCCM_DP_usg",
        "gp_firewall_server_SCCM_MP_usg",
        "LONSCCM01_Administrators ",
        "MELSCCM01_Administrators",
        "MELSCCM02_Administrators",
        "MNLSCCM01_Administrators",
        "PERSCCM01_Administrators",
        "POBSCCM01_Administrators",
        "sccm_jobpac_gs",
        "Scope-OU-au_computers_sccm_2012_usg",
        "share_sccm_captured_os_full_gs",
        "share_sccm_captured_os_modify_gs",
        "share_sccm_captured_os_read_gs",
        "share_sccm_drivers_modify_usg",
        "share_sccm_drivers_owner_usg",
        "share_sccm_drivers_read_usg",
        "share_sccm_osd_logs_modify_gs",
        "share_sccm_packages_modify_usg",
        "share_sccm_packages_owner_usg",
        "share_sccm_packages_read_usg",
        "SYDSCCM01_Administrators",
        "SYDSCCM02_Administrators",
        "TSVSCCM01_Administrators",
        "TSVSCCM02_Administrators",
        "AgentEdition0"
    )

    $logPath = "C:\sources\logs\old-endpoint-groups.log"

    # import the csv into memory
    $deviceQueries = Import-Csv -Path "C:\sources\csv\sccm-device-queries.csv"

    $queriesContainingGroup = @()

    # loop through each group in the list and see if it's mentioned in queries
    foreach ($group in $groupList) {
        Write-Log -Path $logPath -Message "Group: $group"

        foreach ($query in $deviceQueries.Query) {
            if ($query.Contains($group)) {
                $queriesContainingGroup += [PSCustomObject]@{
                    Query = $query
                }
            }
        }
    }

    $queriesContainingGroup | Export-Csv -Path "C:\sources\csv\sccm-queries-containing-group.csv" -NoTypeInformation -Force

    Write-Log -Path $logPath -Message "=== Script completed! ==="
}
