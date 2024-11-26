function Get-BTWPADRecord {
    [CmdletBinding()]
    param (
        [Parameter()]
        [array]$Domains
    )

    if ($null -eq $Domains) {
        $Domains = Get-BTTarget
    }

    $WPADRecordList = @()
    foreach ($domain in $Domains) {
        $RRTypes = @('HInfo','Afsdb','Atma','Isdn','Key','Mb','Md','Mf','Mg','MInfo','Mr','Mx','NsNxt','Rp','Rt','Wks','X25','A',
        'AAAA','CName','Ptr','Srv','Txt','Wins','WinsR','Ns','Soa','NasP','NasPtr','DName','Gpos','Loc','DhcId','Naptr','RRSig',
        'DnsKey','DS','NSec','NSec3','NSec3Param','Tlsa')
        $WPADExists = $false
        foreach ($rrtype in $RRTypes) {
            # Find a valid DC from $domain and get it's resource record
            $DCs = (Get-ADDomain -Identity $domain).ReplicaDirectoryServers
            foreach ($DC in $DCs) {
                if (Test-WSMan -ComputerName $DC -ErrorAction SilentlyContinue) {
                    $ValidDC = $DC
                    break
                }
            }

            if (-Not $ValidDC) {$ValidDC = $domain}
            if (Get-DnsServerResourceRecord -ComputerName $ValidDC -ZoneName $domain -RRType $rrtype -Name 'wpad' -ErrorAction Ignore) {
                $WPADExists = $true
                $ActualRRType = $rrtype
            }
        }

        if ($WPADExists -eq $true) {
            $AddToList = [PSCustomObject]@{
                'Domain'           = $domain
                'WPAD Exists?' = $true
                'WPAD Type'    = $ActualRRType
            } 
        } else {
            $AddToList = [PSCustomObject]@{
                'Domain'           = $domain
                'WPAD Exists?' = $false
                'WPAD Type'    = 'N/A'
            }
        }
        
        $WPADRecordList += $AddToList
    }

    $WPADRecordList
}