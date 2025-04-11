# IP-Adresse und Community anpassen
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
 
    $resultList = @()
    foreach ($variable in $message) {
        $resultList += New-Object PSObject -Property @{
            OID = $variable.Id.ToString()
            Data = $variable.Data.ToString()
        }
    }
    return $resultList
}

# Hashtabelle mit den gewünschten OIDs
$OIDs = @{
    "VPN Name"        = ".1.3.6.1.4.1.2604.5.1.6.1.1.1.1.2"
    "VPN Status"      = ".1.3.6.1.4.1.2604.5.1.6.1.1.1.1.9"
    "VPN Aktiv"       = ".1.3.6.1.4.1.2604.5.1.6.1.1.1.1.10"
}

# Maximale Endung, die überprüft werden soll
$maxEndung = 5

# Ergebnis speichern
$results = @()

# Durchlauf der OIDs und Abfrage der Daten für jede Endung .1, .2, .3, ...
for ($i = 1; $i -le $maxEndung; $i++) {
    $resultForTable = @()

    # Durchlauf der OIDs und Abfrage der Daten für die aktuelle Endung
    foreach ($Key in $OIDs.Keys) {
        $oid = "$($OIDs[$Key]).$i"
        $result = Get-SnmpData -IP $IP -Community $CommunityName -OID $oid

        # Wenn die OID den Wert "NoSuchInstance" zurückgibt, überspringen
        if ($result) {
            $rawData = $result.Data
            if ($rawData -eq "NoSuchInstance") {
                $resultForTable = $null
                break
            }

            $row = [PSCustomObject]@{
                "OID Bezeichnung" = $Key
                #"OID" = $oid
                "Wert" = $rawData
                "Status" = ""
            }

            # Weitere Auswertungen für VPN Status und VPN Aktiv
            if ($Key -eq "VPN Status") {
                if ($rawData -eq "1") {
                    $row.Status = "In Ordnung! VPN ist aktiv."
                } else {
                    $row.Status = "Fehler! VPN ist nicht aktiv."
                }
            }
            if ($Key -eq "VPN Aktiv") {
                if ($rawData -eq "1") {
                    $row.Status = "In Ordnung! VPN aktiviert."
                } else {
                    $row.Status = "Fehler! VPN nicht aktiviert."
                }
            }

            # Füge die Zeile zur Tabelle hinzu
            $resultForTable += $row
        }
    }

    # Wenn Ergebnisse für die aktuelle Endung vorhanden sind, Tabelle ausgeben
    if ($resultForTable.Count -gt 0) {
        Write-Output "Ergebnisse für Endung .${i}:"
        $resultForTable | Format-Table -AutoSize
        Write-Output "`n"
    }
}
