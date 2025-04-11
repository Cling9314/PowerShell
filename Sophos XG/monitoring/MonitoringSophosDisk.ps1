# Abfrage im Monitoring:
# enthält "in Ordnung"
# enthält nicht "Fehler"

# IP Adresse bitte anpassen
# Definiere die IP-Adresse und Community
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
    "Disk-Gesamtkapazität"         = ".1.3.6.1.4.1.2604.5.1.2.4.1.0"
    "Disk-Nutzung in Prozent"      = ".1.3.6.1.4.1.2604.5.1.2.4.2.0"
    "VPN" = ".1.3.6.1.4.1.2604.5.1.6.1.1.1.1.2.1"
}
    
$DiskUsage = 0

foreach ($Key in $OIDs.Keys) {
    $result = Get-SnmpData -IP $IP -Community $CommunityName -OID $OIDs[$Key]

    if ($result) {
        $rawData = $result.Data
        Write-Output "$Key : $rawData"

        # Speichere den Wert der Festplattennutzung
        if ($Key -eq "Disk-Nutzung in Prozent") {
            $DiskUsage = [int]$rawData
        }
    }
}

# Überprüfung, ob die Nutzung über 90% ist
if ($DiskUsage -ge 90) {
    Write-Output "Fehler! Festplattennutzung ist $DiskUsage%. Bitte pruefen!"
}
else {
    Write-Output "In Ordnung! Festplattennutzung ist $DiskUsage%."
}
