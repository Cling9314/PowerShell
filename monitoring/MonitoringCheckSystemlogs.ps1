# Definieren Sie den Startzeitpunkt (1 Stunde zurück)
$st = (Get-Date).AddHours(-1)

# Liste der Ereignis-IDs, die ignoriert werden sollen
$eventsToIgnore = @()  # In der aktuellen Konfiguration gibt es keine IDs zum Ignorieren

# Liste der Ereignis-IDs, die gefiltert werden sollen
$eventsToFilter = "41", "55", "6008", "1018", "7011", "1033", "4625", "4672", "4688", "4648", "4670", "2004", "1500"

#"41" - Kernel-Power (Unerwartetes Herunterfahren)
#"55" - NTFS (Dateisystemfehler)
#"6008" - Event Log (Unerwartetes Herunterfahren)
#"1016" - DistributedCOM (Fehler bei DCOM-Kommunikation)
#"1033" - WHEA-Logger (Hardwarefehler)
#"7023" - Service Control Manager (Dienstfehler)
#"4625" - Security (Anmeldefehler)
#"4634" - Security (Abmeldung)
#"4672" - Security (Besondere Berechtigungen)
#"4688" - Security (Prozess erstellt)
#"4648" - Security (Anmeldeversuch mit expliziten Anmeldeinformationen)
#"4670" - Security (Berechtigungen geändert)
#"1000" - Application Error (Allgemeiner Anwendungsfehler)
#"1026" - .NET Runtime (Fehler in .NET-Anwendung)
#"1001" - Windows Error Reporting (Fehlerbericht)
#"2004" - Microsoft-Windows-Wininit (Fehler beim Initialisieren von Windows)
#"1500" - User Profile Service (Fehler beim Laden oder Erstellen eines Benutzerprofils)
#"2005" - Service Control Manager (Dienstprobleme)
#"1018" - Disk (Fehler beim Zugriff auf Datenträger)
#"7000" - Service Control Manager (Dienst konnte nicht gestartet werden)
#"7011" - Service Control Manager (Dienst hat nicht reagiert)
#"164" - System (Verschiedene Systemereignisse)



# Funktion zum Überprüfen und Anzeigen von Ereignissen
function Check-EventLogs {
    param (
        [string[]]$LogNames,
        [string[]]$FilterIDs,
        [string[]]$IgnoreIDs,
        [datetime]$StartTime
    )

    $eventsFound = $false

    foreach ($logName in $LogNames) {
        $events = Get-WinEvent -ErrorAction SilentlyContinue -FilterHashtable @{
            LogName = $logName
            Level = 2, 3
            StartTime = $StartTime
        }

        $filteredEvents = $events | Where-Object {
            $FilterIDs -contains $_.Id -and -not ($IgnoreIDs -contains $_.Id)
        }

        if ($filteredEvents) {
            $eventsFound = $true
            $filteredEvents | Format-Table TimeCreated, Id, Message -AutoSize
        }
    }

    if (-not $eventsFound) {
        Write-Output "In Ordnung: Es wurden keine Meldungen innerhalb der letzten Stunde festgestellt."
    }
}

# Die zu überprüfenden Logs
$logNames = @("System", "Security", "Application")

# Aufruf der Funktion
Check-EventLogs -LogNames $logNames -FilterIDs $eventsToFilter -IgnoreIDs $eventsToIgnore -StartTime $st

exit
