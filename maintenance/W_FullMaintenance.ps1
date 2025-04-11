# Funktion, um die verfügbaren Server im AD zu scannen
function Get-WindowsServers {
    $servers = Get-ADComputer -Filter {OperatingSystem -Like "*Windows Server*"} -Property Name
    return $servers
}

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
$InstallWindowsUpdates = {
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

    Write-Host "Windows Updates Installation auf $ServerName läuft (ohne Neustart)" -ForegroundColor Green
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

    Write-Host "Windows Updates Installation auf $ServerName läuft (ohne Neustart)" -ForegroundColor Green
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

# Hauptlogik des Skripts
do {
    # 1. Scannen des AD nach Windows Servern und nummerische Auflistung
    $servers = Get-WindowsServers
    $servers = $servers | Select-Object Name

    # Server nummerisch auflisten
    Write-Host "`nVerfügbare Windows Server:"
    $i = 1
    $servers | ForEach-Object { Write-Host "$i) $($_.Name)"; $i++ }

    # 2. Server-Auswahl mit Validierung
    $validInput = $false
    while (-not $validInput) {
        $serverIndex = Read-Host "Wählen Sie einen Server (geben Sie eine Zahl zwischen 1 und $($servers.Count))"
    
        # Überprüfen, ob die Eingabe eine gültige Zahl ist und im Bereich liegt
        if ($serverIndex -match '^\d+$' -and $serverIndex -ge 1 -and $serverIndex -le $servers.Count) {
            $validInput = $true
        } else {
            Write-Host "Ungültige Auswahl. Bitte geben Sie eine Zahl zwischen 1 und $($servers.Count) ein." -ForegroundColor Red
        }
    }

    # Den ausgewählten Server ermitteln
    $selectedServer = $servers[$serverIndex - 1].Name
    Write-Host "Sie haben den Server '$selectedServer' ausgewählt."


     # 3. Auswahl der Aktion
    $actionList = @(
        "1) Alle automatisch startenden Dienste starten",
        "2) Windows Updates installieren (ohne Neustart)",
        "3) Ereignisanzeige überprüfen",
        "4) Festplattensbelegung überprüfen",
        "51) SFC scannow",
        "52) DISM CheckHealth",
        "53) DISM RestoreHealth",
        "99) Server neu starten",
        "q) Beenden"
    )
    Write-Host "`nVerfügbare Aktionen:"
    $actionList | Sort-Object | ForEach-Object { Write-Host $_ }

    $action = Read-Host "`nBitte wählen Sie eine Aktion oder 'q' zum Beenden"

    if ($action -eq 'q') {
        Write-Host "Skript wird beendet." -ForegroundColor Green
        break
    }

    # Durchführung der gewählten Aktion
    switch ($action) {
        '1' {
            Invoke-Command -ComputerName $selectedServer -ScriptBlock $StartAutomaticServices
        }
        '2' {
            Invoke-Command -ComputerName $selectedServer -ScriptBlock $InstallWindowsUpdates
        }
        '3' {
            Invoke-Command -ComputerName $selectedServer -ScriptBlock $CheckEventLogs
        }
        '4' {
            Invoke-Command -ComputerName $selectedServer -ScriptBlock $FreeDiskSpace
        }
        '51' {
            Invoke-Command -ComputerName $selectedServer -ScriptBlock $SFC
        }
        '52' {
            Invoke-Command -ComputerName $selectedServer -ScriptBlock $DISMCheckHealth
        }
        '53' {
            Invoke-Command -ComputerName $selectedServer -ScriptBlock $DISMRestoreHealth
        }
        '99' {
            Invoke-Command -ComputerName $selectedServer -ScriptBlock $RestartServer
        }
        default {
            Write-Host "Ungültige Auswahl. Bitte wählen Sie eine gültige Aktion." -ForegroundColor Red
        }
    }

    # Nach jeder Aktion wird das Skript fragen, ob eine neue Auswahl getroffen werden soll
} while ($true)
