<#
    Dieses Skript durchsucht die Ereignisprotokolle der letzten 30 Tage auf einem Windows-System und filtert Ereignisse 
    mit kritischem oder Fehler-Level (Level 1 und 2) aus den Logs 'Application', 'System' und 'Security'. Es zeigt die 
    Ereignisse der letzten 7 Tage an, gruppiert sie nach Ereignis-ID und Nachricht und listet alle Ereignisse auf, die 
    mehr als einmal aufgetreten sind.

    Was manuell angepasst werden muss:
    1. **$startDate**: Das Startdatum ist standardmäßig auf 30 Tage vor dem aktuellen Datum gesetzt. Falls du einen anderen Zeitraum 
       für die Ereignisabfrage benötigst, kann dieser Wert in der Zeile `$startDate = (Get-Date).AddDays(-30)` geändert werden.
    2. **$logFilter**: Du kannst die Lognamen (z. B. 'Application', 'System', 'Security') nach Bedarf anpassen, um spezifische 
       Log-Dateien zu durchsuchen. 
    3. **$recentEvents Filter**: Derzeit filtert das Skript Ereignisse der letzten 7 Tage. Falls du den Zeitraum ändern möchtest, 
       kannst du den Wert in `AddDays(-7)` anpassen.
    4. **Ereignismeldung**: Der Teil, der die Nachricht des Ereignisses auf die ersten 200 Zeichen begrenzt, kann geändert werden, 
       falls eine andere Anzahl von Zeichen gewünscht ist.

    Hinweis: Das Skript gibt eine Zusammenfassung von Ereignissen aus, die mehr als einmal aufgetreten sind. Die Anzahl 
    der Vorkommen wird zusammen mit der ID und einer verkürzten Nachricht angezeigt.

    Das Skript wartet am Ende auf eine Benutzereingabe (Enter), bevor es beendet wird.
#>


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
