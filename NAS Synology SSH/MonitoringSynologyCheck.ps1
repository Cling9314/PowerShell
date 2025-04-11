$scriptPath = "C:\Monitoring\MonitoringSynologyCheck.ps1"

# Name des geplanten Tasks
$taskName = "MonitoringSynologyCheck"

# Prüfe, ob der Task bereits existiert
$taskExists = Get-ScheduledTask -TaskName $taskName -ErrorAction SilentlyContinue

if (-not $taskExists) {
    # Task gibt es noch nicht, erstelle ihn

    # Erstelle den Trigger (jeden Sonntag um 08:00)
    $trigger = New-ScheduledTaskTrigger -Daily -At 08:00

    # Erstelle die Aktion
    $action = New-ScheduledTaskAction -Execute "C:\Windows\System32\WindowsPowerShell\v1.0\powershell.exe" -Argument "-File $scriptPath"
    
    # Erstelle den geplanten Task
    Register-ScheduledTask -Action $action -Trigger $trigger -TaskName $taskName -Description "Überwacht Synology NAS und speichert Ergebnisse." -RunLevel Highest -User "SYSTEM"

    Write-Output "Der Task wurde erfolgreich erstellt."
}

# Variablen definieren
$DeviceIP = '192.168.10.209'
$User = "api_user"
$Password = "]8b?Pa/N"

# SSH-Befehle
$CommandRAID = 'cat /proc/mdstat'
$CommandSerial = 'cat /proc/sys/kernel/syno_serial'  # Neuer Befehl zur Seriennummer
$CommandUptime = 'uptime -p'
$CommandDiskUsage = 'df -h --total | grep total'  # Holt nur die Gesamtdaten der Festplatten
$CommandCPU = 'top -n 1 | grep "Cpu"'  # CPU-Last
$CommandRAM = 'free -h'  # RAM-Nutzung
$CommandNetwork = 'ifconfig | grep "inet " | grep -v "127.0.0.1"'  # Aktive Netzwerkinterfaces
$CommandDSMUpdates = 'synopkg list | grep -i update'  # DSM Updates
$CommandUsers = 'cat /etc/passwd'  # Benutzer
$CommandGroups = 'cat /etc/group'  # Gruppen
$CommandSystemLog = 'grep "error" /var/log/messages'  # Fehler im Systemlog

# Kritische RAID-Zustände definieren
$NotHealthyStates = "*recovery*", "*failed*", "*failure*", "*offline*", "*rebuilding*"

# Passwort in SecureString umwandeln
$SecurePassword = ConvertTo-SecureString $Password -AsPlainText -Force
$Creds = New-Object System.Management.Automation.PSCredential ($User, $SecurePassword)

# Prüfen, ob das Modul "Posh-SSH" installiert ist
If (Get-Module -ListAvailable -Name "Posh-SSH") { 
    Import-Module "Posh-SSH" 
} Else { 
    Install-Module "Posh-SSH" -Force 
    Import-Module "Posh-SSH" 
}

try {
    # SSH-Sitzung starten
    $null = New-SSHSession -ComputerName $DeviceIP -Credential $Creds -AcceptKey -Force

    # RAID-Status abrufen
    $SSHOutputRAID = (Invoke-SSHCommand -Index 0 -Command $CommandRAID).Output
    # Seriennummer abrufen
    $SSHOutputSerial = (Invoke-SSHCommand -Index 0 -Command $CommandSerial).Output
    # Laufzeit seit letztem Neustart abrufen
    $SSHOutputUptime = (Invoke-SSHCommand -Index 0 -Command $CommandUptime).Output
    # Festplattenspeicher abrufen
    $SSHOutputDiskUsage = (Invoke-SSHCommand -Index 0 -Command $CommandDiskUsage).Output
    # CPU-Last abrufen
    $SSHOutputCPU = (Invoke-SSHCommand -Index 0 -Command $CommandCPU).Output
    # RAM-Nutzung abrufen
    $SSHOutputRAM = (Invoke-SSHCommand -Index 0 -Command $CommandRAM).Output
    # Aktive Netzwerk-Interfaces abrufen
    $SSHOutputNetwork = (Invoke-SSHCommand -Index 0 -Command $CommandNetwork).Output
    # DSM Updates abrufen
    $SSHOutputDSMUpdates = (Invoke-SSHCommand -Index 0 -Command $CommandDSMUpdates).Output
    # Benutzer abrufen
    $SSHOutputUsers = (Invoke-SSHCommand -Index 0 -Command $CommandUsers).Output
    # Gruppen abrufen
    $SSHOutputGroups = (Invoke-SSHCommand -Index 0 -Command $CommandGroups).Output
    # Systemlog auf Fehler prüfen
    $SSHOutputSystemLog = (Invoke-SSHCommand -Index 0 -Command $CommandSystemLog).Output

    # SSH-Sitzung beenden
    $null = Get-SSHSession | Remove-SSHSession
}
catch {
    Write-Host "!!!Fehler: Verbindung zum NAS fehlgeschlagen!" -ForegroundColor Red
    exit
}

# Falls keine Ausgabe erhalten wurde
if (!$SSHOutputRAID) { 
    Write-Host "!!!Fehler: Keine RAID-Informationen gefunden!" -ForegroundColor Red
    exit
}

# RAID-Status prüfen
$HealthState = foreach ($State in $NotHealthyStates) {
    if ($SSHOutputRAID -like $State) {
        "!!!Unhealthy - $State found."
    }
}

# Festplattenspeicherwerte auslesen (df -h Ausgabe: "total   5.4T   2.1T   3.3T   38%")
$DiskValues = $SSHOutputDiskUsage -split "\s+"  # Trenne Werte anhand von Leerzeichen/Tabs

# Überprüfen, ob wir gültige Daten haben
if ($DiskValues.Count -ge 5) {
    $TotalSpace = $DiskValues[1]  # Gesamtspeicher
    $UsedSpace = $DiskValues[2]   # Verwendeter Speicher
    $UsedPercentage = $DiskValues[4]  # Belegter Speicher in %

    # Prozentwert bereinigen (Entfernen von "%")
    $UsedPercentageValue = $UsedPercentage -replace "%", "" | ForEach-Object { [int]$_ }

    # Prüfen, ob der Speicher über 90% belegt ist
    if ($UsedPercentageValue -ge 90) {
        Write-Host "!!!Fehler: Speicherbelegung über 95% ($UsedPercentage)" -ForegroundColor Red
        $StorageWarning = "!!!WARNUNG: Speicherbelegung über 95% ($UsedPercentage)"
    }
    elseif ($UsedPercentageValue -ge 80) {
        Write-Host "!!!WARNUNG: Speicherbelegung über 80% ($UsedPercentage)" -ForegroundColor Red
        $StorageWarning = "!!!WARNUNG: Speicherbelegung über 80% ($UsedPercentage)"
    } else {
        $StorageWarning = "Speicherbelegung In Ordnung ($UsedPercentage)"
    }
} else {
    $TotalSpace = "N/A"
    $UsedSpace = "N/A"
    $UsedPercentage = "N/A"
    $StorageWarning = " Speicherinfo konnte nicht abgerufen werden!"
}

# Ergebnisse für Terminal ausgeben
Write-Host "**Synology NAS Systeminfo**" -ForegroundColor Cyan
Write-Host "---------------------------------" -ForegroundColor Cyan
Write-Host "Seriennummer: $SSHOutputSerial" -ForegroundColor Yellow
Write-Host "Laufzeit seit letztem Neustart: $SSHOutputUptime" -ForegroundColor Yellow
Write-Host "---------------------------------" -ForegroundColor Cyan
Write-Host "**Festplattenspeicher**" -ForegroundColor Green
Write-Host "Gesamtspeicher: $TotalSpace" -ForegroundColor Green
Write-Host "Verwendeter Speicher: $UsedSpace" -ForegroundColor Green
Write-Host "Belegter Speicher in %: $UsedPercentage" -ForegroundColor Green
Write-Host "Speicherstatus: $StorageWarning" -ForegroundColor Green
Write-Host "---------------------------------" -ForegroundColor Cyan

# CPU-Last ausgeben
Write-Host "**CPU-Last**" -ForegroundColor Green
Write-Host $SSHOutputCPU -ForegroundColor Green
Write-Host "---------------------------------" -ForegroundColor Cyan

# RAM-Nutzung ausgeben
Write-Host "**RAM-Nutzung**" -ForegroundColor Green
Write-Host $SSHOutputRAM -ForegroundColor Green
Write-Host "---------------------------------" -ForegroundColor Cyan

# Aktive Netzwerk-Interfaces ausgeben
Write-Host "**Aktive Netzwerk-Interfaces**" -ForegroundColor Green
Write-Host $SSHOutputNetwork -ForegroundColor Green
Write-Host "---------------------------------" -ForegroundColor Cyan

# DSM Updates ausgeben
Write-Host "**DSM Updates**" -ForegroundColor Green
Write-Host $SSHOutputDSMUpdates -ForegroundColor Green
Write-Host "---------------------------------" -ForegroundColor Cyan

# Benutzer ausgeben
#Write-Host "**Benutzer**" -ForegroundColor Green
#Write-Host $SSHOutputUsers -ForegroundColor Green
#Write-Host "---------------------------------" -ForegroundColor Cyan

# Gruppen ausgeben
#Write-Host "**Gruppen**" -ForegroundColor Green
#Write-Host $SSHOutputGroups -ForegroundColor Green
#Write-Host "---------------------------------" -ForegroundColor Cyan

# Fehler im Systemlog ausgeben
Write-Host "**Systemlog - Meldungen**" -ForegroundColor Green
Write-Host $SSHOutputSystemLog -ForegroundColor Green
Write-Host "---------------------------------" -ForegroundColor Cyan

# RAID-Zustand ausgeben
if (!$HealthState) { 
    Write-Host "RAID-Status: Healthy - Alles In Ordnung." -ForegroundColor Green
} else { 
    Write-Host $HealthState -ForegroundColor Red
}

# Ergebnisse in Textdatei speichern
$OutputFile = "c:\monitoring\MonitoringSynologyCheck.txt"
$OutputContent = @"
**Synology NAS Systeminfo**
---------------------------------
Seriennummer: $SSHOutputSerial
Laufzeit seit letztem Neustart: $SSHOutputUptime
---------------------------------
**Festplattenspeicher**
Gesamtspeicher: $TotalSpace
Verwendeter Speicher: $UsedSpace
Belegter Speicher in %: $UsedPercentage
Speicherstatus: $StorageWarning
---------------------------------
**CPU-Last**
$SSHOutputCPU
---------------------------------
**RAM-Nutzung**
$SSHOutputRAM
---------------------------------
**Aktive Netzwerk-Interfaces**
$SSHOutputNetwork
---------------------------------
**DSM Updates**
$SSHOutputDSMUpdates
---------------------------------

**Systemlog - Fehler**
$SSHOutputSystemLog
---------------------------------
"@

#**Benutzer**
#$SSHOutputUsers
#---------------------------------
#**Gruppen**
#$SSHOutputGroups
#---------------------------------

# Falls RAID Fehler hat, in Datei schreiben
if ($HealthState) {
    $OutputContent += "`n!!!RAID-Status: Fehler gefunden: $HealthState`n"
}

# Datei speichern
$OutputContent | Out-File -Encoding utf8 $OutputFile
Write-Host "✅ Ergebnisse wurden in '$OutputFile' gespeichert." -ForegroundColor Green
