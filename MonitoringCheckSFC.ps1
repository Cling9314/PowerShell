<# Anleitung

Damit das Skript ordnungsgemäß funktionieren kann, sollte über die Aufgabenplanung jeden Sonntag um 04:00 Uhr "sfc /verifyonly" ausgeführt werden. Falls die Aufgabe noch nicht existiert, erstellt das Skript sie automatisch. Das Skript sollte einmalig mit Administratorrechten ausgeführt werden.

#>

# Pfad zur CBS.log Datei
$logFilePath = "C:\Windows\Logs\CBS\CBS.log"

# Name des geplanten Tasks
$taskName = "SFC Wöchentlicher Wartungstask"

# Prüfe, ob der Task bereits existiert
$taskExists = Get-ScheduledTask -TaskName $taskName -ErrorAction SilentlyContinue

if (-not $taskExists) {
    # Task gibt es noch nicht, erstelle ihn

    # Erstelle den Trigger (jeden Sonntag um 04:00)
    $trigger = New-ScheduledTaskTrigger -Weekly -DaysOfWeek Sunday -At 04:00

    # Erstelle die Aktion (sfc /verifyonly)
    $action = New-ScheduledTaskAction -Execute "cmd.exe" -Argument "/c sfc /verifyonly"

    # Erstelle den geplanten Task
    Register-ScheduledTask -Action $action -Trigger $trigger -TaskName $taskName -Description "Führt sfc /verifyonly aus" -RunLevel Highest -User "SYSTEM"

    Write-Output "Der Task wurde erfolgreich erstellt."
}

# Überprüfen, ob die Datei existiert
if (-Not (Test-Path $logFilePath)) {
    Write-Output "Fehler: Die CBS.log Datei wurde nicht gefunden."
    exit 1
} else {
    Write-Output "In Ordnung: Die CBS.log Datei ist vorhanden und wird geprüft."
}

# Muster für spezifische Fehler in der CBS.log Datei
$errorPatterns = @(
    "found integrity violations",
    "could not perform the requested operation",
    "Cannot repair",
    "Hash mismatch",
    "Repair failed",
    "Corrupt file",
    "Could not reproject corrupted file",
    "Failed to find the root cause of corruption",
    "COMPONENT_STORE_CORRUPT"
)

# Überprüfen, ob einer der spezifischen Fehler in der CBS.log Datei vorhanden ist
$errorsFound = $false
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
        Write-Output "Fehler: Im CBS-Log wurden relevante Meldungen gefunden!"
        Write-Output "Fehlerhafte Zeilen:"
        foreach ($line in $errorLines) {
            Write-Output $line.Line  # Gib die spezifischen Fehlerzeilen aus
        }
    } else {
        Write-Output "In Ordnung: Im CBS-Log wurden keine relevanten Meldungen gefunden."
    }
} else {
    Write-Output "Fehler: CBS-Log nicht vorhanden"
}

exit