# Startdatum auf 30 Tage vor dem aktuellen Datum setzen
$startDate = (Get-Date).AddDays(-30)

# Filterkriterien für Fehler und kritische Ereignisse
$logFilter = @{
    LogName   = 'Application', 'System', 'Security'
    Level     = 1, 2  # 1 = Kritisch, 2 = Fehler
    StartTime = $startDate
}

# Ereignisprotokolle durchsuchen und die Ergebnisse in einer Variablen speichern
$events = Get-WinEvent -FilterHashtable $logFilter

# Ereignisse der letzten 3 Tage filtern
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
        $eventMessage = if ($event.Message.Length -gt 200) { 
            $event.Message.Substring(0, 200) + "..." 
        } else { 
            $event.Message 
        }

        # Ausgabe der Ereignisse
        Write-Output "Ereignis-ID: $eventId ($eventLevel), Anzahl: $($group.Count), Nachricht: $eventMessage"
        #Write-Output "Ebene: $eventLevel"
        #Write-Output "Nachricht: $eventMessage"
        #Write-Output "Anzahl: $($group.Count)"
        Write-Output "----------------------------------------"
    }
}


# Warten auf Benutzereingabe, bevor das Skript beendet wird
Write-Host "`nDrücken Sie die Enter-Taste, um das Skript zu beenden..."
$null = $Host.UI.RawUI.ReadKey('NoEcho,IncludeKeyDown')