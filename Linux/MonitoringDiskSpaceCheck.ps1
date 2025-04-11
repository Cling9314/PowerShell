# Posh-SSH Modul importieren
Import-Module Posh-SSH

# SSH-Verbindungsinformationen
# !!! Erstelle unbedingt vorher den Benutzer "monitoring" oder ähnlich auf deinem Linux Server und hinterlege unter username und password hier die Anmeldeinformationen
$remoteIP = "IP-ADRESSE"
$username = "BENUTZERNAME"
$password = ConvertTo-SecureString "SICHERES-PASSWORT" -AsPlainText -Force
$credential = New-Object System.Management.Automation.PSCredential($username, $password)

# Befehl zur Überprüfung der Festplattenauslastung
$diskUsageCommand = "df -h /"

# SSH-Verbindung herstellen und Befehl ausführen
$session = New-SSHSession -ComputerName $remoteIP -Credential $credential
$output = Invoke-SSHCommand -SessionId $session.SessionId -Command $diskUsageCommand
Remove-SSHSession -SessionId $session.SessionId

# Ausgabe analysieren
foreach ($line in $output.Output) {
    if ($line -match "/dev/") {
        $parts = $line -split "\s+"
        $filesystem = $parts[0]
        $size = $parts[1]
        $used = $parts[2]
        $avail = $parts[3]
        $usePercentage = $parts[4]
        $mountedOn = $parts[5]

        # Prozentualen freien Speicherplatz berechnen
        $freePercentage = 100 - [int]($usePercentage.TrimEnd('%'))

        # Warnung oder kritische Meldung ausgeben
        if ($freePercentage -lt 5) {
            
            "Kritisch: Weniger als 5% freier Speicherplatz auf $filesystem ($mountedOn)." | set-content C:\Monitoring\discSpace.txt
        } elseif ($freePercentage -lt 10) {
            "Warnung: Weniger als 10% freier Speicherplatz auf $filesystem ($mountedOn)." | set-content C:\Monitoring\discSpace.txt
        } else {
            "Alles in Ordnung: $freePercentage% freier Speicherplatz auf $filesystem ($mountedOn)." | set-content C:\Monitoring\discSpace.txt
        }
    }
}
