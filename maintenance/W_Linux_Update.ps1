<#
    Dieses Skript führt automatisch die Befehle `apt update` und `apt upgrade` auf einem entfernten Linux-Server über SSH aus.
    Der Benutzer muss die IP-Adresse und den Benutzernamen des Linux-Servers angeben. Diese Informationen werden in einer JSON-Konfigurationsdatei 
    gespeichert, sodass sie bei späteren Ausführungen nicht erneut eingegeben werden müssen. Das Skript fragt außerdem das Passwort des Benutzers 
    für sudo-Rechte bei jedem Aufruf ab.

    Was manuell angepasst werden muss:
    1. **$scriptFolder**: Der Speicherort des Ordners für das Skript und die Konfigurationsdatei. Standardmäßig auf `C:\Skripte` gesetzt. 
       Ändere den Pfad, wenn der Ordner an einem anderen Ort gespeichert werden soll.
    2. **$configFile**: Der Pfad zur Konfigurationsdatei (`LinuxServerConfig.json`). Diese Datei speichert die IP-Adresse und den Benutzernamen des Servers. 
       Falls du einen anderen Speicherort oder Dateinamen verwenden möchtest, ändere diesen Pfad entsprechend.
    3. **SSH-Befehle**: Im Skript sind standardmäßig die Befehle `apt update` und `apt upgrade` für den Linux-Server vorgesehen. 
       Wenn du andere Befehle ausführen möchtest, kannst du die Variablen im Abschnitt `$sshCommand` anpassen.
       
    Hinweis: Das Skript erstellt die Konfigurationsdatei automatisch, wenn sie nicht vorhanden ist, und speichert die eingegebenen Werte. 
    Bei späteren Ausführungen wird die Konfiguration aus der Datei geladen, um die Eingabe der IP-Adresse und des Benutzernamens zu vermeiden.
#>

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
