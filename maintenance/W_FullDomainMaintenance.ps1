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