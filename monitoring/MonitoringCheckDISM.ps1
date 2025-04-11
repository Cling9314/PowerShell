<# Anleitung

Damit das Skript ordnungsgemäß funktionieren kann, sollte über Aufgabenplanung alle 7 Tage DISM Scan durchgeführt werden. Ansonsten kann es vorkommen, 
dass die dism.log älter als 7 Tage ist und demzufolge keine aussagekräftigen Einträge enthält.

Das Skript erstellt die geplante Aufgabe automatisch, falls diese nicht vorhanden ist. Der geplante Tag/Uhrzeit kann im Nachgang manuell angepasst werden.
Gegebennenfalls sollte das Skript einmalig manuell mit Administratorrechten ausgeführt werden.


#>

# Pfad zur CBS.log Datei
$logFilePath = "C:\Windows\Logs\DISM\dism.log"

# Name des geplanten Tasks
$taskName = "DISM Wöchentlicher Wartungstask"

# Prüfe, ob der Task bereits existiert
$taskExists = Get-ScheduledTask -TaskName $taskName -ErrorAction SilentlyContinue

if (-not $taskExists) {
    # Task gibt es noch nicht, erstelle ihn

    # Erstelle den Trigger (jeden Sonntag um 05:00)
    $trigger = New-ScheduledTaskTrigger -Weekly -DaysOfWeek Sunday -At 06:00

    # Erstelle die erste Aktion (Löschen der Datei)
    $action1 = New-ScheduledTaskAction -Execute "cmd.exe" -Argument "/c del /f C:\Windows\Logs\DISM\dism.log"

    # Erstelle die zweite Aktion (sfc /verifyonly)
    $action2 = New-ScheduledTaskAction -Execute "cmd.exe" -Argument "/c dism /online /cleanup-image /scanhealth"

    # Erstelle den geplanten Task
    Register-ScheduledTask -Action $action1, $action2 -Trigger $trigger -TaskName $taskName -Description "Löscht DISM.log und führe DISM Scanhealth aus." -RunLevel Highest -User "SYSTEM"

    Write-Output "Der Task wurde erfolgreich erstellt."
}


# Überprüfen, ob die Datei existiert
if (-Not (Test-Path $logFilePath)) {
    Write-Output "Fehler: Die DISM.log Datei wurde nicht gefunden."
    exit 1
} else {
    Write-Output "In Ordnung: Die DISM.log Datei ist vorhanden und wird geprüft."
}


# Muster für spezifische Fehler in der DISM.log Datei
$errorPatterns = @(
    "The component store is repairable",
    "Error: 0x800f081f",
    "The source files could not be found",
    "The component store is corrupted"
)

# Überprüfen, ob einer der spezifischen Fehler in der DISM.log Datei vorhanden ist
$errorsFound = $false

foreach ($pattern in $errorPatterns) {
    if (Select-String -Path $logFilePath -Pattern $pattern -Quiet) {
        $errorsFound = $true
        break
    }
}

if ($errorsFound) {
    Write-Output "Fehler: Im DISM-Log wurden Meldungen gefunden!"
} else {
    Write-Output "In Ordnung: Im DISM-Log wurden keine relevanten Meldungen gefunden."
}

$errorLines = @()

if (Test-Path $logFilePath) {
    foreach ($pattern in $errorPatterns) {
        # Finde alle Zeilen, die das Muster enthalten
        $matchingLines = Select-String -Path $logFilePath -Pattern $pattern
        if ($matchingLines) {
            $errorsFound = $true
            $errorLines += $matchingLines  # Speichere die fehlerhaften Zeilen
        }
    }

    if ($errorsFound) {
        Write-Output "Fehler: Im DISM-Log wurden relevante Meldungen gefunden!"
        Write-Output "Fehlerhafte Zeilen:"
        foreach ($line in $errorLines) {
            Write-Output $line.Line  # Gib die spezifischen Fehlerzeilen aus
        }
    } else {
        Write-Output "In Ordnung: Im DISM-Log wurden keine relevanten Meldungen gefunden."
    }
} else {
    Write-Output "Fehler: DISM-Log nicht vorhanden"
}

exit
