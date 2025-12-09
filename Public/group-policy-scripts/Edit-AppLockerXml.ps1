function Edit-AppLockerXml {
    for ($i = 0; $i -lt $denyPaths.Count; $i++) {
        $denyApps.AppLockerPolicy.RuleCollection.filepathrule[$i].id = $((new-guid).tostring())
        $denyApps.AppLockerPolicy.RuleCollection.filepathrule[$i].name = "BypassAppControlApps: $($denyPaths[$i])"
        $denyApps.AppLockerPolicy.RuleCollection.filepathrule[$i].conditions.filepathcondition.path = "*\$($denyPaths[$i])"
    }
}
