# Lokaler Servername zur Infoausgabe
$ServerName = $env:COMPUTERNAME

# Funktion zum Starten automatisch startender Dienste
$StartAutomaticServices = {
    # Überprüfen und Starten aller automatisch startenden Dienste
    $automatischeDienste = Get-Service | Where-Object {$_.StartType -eq 'Automatic'}
    foreach ($dienst in $automatischeDienste) {
        if ($dienst.Status -ne 'Running') {
            Write-Host "Der Dienst $($dienst.DisplayName) ist nicht gestartet. Starte den Dienst jetzt..."
            Start-Service $dienst.Name
        }
    }

    # Überprüfen und Auflisten aller automatisch startenden Dienste, die nicht gestartet sind
    $gestoppteDienste = Get-Service | Where-Object {$_.StartType -eq 'Automatic' -and $_.Status -ne 'Running'}
    if ($gestoppteDienste.Count -gt 0) {
        Write-Host "Folgende automatisch startende Dienste sind nicht gestartet:"  -ForegroundColor Yellow
        $gestoppteDienste | Format-Table DisplayName, Status, StartType -AutoSize
    } else {
        Write-Host "Alle automatisch startenden Dienste sind gestartet." -ForegroundColor Green
    }
}

# Funktion zum Installieren von Windows Updates (ohne Neustart)

$InstallWindowsUpdatesForeground = {
   # Falls Installation fehlschlägt, TLS fixen:
    [Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12

    # Überprüfen, ob das PSWindowsUpdate-Modul installiert ist
    if (-not (Get-Module -ListAvailable -Name PSWindowsUpdate)) {
        # Falls nicht installiert, versuche es zu installieren
        try {
            Write-Host "Das Modul PSWindowsUpdate wird installiert..."
            Install-Module -Name PSWindowsUpdate -Force -Confirm:$false
            Write-Host "Das Modul PSWindowsUpdate wurde erfolgreich installiert."
        } catch {
            Write-Error "Fehler beim Installieren des Moduls PSWindowsUpdate: $_"
        }
    } else {
        Write-Host "Das Modul PSWindowsUpdate ist bereits installiert. Installation wird gestartet."
    }

        Add-WUServiceManager -ServiceID "7971f918-a847-4430-9279-4a52d1efe18d" -AddServiceFlag 7 -Confirm:$false;
        Import-Module PSWindowsUpdate;
        Get-WUList -MicrosoftUpdate;
        Install-WindowsUpdate -MicrosoftUpdate -AcceptAll -IgnoreReboot

    Write-Host "Windows Updates Installation auf $ServerName läuft (ohne Neustart)" -ForegroundColor Green
}

$InstallWindowsUpdatesBackground = {
   # Falls Installation fehlschlägt, TLS fixen:
    [Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12

    # Überprüfen, ob das PSWindowsUpdate-Modul installiert ist
    if (-not (Get-Module -ListAvailable -Name PSWindowsUpdate)) {
        # Falls nicht installiert, versuche es zu installieren
        try {
            Write-Host "Das Modul PSWindowsUpdate wird installiert..."
            Install-Module -Name PSWindowsUpdate -Force -Confirm:$false
            Write-Host "Das Modul PSWindowsUpdate wurde erfolgreich installiert."
        } catch {
            Write-Error "Fehler beim Installieren des Moduls PSWindowsUpdate: $_"
        }
    } else {
        Write-Host "Das Modul PSWindowsUpdate ist bereits installiert. Installation wird gestartet."
    }

    Start-Job -ScriptBlock {
        Add-WUServiceManager -ServiceID "7971f918-a847-4430-9279-4a52d1efe18d" -AddServiceFlag 7 -Confirm:$false;
        Import-Module PSWindowsUpdate;
        Get-WUList -MicrosoftUpdate;
        Install-WindowsUpdate -MicrosoftUpdate -AcceptAll -IgnoreReboot
    }

    Write-Host "Windows Updates Installation auf $ServerName im Hintergrund gestartet (ohne Neustart)" -ForegroundColor Green
}

# Funktion zum Prüfen der Event Logs auf kritische Fehler
$CheckEventLogs = {
     # Startdatum auf 30 Tage vor dem aktuellen Datum setzen
    $startDate = (Get-Date).AddDays(-30)

    # Filterkriterien für Fehler und kritische Ereignisse
    $logFilter = @{
        LogName   = 'Application', 'System', 'Security', 'Directory Service', 'DNS Server', 'DFS Replication', 'DhcpAdminEvents'
        Level     = 1, 2, 3  # 1 = Kritisch, 2 = Fehler, 3 = Warnung
        StartTime = $startDate
    }

    # Ereignisprotokolle durchsuchen und die Ergebnisse in einer Variablen speichern
    $events = Get-WinEvent -FilterHashtable $logFilter -ErrorAction SilentlyContinue

    # Ereignisse der letzten 7 Tage filtern
    $recentEvents = $events | Where-Object { $_.TimeCreated -gt (Get-Date).AddDays(-7) }

    # Ereignisse nach ID und Nachricht gruppieren
    $groupedEvents = $recentEvents | Group-Object Id, Message

    # Alle gefundenen Ereignisse auflisten
    foreach ($group in $groupedEvents) {
        if ($group.Count -gt 1) {
            $event = $group.Group[0]
            $eventTime = $event.TimeCreated
            $eventId = $event.Id
            $eventLevel = $event.LevelDisplayName
            $eventMessage = if ($event.Message.Length -gt 100) { 
                $event.Message.Substring(0, 100) + "..." 
            } else { 
                $event.Message 
            }

            # Farbe je nach Schweregrad setzen
            switch ($eventLevel) {
                'Kritisch' { $color = 'DarkRed' }
                'Fehler'   { $color = 'Red' }
                'Warnung'  { $color = 'Yellow' }
                'Critical' { $color = 'DarkRed' }
                'Error'   { $color = 'Red' }
                'Warning'  { $color = 'Yellow' }
                default    { $color = 'White' }
            }

            # Ausgabe der Ereignisse
            Write-Host "Ereignis-ID: $eventId ($eventLevel), Anzahl: $($group.Count), Nachricht: $eventMessage" -ForegroundColor $color
            Write-Output "----------------------------------------"
        }
    }

}

# Funktion zum Neustarten des Servers
$RestartServer = {
    Restart-Computer -Timeout 60 -Force -Confirm:$false
    Write-Host "Der Server wird in 60 Sekunden neu gestartet..." -ForegroundColor Yellow
}

$SFC = {
    Start-Job -ScriptBlock {
        Add-WUServiceManager -ServiceID "7971f918-a847-4430-9279-4a52d1efe18d" -AddServiceFlag 7 -Confirm:$false;
        Import-Module PSWindowsUpdate;
        Get-WUList -MicrosoftUpdate;
        Install-WindowsUpdate -MicrosoftUpdate -AcceptAll -IgnoreReboot
    }

    Write-Host "SFC Scan gestartet (ohne Neustart)" -ForegroundColor Green
}

$DISMCheckHealth = {
    Start-Job -ScriptBlock {
        dism /online /cleanup-image /checkhealth
    }

    Write-Host "DISM ScanHealth wurde im Hintergrund gestartet" -ForegroundColor Green
}

$DISMRestoreHealth = {
    Start-Job -ScriptBlock {
        dism /online /cleanup-image /restorehealth
    }

    Write-Host "DISM RestoreHealth wurde im Hintergrund gestartet" -ForegroundColor Green
}

$FreeDiskSpace = {
    # Holen der WMI-Laufwerksinformationen (Details zu Festplattenlaufwerken)
    $drives = Get-WmiObject -Class Win32_LogicalDisk | Where-Object { $_.DriveType -eq 3 }

    # Durchlaufen der Laufwerke und Ausgeben der Kapazität und Auslastung in GB
    foreach ($drive in $drives) {
        $usedSpaceGB = [math]::round($drive.Size - $drive.FreeSpace / 1GB, 2)  # Umrechnung in GB und Berechnung der genutzten Größe
        $freeSpaceGB = [math]::round($drive.FreeSpace / 1GB, 2)  # Umrechnung in GB für freien Speicher
        $totalSpaceGB = [math]::round($drive.Size / 1GB, 2)  # Gesamtgröße in GB

        # Berechnung des freien Speicherplatzes in Prozent
        $freeSpacePercent = ($freeSpaceGB / $totalSpaceGB) * 100

        # Ausgabe der Partitionen mit Farbanpassung und Anzeige in GB
        if ($freeSpacePercent -le 15) {
            Write-Host "$($drive.DeviceID): $usedSpaceGB GB verwendet, $freeSpaceGB GB frei ($([math]::round($freeSpacePercent, 2))% frei)" -ForegroundColor Red
        } else {
            Write-Host "$($drive.DeviceID): $usedSpaceGB GB verwendet, $freeSpaceGB GB frei ($([math]::round($freeSpacePercent, 2))% frei)" -ForegroundColor Green
        }
    }

}

$ExchangeHealthChecker = {
    # 1. Prüfen ob Exchange Server installiert ist
    $exchangeServices = Get-Service | Where-Object { $_.Name -like "MSExchange*" }

    if (-not $exchangeServices -or $exchangeServices.Count -eq 0) {
        Write-Host "Kein Exchange Server installiert (keine Exchange-Dienste gefunden)." -ForegroundColor Red
        exit
    } else {
        Write-Host "Exchange Server erkannt." -ForegroundColor Green
    }


    # 2. Prüfen ob Ordner C:\Skripte existiert, falls nicht erstellen
    $skriptPfad = "C:\Skripte"
    if (-not (Test-Path $skriptPfad)) {
        New-Item -Path $skriptPfad -ItemType Directory | Out-Null
        Write-Host "Ordner C:\Skripte wurde erstellt." -ForegroundColor Green
    } else {
        Write-Host "Ordner C:\Skripte ist bereits vorhanden." -ForegroundColor Gray
    }

    # 3. HealthChecker.ps1 herunterladen (immer überschreiben)
    $healthCheckerUrl = "https://github.com/microsoft/CSS-Exchange/releases/latest/download/HealthChecker.ps1"
    $zielDatei = Join-Path $skriptPfad "HealthChecker.ps1"

    Write-Host "Lade HealthChecker.ps1 herunter..."
    Invoke-WebRequest -Uri $healthCheckerUrl -OutFile $zielDatei -UseBasicParsing
    Write-Host "HealthChecker.ps1 wurde heruntergeladen nach $zielDatei." -ForegroundColor Green

    # 4. Exchange Management Shell laden
    try {
        Add-PSSnapin Microsoft.Exchange.Management.PowerShell.SnapIn -ErrorAction Stop
        Write-Host "Exchange Management Shell erfolgreich geladen." -ForegroundColor Green
    } catch {
        Write-Host "Fehler beim Laden der Exchange Management Shell: $_" -ForegroundColor Red
        exit
    }

    # 5. HealthChecker.ps1 ausführen
    Write-Host "Führe HealthChecker.ps1 aus..."
    & $zielDatei

}

$ExchangeQueue = {
    # 1. Prüfen ob Exchange Server installiert ist
    $exchangeServices = Get-Service | Where-Object { $_.Name -like "MSExchange*" }

    if (-not $exchangeServices -or $exchangeServices.Count -eq 0) {
        Write-Host "Kein Exchange Server installiert (keine Exchange-Dienste gefunden)." -ForegroundColor Red
        exit
    } else {
        Write-Host "Exchange Server erkannt." -ForegroundColor Green
    }

    # 2. Exchange Management Shell laden
    try {
        Add-PSSnapin Microsoft.Exchange.Management.PowerShell.SnapIn -ErrorAction Stop
        Write-Host "Exchange Management Shell erfolgreich geladen." -ForegroundColor Green
    } catch {
        Write-Host "Fehler beim Laden der Exchange Management Shell: $_" -ForegroundColor Red
        exit
    }
    
    # 3. Exchange Queue prüfen
    try {
        $queues = Get-Queue

        if ($queues.Count -eq 0) {
            Write-Host "Keine Queues gefunden – alles sieht gut aus." -ForegroundColor Green
        } else {
            $queuesWithMessages = $queues | Where-Object { $_.MessageCount -gt 0 }

            if ($queuesWithMessages.Count -eq 0) {
                Write-Host "Alle Queues sind leer." -ForegroundColor Green
            } else {
                Write-Host "Folgende Queues enthalten Nachrichten:" -ForegroundColor Yellow
                $queuesWithMessages | Format-Table Identity, MessageCount, Status, DeliveryType -AutoSize
            }
        }
    } catch {
        Write-Host "Fehler beim Abrufen der Queue-Informationen: $_" -ForegroundColor Red
    }

}

$ScheduledRestart = {
# Überprüfen, ob das Skript mit Administratorrechten ausgeführt wird
if (-not ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole] "Administrator")) {
    Write-Host "Dieses Skript erfordert Administratorrechte. Bitte führen Sie es als Administrator aus."
    exit
}

# Name des geplanten Tasks
$TaskName = "ServerNeustart"
$DisableTaskName = "Disable_ServerNeustart"

# Zielpfad für das Deaktivierungs-Skript
$ScriptFolder = "C:\Skripte"
$DisableScriptPath = "$ScriptFolder\DisableTaskAfterExecution.ps1"

# 1. Ordner C:\Skripte sicherstellen
if (-not (Test-Path $ScriptFolder)) {
    New-Item -ItemType Directory -Path $ScriptFolder | Out-Null
    Write-Output "Der Ordner '$ScriptFolder' wurde erstellt."
}

# 2. Benutzer nach der Uhrzeit fragen
$restartTime = Read-Host "Geben Sie die Uhrzeit ein, zu der der Server täglich neu gestartet werden soll (z.B. 19:00)"

# Überprüfen, ob die Eingabe ein gültiges Zeitformat hat
if (-not ($restartTime -match '^\d{2}:\d{2}$')) {
    Write-Host "Ungültiges Format. Bitte geben Sie die Uhrzeit im Format HH:mm ein."
    exit
}

# 3. Prüfen und ggf. löschen: Existierende geplante Tasks mit dem gleichen Namen
$existingTask = Get-ScheduledTask -TaskName ServerNeustart -ErrorAction SilentlyContinue
if ($existingTask) {
    Write-Output "Der geplante Task ServerNeustart existiert bereits. Er wird gelöscht."
    Unregister-ScheduledTask -TaskName ServerNeustart -Confirm:$false
}

$existingDisableTask = Get-ScheduledTask -TaskName $DisableTaskName -ErrorAction SilentlyContinue
if ($existingDisableTask) {
    Write-Output "Der geplante Task '$DisableTaskName' existiert bereits. Er wird gelöscht."
    Unregister-ScheduledTask -TaskName $DisableTaskName -Confirm:$false
}

# 4. Neuen Task erstellen: ServerNeustart
Write-Output "Der geplante Task ServerNeustart wird erstellt."

# Trigger auf die benutzerdefinierte Uhrzeit setzen
$Trigger = New-ScheduledTaskTrigger -Daily -At $restartTime

# Aktion zum Neustarten des Servers
$Action = New-ScheduledTaskAction -Execute "shutdown.exe" -Argument "/r /t 60 /f"
$Settings = New-ScheduledTaskSettingsSet -AllowStartIfOnBatteries -DontStopIfGoingOnBatteries -StartWhenAvailable

Register-ScheduledTask -TaskName ServerNeustart -Description "Startet den Server um $restartTime neu und löscht sich danach." `
    -Trigger $Trigger -Action $Action -Settings $Settings -RunLevel Highest -User "SYSTEM"

Write-Output "Der Task ServerNeustart wurde erfolgreich erstellt."

# 5. Skript zur Deaktivierung des Tasks nach Ausführung speichern
$DisableTaskScript = @'
# Lösche den geplanten Task nach dem Neustart
    Unregister-ScheduledTask -TaskName ServerNeustart -Confirm:$false
Write-Output "Der geplante Task ServerNeustart wurde nach dem Neustart gelöscht."
'@

$DisableTaskScript | Set-Content -Path $DisableScriptPath -Encoding UTF8
Write-Output "Deaktivierungs-Skript wurde unter '$DisableScriptPath' gespeichert."

# 6. Neuen Task erstellen: Disable-Task nach dem Neustart
Write-Output "Der zusätzliche Task '$DisableTaskName' wird erstellt."

$DisableTrigger = New-ScheduledTaskTrigger -AtStartup
$DisableAction = New-ScheduledTaskAction -Execute "powershell.exe" -Argument "-ExecutionPolicy Bypass -File `"$DisableScriptPath`""

Register-ScheduledTask -TaskName $DisableTaskName -Description "Löscht den Neustart-Task nach der ersten Ausführung." `
    -Trigger $DisableTrigger -Action $DisableAction -RunLevel Highest -User "SYSTEM"

Write-Host "Der Task '$DisableTaskName' wurde erfolgreich erstellt."
Write-Host "Der Server startet nun einmalig um $restartTime neu." -ForegroundColor Green

}

$AutomaticServiceTask = {
# Überprüfen, ob das Skript mit Administratorrechten ausgeführt wird
if (-not ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole] "Administrator")) {
    Write-Host "Dieses Skript erfordert Administratorrechte. Bitte führen Sie es als Administrator aus."
    exit
}

# Zielpfad für das Dienststart-Skript
$ScriptFolder = "C:\Skripte"
$ScriptPath = "$ScriptFolder\StartServices.ps1"
$TaskName = "Start_AutoServices"

# Falls der Ordner C:\Skripte nicht existiert, erstelle ihn
if (-not (Test-Path $ScriptFolder)) {
    New-Item -ItemType Directory -Path $ScriptFolder | Out-Null
    Write-Output "Der Ordner '$ScriptFolder' wurde erstellt."
}

# Überprüfen, ob der geplante Task bereits existiert und löschen falls vorhanden
$TaskExists = Get-ScheduledTask -TaskName $TaskName -ErrorAction SilentlyContinue
if ($null -ne $TaskExists) {
    Write-Output "Der geplante Task '$TaskName' existiert bereits. Er wird nun gelöscht."
    Unregister-ScheduledTask -TaskName $TaskName -Confirm:$false
}

# Erstelle einen neuen Task
Write-Output "Der geplante Task '$TaskName' wird jetzt erstellt."

# Erstelle einen Start-Trigger (direkt nach Systemstart)
$Trigger = New-ScheduledTaskTrigger -AtStartup

# Erstelle eine Aktion zum Ausführen des Skripts
$Action = New-ScheduledTaskAction -Execute "powershell.exe" -Argument "-ExecutionPolicy Bypass -File `"$ScriptPath`""

# Erstelle den Task mit SYSTEM-Berechtigungen
Register-ScheduledTask -TaskName $TaskName -Description "Überprüft und startet automatisch startende Dienste." -Trigger $Trigger -Action $Action -RunLevel Highest -User "SYSTEM"

Write-Output "Der geplante Task wurde erfolgreich erstellt."

# Erstelle das Dienststart-Skript
$ServiceScript = @'
Start-Sleep -Seconds 300  # Warten Sie 5 Minuten (300 Sekunden), bevor die Dienste überprüft werden
# Überprüfen und Starten aller automatisch startenden Dienste
$automatischeDienste = Get-Service | Where-Object {$_.StartType -eq 'Automatic'}
foreach ($dienst in $automatischeDienste) {
    if ($dienst.Status -ne 'Running') {
        Write-Host "Der Dienst $($dienst.DisplayName) ist nicht gestartet. Starte den Dienst jetzt..."
        Start-Service $dienst.Name
    }
}

# Überprüfen und Auflisten aller automatisch startenden Dienste, die nicht gestartet sind
$gestoppteDienste = Get-Service | Where-Object {$_.StartType -eq 'Automatic' -and $_.Status -ne 'Running'}
if ($gestoppteDienste.Count -gt 0) {
    Write-Host "`nFolgende automatisch startenden Dienste sind nicht gestartet:`n"
    $gestoppteDienste | Format-Table DisplayName, Status, StartType -AutoSize
} else {
    Write-Host "`nAlle automatisch startenden Dienste sind gestartet.`n"
}
'@

# Speichere das Dienststart-Skript unter C:\Skripte\StartServices.ps1
$ServiceScript | Set-Content -Path $ScriptPath -Encoding UTF8
Write-Output "Das Dienststart-Skript wurde unter '$ScriptPath' gespeichert."
Write-Output "Alle Dienste werden nun 5 Minuten nach jedem Neustart geprüft" -ForegroundColor Green

}

# Hauptlogik des Skripts
do {

     # 3. Auswahl der Aktion
    Write-Host "`nVerfügbare Aktionen:
    --- Monatliche Wartung ---
    1) Alle automatisch startenden Dienste starten
    2) Windows Updates installieren (ohne Neustart)
    3) Windows Updates im Hintergrund installieren (ohne Neustart)
    4) Ereignisanzeige überprüfen
    5) Festplattensbelegung überprüfen
    9) Server neu starten

    --- Systemüberprüfung ---
    51) SFC scannow
    52) DISM CheckHealth
    53) DISM RestoreHealth

    --- Exchange 2016/2019 Server ---
    61) Exchange 2016/2019 HealthChecker
    62) Exchange 2016/2019 Queue

    --- Automatisierung ---
    81) Automatischen Neustart konfigurieren
    82) Dienste nach Neustarts überprüfen"


    $action = Read-Host "`nBitte wählen Sie eine Aktion oder 'q' zum Beenden"

    if ($action -eq 'q') {
        Write-Host "Skript wird beendet." -ForegroundColor Green
        break
    }

    # Durchführung der gewählten Aktion
    switch ($action) {
        '1' {& $StartAutomaticServices
        }
        '2' {& $InstallWindowsUpdatesForeground
        }
        '3' {& $InstallWindowsUpdatesBackground
        }
        '4' {& $CheckEventLogs
        }
        '5' {& $FreeDiskSpace
        }
        '51' {& $SFC
        }
        '52' {& $DISMCheckHealth
        }
        '53' {& $DISMRestoreHealth
        }
        '61' {& $ExchangeHealthChecker
        }
        '62' {& $ExchangeQueue
        }
        '81' {& $ScheduledRestart
        }
        '82' {& $AutomaticServiceTask
        }
        '9' {& $RestartServer
        }
        default {
            Write-Host "Ungültige Auswahl. Bitte wählen Sie eine gültige Aktion." -ForegroundColor Red
        }
    }
}
while ($true)