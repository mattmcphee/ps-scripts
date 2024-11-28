function New-WDACRulesFromEventLogs {
    [CmdletBinding()]
    param (
        # policy filepath to put rules into
        [Parameter(Mandatory=$true)]
        [string]
        $SuppPolicyPath,
        # minutes to look back in time
        [ValidatePattern('^[0-9]+$')]
        [Parameter(Mandatory=$true)]
        [string]
        $MinutesAgo,
        # id value to start from
        [Parameter(Mandatory=$true)]
        [int]
        $IdStart
    )
    # testing
    # $MinutesAgo = 900
    # $SuppPolicyPath = 'C:\sources\rules.xml'

    # 1. get codeintegrity events with event ID 3077 and timecreated greater
    # than negative minutes ago
    
    $events = Get-WinEvent -LogName 'Microsoft-Windows-CodeIntegrity/Operational' |
    Where-Object {
        ($_.id -eq '3077') -and ($_.timecreated -gt (get-date).addminutes(-$MinutesAgo))
    }

    # 2. foreach event, get the process name, filename, file sha1 hash and
    # file sha256 hash
    foreach ($CIEvent in $events) {
        [xml]$eventXml = $CIEvent.ToXml()
        $eventData = $eventXml.Event.EventData.Data
        $fileName = $eventData | Where-Object {$_.Name -like 'File Name'}
        $fileNameValue = $fileName.'#text'
        $sha1Hash = $eventData | Where-Object {$_.Name -like 'SHA1 Hash'}
        $sha1HashValue = $sha1Hash.'#text'
        $sha256Hash = $eventData | Where-Object {$_.Name -like 'SHA256 Hash'}
        $sha256HashValue = $sha256Hash.'#text'
    
        # 3. output hash rules in xml format to a file
        $sha1Rule = "<Allow ID=`"ID_ALLOW_A_$($idStart)_0`" FriendlyName=`"$($fileNameValue) Hash Sha1`" Hash=`"$($sha1HashValue)`" />"
        $sha1RuleRef = "<FileRuleRef RuleID=`"ID_ALLOW_A_$($idStart)_0`" />"
        $idStart++
        $sha256Rule = "<Allow ID=`"ID_ALLOW_A_$($idStart)_0`" FriendlyName=`"$($fileNameValue) Hash Sha256`" Hash=`"$($sha256HashValue)`" />"
        $sha256RuleRef = "<FileRuleRef RuleID=`"ID_ALLOW_A_$($idStart)_0`" />"
        $idStart++

        $sha1Rule | Out-File -Append -FilePath $SuppPolicyPath -Force
        $sha256Rule | Out-File -Append -FilePath $SuppPolicyPath -Force
        $sha1RuleRef | Out-File -Append -FilePath $SuppPolicyPath -Force
        $sha256RuleRef | Out-File -Append -FilePath $SuppPolicyPath -Force
    }
}