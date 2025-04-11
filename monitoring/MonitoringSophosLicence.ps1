# Abfrage im Monitoring:
# enthält "In Ordnung"
# enthält nicht "Fehler"
# enthält nicht "WARNUNG" (optional)


# Definiere die IP-Adresse und Community
# IP Adresse bitte anpassen
$IP = "192.168.10.1"
$CommunityName = "public"


Push-Location $PSScriptRoot

Add-Type -Path ".\SharpSnmpLib.dll"

Pop-Location


function Get-SnmpData {
    <#    
    .SYNOPSIS
        Function reading data from SNMP.

    .DESCRIPTION
        Function reads data from SNMP using library SharpSnmpLib.
        Libraries taken from project SharpSnmpLib (http://sharpsnmplib.codeplex.com).

        Die .Net Bibliothek, auf der der Zugriff basiert ist hier dokumentiert :
            https://docs.sharpsnmp.com/getting-started/index.html
        Das Powershell-Modul, welches den Code ursprünglich enthielt: 
            https://www.powershellgallery.com/packages/SNMP/1.0.0.1
    #>
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true,HelpMessage = 'Endpoint IP address')]
        [Net.IPAddress]$IP,

        [Parameter(Mandatory = $true,HelpMessage = 'OID list')]
        [string[]]$OID,
    
        [string]$Community = 'public', 
        [int]$UDPport = 161,
        [Lextm.SharpSnmpLib.VersionCode]$Version = 'V2',
        [int]$TimeOut = 5000
    )

    $variableList = New-Object Collections.Generic.List[Lextm.SharpSnmpLib.Variable]
    foreach ($singleOID in $OID) {
        $variableList.Add($(
            New-Object Lextm.SharpSnmpLib.ObjectIdentifier $singleOID
        ))
    }
 
    $endpoint = New-Object Net.IpEndPoint $IP, $UDPport
 
    try {
        $message = [Lextm.SharpSnmpLib.Messaging.Messenger]::Get(
            $Version, 
            $endpoint, 
            $Community, 
            $variableList, 
            $TimeOut
        )
    } catch {
        Write-Warning "SNMP Get error: $_"
        return
    }
 
    foreach ($variable in $message) {
        New-Object PSObject -Property @{
            OID = $variable.Id.ToString()
            Data = $variable.Data.ToString()
        }
    }
}


# Hashtabelle mit OIDs
$OIDs = @{
    "Base"                 = "1.3.6.1.4.1.2604.5.1.5.1.2.0"
    "Net Protection"       = "1.3.6.1.4.1.2604.5.1.5.2.2.0"
    "Web Protection"       = "1.3.6.1.4.1.2604.5.1.5.3.2.0"
    "Mail Protection"      = "1.3.6.1.4.1.2604.5.1.5.4.2.0"
    "Web Server Protection"= "1.3.6.1.4.1.2604.5.1.5.5.2.0"
    "Sandstorm"            = "1.3.6.1.4.1.2604.5.1.5.6.2.0"
    "Enhanced Support"     = "1.3.6.1.4.1.2604.5.1.5.7.2.0"
    "Enhanced Plus Support"= "1.3.6.1.4.1.2604.5.1.5.8.2.0"
}

# Abfrage der OIDs
foreach ($Key in $OIDs.Keys) {
    $result = Get-SnmpData -IP $IP -Community $CommunityName -OID $OIDs[$Key]

    if ($result) {
        $rawDate = $result.Data

        if ($rawDate -match "fail") {
            Write-Output "$Key : wird nicht verwendet"
        } else {
            try {
                $licenseDate = Get-Date $rawDate
                $daysLeft = ($licenseDate - (Get-Date)).Days

                if ([int]$daysLeft -le 7) {
                    Write-Output "$Key : Fehler | Laeuft in $daysLeft Tagen ab ($rawDate)"
                } elseif ([int]$daysLeft -le 30) {
                    Write-Output "$Key : Warnung | Laeuft in $daysLeft Tagen ab ($rawDate)"
                } else {
                    Write-Output "$Key : In Ordnung  | $rawDate ($daysLeft Tage verbleibend)"
                }
            } catch {
                Write-Output "$Key : Fehler bei der Datumskonvertierung ($rawDate)"
            }
        }
    } else {
        Write-Output "$Key : Keine Daten empfangen"
    }
}


