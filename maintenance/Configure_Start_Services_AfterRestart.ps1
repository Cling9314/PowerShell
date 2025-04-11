﻿<#
Dieses Skript überprüft, ob es mit Administratorrechten ausgeführt wird. Wenn nicht, wird es beendet und fordert den Benutzer auf, das Skript mit Administratorrechten zu starten.
WICHTIG: Das Skript muss mit Administratorrechten ausgeführt werden, da es geplante Aufgaben registrieren und Systemdienste starten soll.

Der Zielordner für das Skript und das geplante Task-Skript ist "C:\Skripte". Falls dieser Ordner nicht existiert, wird er erstellt.
WICHTIG: Stellen Sie sicher, dass der Pfad C:\Skripte für Ihre Umgebung korrekt ist, oder passen Sie den Pfad an, falls erforderlich.

Der geplante Task, der das Dienststart-Skript ausführt, wird überprüft, ob er bereits existiert. Wenn der Task noch nicht existiert, wird er erstellt.
Der Task wird so konfiguriert, dass er beim Systemstart ausgeführt wird und das Dienststart-Skript (StartServices.ps1) ausführt.
Der Task wird mit SYSTEM-Berechtigungen registriert, was bedeutet, dass er mit höchsten Privilegien ausgeführt wird.
WICHTIG: Der Name des geplanten Tasks ist "Start_AutoServices". Dieser Name kann bei Bedarf angepasst werden.

Das Skript, das automatisch startende Dienste überprüft und startet, wird ebenfalls erstellt.
Es überprüft alle Dienste, deren Starttyp auf 'Automatic' gesetzt ist und startet diese, falls sie nicht bereits laufen.
Falls automatisch startende Dienste gestoppt sind, werden sie in einer Tabelle angezeigt.
Das Skript wird unter C:\Skripte\StartServices.ps1 gespeichert. Wenn Sie einen anderen Speicherort möchten, passen Sie den Pfad entsprechend an.

Zum Schluss wartet das Skript auf eine Benutzereingabe, bevor es beendet wird. Dies verhindert, dass das Skript sofort nach Ausführung schließt.
Wenn das Skript abgeschlossen ist, drücken Sie die Enter-Taste, um den Vorgang zu beenden.

MANUELLE ANPASSUNGEN:
- Wenn der Ordner C:\Skripte bereits existiert oder ein anderer Pfad gewünscht wird, passen Sie den Wert von $ScriptFolder an.
- Falls der Name des geplanten Tasks ("Start_AutoServices") oder die geplante Aktion (Starten des Dienststart-Skripts) geändert werden soll, passen Sie die Variablen $TaskName und $Action entsprechend an.
- Passen Sie bei Bedarf den Pfad des Dienststart-Skripts (StartServices.ps1) an, falls es in einem anderen Verzeichnis gespeichert werden soll.
#>
 
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

# Überprüfen, ob der geplante Task bereits existiert
$TaskExists = Get-ScheduledTask -TaskName $TaskName -ErrorAction SilentlyContinue

if ($null -eq $TaskExists) {
    Write-Output "Der geplante Task '$TaskName' existiert nicht. Er wird jetzt erstellt."

    # Erstelle einen Start-Trigger (direkt nach Systemstart)
    $Trigger = New-ScheduledTaskTrigger -AtStartup

    # Erstelle eine Aktion zum Ausführen des Skripts
    $Action = New-ScheduledTaskAction -Execute "powershell.exe" -Argument "-ExecutionPolicy Bypass -File `"$ScriptPath`""

    # Erstelle den Task mit SYSTEM-Berechtigungen
    Register-ScheduledTask -TaskName $TaskName -Description "Überprüft und startet automatisch startende Dienste." -Trigger $Trigger -Action $Action -RunLevel Highest -User "SYSTEM"

    Write-Output "Der geplante Task wurde erfolgreich erstellt."
} else {
    Write-Output "Der geplante Task '$TaskName' existiert bereits."
}

# Erstelle das Dienststart-Skript
$ServiceScript = @'
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

# Warten auf Benutzereingabe, bevor das Skript beendet wird
Write-Host "`nDrücken Sie die Enter-Taste, um das Skript zu beenden..."
$null = $Host.UI.RawUI.ReadKey('NoEcho,IncludeKeyDown')
