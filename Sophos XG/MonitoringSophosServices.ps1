# Abfrage im Monitoring:
# enthält "In Ordnung"
# enthält nicht "Fehler"

# IP Adresse bitte anpassen
# Definiere die IP-Adresse und Community
$IP = "192.168.10.1"
$CommunityName = "public"

# Aktivieren/Deaktivieren von Diensten für die Überprüfung (true = aktiv, false = ignorieren)
$EnabledServices = @{
    "POP3" = $true
    "IMAP4" = $true
    "SMTP" = $true
    "FTP" = $true
    "HTTP" = $true
    "AV (Antivirus)" = $true
    "AS (Antispam)" = $true
    "DNS" = $true
    "HA (High Availability)" = $false
    "IPS (Intrusion Prevention System)" = $true
    "Apache Web Server" = $true
    "NTP (Network Time Protocol)" = $true
    "Tomcat Application Server" = $true
    "SSL-VPN" = $true
    "IPSec VPN" = $true
    "Database" = $true
    "Network" = $true
    "Garner (Logging System)" = $true
    "Drouting (Dynamic Routing)" = $true
    "SSHD (Secure Shell Daemon)" = $true
    "DGD (Device and Group Discovery)" = $true
}

# Hashtabelle mit den OIDs für die Dienste
$ServiceOIDs = @{
    "POP3" = ".1.3.6.1.4.1.2604.5.1.3.1.0"
    "IMAP4" = ".1.3.6.1.4.1.2604.5.1.3.2.0"
    "SMTP" = ".1.3.6.1.4.1.2604.5.1.3.3.0"
    "FTP" = ".1.3.6.1.4.1.2604.5.1.3.4.0"
    "HTTP" = ".1.3.6.1.4.1.2604.5.1.3.5.0"
    "AV (Antivirus)" = ".1.3.6.1.4.1.2604.5.1.3.6.0"
    "AS (Antispam)" = ".1.3.6.1.4.1.2604.5.1.3.7.0"
    "DNS" = ".1.3.6.1.4.1.2604.5.1.3.8.0"
    "HA (High Availability)" = ".1.3.6.1.4.1.2604.5.1.3.9.0"
    "IPS (Intrusion Prevention System)" = ".1.3.6.1.4.1.2604.5.1.3.10.0"
    "Apache Web Server" = ".1.3.6.1.4.1.2604.5.1.3.11.0"
    "NTP (Network Time Protocol)" = ".1.3.6.1.4.1.2604.5.1.3.12.0"
    "Tomcat Application Server" = ".1.3.6.1.4.1.2604.5.1.3.13.0"
    "SSL-VPN" = ".1.3.6.1.4.1.2604.5.1.3.14.0"
    "IPSec VPN" = ".1.3.6.1.4.1.2604.5.1.3.15.0"
    "Database" = ".1.3.6.1.4.1.2604.5.1.3.16.0"
    "Network" = ".1.3.6.1.4.1.2604.5.1.3.17.0"
    "Garner (Logging System)" = ".1.3.6.1.4.1.2604.5.1.3.18.0"
    "Drouting (Dynamic Routing)" = ".1.3.6.1.4.1.2604.5.1.3.19.0"
    "SSHD (Secure Shell Daemon)" = ".1.3.6.1.4.1.2604.5.1.3.20.0"
    "DGD (Device and Group Discovery)" = ".1.3.6.1.4.1.2604.5.1.3.21.0"
}

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

# Liste für inaktive Dienste
$inactiveServices = @()

foreach ($Service in $ServiceOIDs.Keys) {
    # Prüfen, ob der Dienst aktiviert ist
    if ($EnabledServices[$Service] -eq $false) {
        Write-Output "$Service : Überprüfung deaktiviert"
        continue
    }

    $OID = $ServiceOIDs[$Service]
    $result = Get-SnmpData -IP $IP -Community $CommunityName -OID $OID

    if ($result) {
        $status = [int]$result.Data
        if ($status -eq 3) {
            Write-Output "$Service : Dienst gestartet"
        }

        # Wenn der Dienst nicht aktiv ist, zur Warnliste hinzufügen
        if ($status -eq 0) {
            $inactiveServices += $Service
        }
    } else {
        Write-Warning "Konnte Status für $Service nicht abrufen!"
    }
}

# Falls Dienste inaktiv sind, Warnung ausgeben
if ($inactiveServices.Count -gt 0) {
    Write-Warning "Fehler: Die folgenden Dienste sind inaktiv: $($inactiveServices -join ', ')"
} else {
    Write-Output "In Ordnung: Alle ueberprueften Dienste sind aktiv."
}
