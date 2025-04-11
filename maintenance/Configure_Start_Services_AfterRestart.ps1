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