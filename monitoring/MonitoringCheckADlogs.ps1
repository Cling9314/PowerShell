# Definieren Sie den Startzeitpunkt (1 Stunde zurück)
$st = (Get-Date).AddHours(-1)

# Liste der Ereignis-IDs, die gefiltert werden sollen (häufig kritische IDs auf Windows Servern)
$eventsToFilter = "1221", "1306", "1311", "1358", "1566", "1586", "1645", "1864", "1865", "1866", "1898", "2042", "4000", "4001", "4002", "4004", "4010", "4011", "4013", "4017", "4018", "5000", "5002", "5004", "5014", "5015", "5057", "5501", "7011", "7050", "7053"

# Funktion zum Überprüfen und Anzeigen von Ereignissen
function Check-EventLogs {
    param (
        [string[]]$LogNames,
        [string[]]$FilterIDs,
        [datetime]$StartTime
    )

    $eventsFound = $false

    foreach ($logName in $LogNames) {
        # Überprüfen, ob das Log existiert
        if (Get-WinEvent -ListLog $logName -ErrorAction SilentlyContinue) {
            $events = Get-WinEvent -ErrorAction SilentlyContinue -FilterHashtable @{
                LogName = $logName
                Level = 2, 3
                StartTime = $StartTime
            }

            $filteredEvents = $events | Where-Object {
                $FilterIDs -contains $_.Id
            }

            if ($filteredEvents) {
                $eventsFound = $true
                Write-Output "Ereignisse im Log '$logName':"
                $filteredEvents | Format-Table TimeCreated, Id, Message -AutoSize
            }
        }
    }

    if (-not $eventsFound) {
        Write-Output "In Ordnung: Es wurden keine Meldungen innerhalb der letzten Stunde festgestellt."
    }
}

# Die zu überprüfenden Logs
$logNames = @("DFS Replication", "Directory Service", "DNS Server", "DHCP Server")

# Aufruf der Funktion
Check-EventLogs -LogNames $logNames -FilterIDs $eventsToFilter -StartTime $st
