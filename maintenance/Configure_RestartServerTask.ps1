# Überprüfen, ob das Skript mit Administratorrechten ausgeführt wird
if (-not ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole] "Administrator")) {
    Write-Host "Dieses Skript erfordert Administratorrechte. Bitte führen Sie es als Administrator aus."
    exit
}

# Name des geplanten Tasks
$TaskName = "ServerNeustart_19Uhr"

# Zielpfad für das Deaktivierungs-Skript
$ScriptFolder = "C:\Skripte"
$DisableScriptPath = "$ScriptFolder\DisableTaskAfterExecution.ps1"

# Falls der Ordner C:\Skripte nicht existiert, erstelle ihn
if (-not (Test-Path $ScriptFolder)) {
    New-Item -ItemType Directory -Path $ScriptFolder | Out-Null
    Write-Output "Der Ordner '$ScriptFolder' wurde erstellt."
}

# Überprüfen, ob der Task bereits existiert
$TaskExists = Get-ScheduledTask -TaskName $TaskName -ErrorAction SilentlyContinue

if ($null -eq $TaskExists) {
    Write-Output "Der geplante Task '$TaskName' existiert nicht. Er wird jetzt erstellt."

    # Erstelle einen Zeit-Trigger für 19:00 Uhr täglich
    $Trigger = New-ScheduledTaskTrigger -Daily -At 19:00

    # Erstelle eine Aktion zum Neustarten des Servers
    $Action = New-ScheduledTaskAction -Execute "shutdown.exe" -Argument "/r /t 60 /f"

    # Option: Der Task wird nach der ersten Ausführung deaktiviert
    $Settings = New-ScheduledTaskSettingsSet -AllowStartIfOnBatteries -DontStopIfGoingOnBatteries -StartWhenAvailable

    # Task registrieren (wird mit SYSTEM-Rechten ausgeführt)
    Register-ScheduledTask -TaskName $TaskName -Description "Startet den Server um 19:00 Uhr neu und deaktiviert sich danach." -Trigger $Trigger -Action $Action -Settings $Settings -RunLevel Highest -User "SYSTEM"

    Write-Output "Der geplante Task wurde erfolgreich erstellt."
} else {
    Write-Output "Der geplante Task '$TaskName' existiert bereits."
}

# Skript für die automatische Deaktivierung nach der ersten Ausführung erstellen
$DisableTaskScript = @"
# Warte 2 Minuten nach dem Neustart, um sicherzustellen, dass der Server stabil läuft
Start-Sleep -Seconds 120

# Deaktiviere den geplanten Task
Disable-ScheduledTask -TaskName "$TaskName"
Write-Output "Der geplante Task '$TaskName' wurde deaktiviert."
"@

# Speichere das Deaktivierungs-Skript unter C:\Skripte\DisableTaskAfterExecution.ps1
$DisableTaskScript | Set-Content -Path $DisableScriptPath -Encoding UTF8
Write-Output "Das Deaktivierungs-Skript wurde unter '$DisableScriptPath' gespeichert."

# Zweiten Task erstellen, um das Deaktivierungs-Skript nach dem Neustart auszuführen
$DisableTrigger = New-ScheduledTaskTrigger -AtStartup
$DisableAction = New-ScheduledTaskAction -Execute "powershell.exe" -Argument "-ExecutionPolicy Bypass -File `"$DisableScriptPath`""
Register-ScheduledTask -TaskName "Disable_$TaskName" -Description "Deaktiviert den Neustart-Task nach der ersten Ausführung." -Trigger $DisableTrigger -Action $DisableAction -RunLevel Highest -User "SYSTEM"

Write-Output "Ein zusätzlicher Task wurde erstellt, um den Neustart-Task nach der ersten Ausführung zu deaktivieren."

# Warten auf Benutzereingabe, bevor das Skript beendet wird
Write-Host "`nDrücken Sie die Enter-Taste, um das Skript zu beenden..."
$null = $Host.UI.RawUI.ReadKey('NoEcho,IncludeKeyDown')
