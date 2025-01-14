function Get-BTWildcardRecord {
    [CmdletBinding()]
    param (
        [Parameter()]
        [array]$Domains
    )

    if ($null -eq $Domains) {
        $Domains = Get-BTTarget
    }

    $WildcardRecordList = @()
    foreach ($domain in $Domains) {
        $RRTypes = @('HInfo','Afsdb','Atma','Isdn','Key','Mb','Md','Mf','Mg','MInfo','Mr','Mx','NsNxt','Rp','Rt','Wks','X25','A',
        'AAAA','CName','Ptr','Srv','Txt','Wins','WinsR','Ns','Soa','NasP','NasPtr','DName','Gpos','Loc','DhcId','Naptr','RRSig',
        'DnsKey','DS','NSec','NSec3','NSec3Param','Tlsa')
        $WildcardExists = $false
        foreach ($rrtype in $RRTypes) {
            # Find a valid DC from $domain and get its resource record
            $DCs = (Get-ADDomain -Identity $domain).ReplicaDirectoryServers
            foreach ($DC in $DCs) {
                if (Test-WSMan -ComputerName $DC -ErrorAction SilentlyContinue) {
                    $ValidDC = $DC
                    break
                }
            }

            if (-Not $ValidDC) {$ValidDC = $domain}
            if (Get-DnsServerResourceRecord -ComputerName $ValidDC -ZoneName $domain -RRType $rrtype -Name '*' -ErrorAction Ignore) {
                $WildcardExists = $true
                $ActualRRType = $rrtype
            }
        }

        if ($WildcardExists -eq $true) {
            $AddToList = [PSCustomObject]@{
                'Domain'           = $domain
                'Wildcard Exists?' = $true
                'Wildcard Type'    = $ActualRRType
            } 
        } else {
            $AddToList = [PSCustomObject]@{
                'Domain'           = $domain
                'Wildcard Exists?' = $false
                'Wildcard Type'    = 'N/A'
            }
        }
        
        $WildcardRecordList += $AddToList
    }

    $WildcardRecordList
}
