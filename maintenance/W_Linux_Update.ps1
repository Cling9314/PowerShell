# Speicherort der Konfigurationsdatei
$scriptFolder = "C:\Skripte"
$configFile = "$scriptFolder\LinuxServerConfig.json"

# Falls der Ordner C:\Skripte nicht existiert, erstelle ihn
if (-not (Test-Path $scriptFolder)) {
    New-Item -ItemType Directory -Path $scriptFolder | Out-Null
    Write-Output "Der Ordner '$scriptFolder' wurde erstellt."
}

# Überprüfen, ob die Konfigurationsdatei existiert
if (Test-Path $configFile) {
    # Konfiguration aus der Datei laden
    $config = Get-Content -Path $configFile | ConvertFrom-Json
    $ipAddress = $config.IP
    $username = $config.Username
} else {
    # Erster Benutzeraufruf, IP-Adresse und Benutzername abfragen
    $ipAddress = Read-Host "Bitte geben Sie die IP-Adresse des Linux-Servers ein"
    $username = Read-Host "Bitte geben Sie den Benutzernamen des Linux-Servers ein"

    # Speichern der Eingaben in der Konfigurationsdatei
    $config = @{
        IP = $ipAddress
        Username = $username
    }

    $config | ConvertTo-Json | Set-Content -Path $configFile
}

# Passwort für sudo bei jedem Aufruf abfragen
$password = Read-Host "Bitte geben Sie das Passwort für den Benutzer $username auf $ipAddress ein" -AsSecureString

# Die SSH-Verbindung und Befehlsausführung mit PowerShell SSH
$sshCommand = {
    # Führen Sie die sudo-Befehle aus
    sudo apt update -y
    sudo apt upgrade -y
}

# Erstellen der SSH-Verbindung und Ausführen der Befehle
$credential = New-Object System.Management.Automation.PSCredential($username, $password)
$sshConnection = New-PSSession -HostName $ipAddress -UserName $username -Password $password -Port 22

# Auf dem Remote-Server Befehle ausführen
Invoke-Command -Session $sshConnection -ScriptBlock $sshCommand

# Schließen der SSH-Verbindung
Remove-PSSession -Session $sshConnection

Write-Host "Die Befehle 'apt update' und 'apt upgrade' wurden erfolgreich ausgeführt."

# Benutzerbestätigung abfragen, bevor das Skript beendet wird
$confirmation = Read-Host "Drücken Sie Enter, um das Skript zu beenden."
