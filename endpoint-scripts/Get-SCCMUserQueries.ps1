function Get-SCCMUserQueries {
    $logPath = "C:\sources\logs\Get-SCCMUserQueries.log"

    $collections = Get-CMUserCollection | Select-Object Name, CollectionID

    $results = @()

    foreach ($collection in $collections) {
        Write-Log -Path $logPath -Message "Collection: $($collection.Name)"

        # get all membership rules
        $rules = Get-CMCollectionQueryMembershipRule -CollectionId $collection.CollectionID

        foreach ($rule in $rules) {
            Write-Log -Path $logPath -Message "Rule Name: $($rule.RuleName)"
            Write-Log -Path $logPath -Message "Query: $($rule.QueryExpression)"

            $result = [PSCustomObject]@{
                "Collection" = $collection.Name
                "RuleName"   = $rule.RuleName
                "Query"      = $rule.QueryExpression
            }

            $results += $result
        }
    }

    $results | Export-Csv -Path "C:\sources\csv\sccm-user-queries.csv" -NoTypeInformation
}
