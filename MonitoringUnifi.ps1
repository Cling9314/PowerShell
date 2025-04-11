# Definiere die IP-Adresse des UniFi Controllers
$controllerIp = "192.168.10.217"
$sshUsername = "monitoring"  # Ersetze mit deinem SSH-Benutzernamen
$sshPassword = "?M+k.uNfY%807%nSC4u&nT"    # Ersetze mit deinem SSH-Passwort

# Funktion zur Überprüfung, ob die IP-Adresse erreichbar ist
function Test-Ping {
    param (
        [string]$ip
    )
    
    Write-Host "Überprüfe, ob die IP-Adresse $ip erreichbar ist..." -ForegroundColor Cyan
    if (Test-Connection -ComputerName $ip -Count 2 -Quiet) {
        Write-Host "In Ordnung: Die IP-Adresse $ip ist erreichbar." -ForegroundColor Green
    } else {
        Write-Host "Fehler: Die IP-Adresse $ip ist NICHT erreichbar." -ForegroundColor Red
        exit 1
    }
}

# Funktion zur Überprüfung, ob der UniFi-Dienst läuft (über SSH)
function Check-UniFiService {
    param (
        [string]$ip,
        [string]$username,
        [string]$password
    )
    
    Write-Host "Überprüfe den Status des UniFi-Dienstes auf $ip..." -ForegroundColor Cyan

    try {
        # Erstelle eine SSH-Verbindung über Posh-SSH
        $securePassword = ConvertTo-SecureString $password -AsPlainText -Force
        $credential = New-Object System.Management.Automation.PSCredential ($username, $securePassword)

        # Installiere das Posh-SSH-Modul, falls nicht vorhanden
        if (-not (Get-Module -ListAvailable -Name Posh-SSH)) {
            Install-Module -Name Posh-SSH -Force -Scope CurrentUser
        }
        
        Import-Module Posh-SSH

        # Verbinde zum Server
        $session = New-SSHSession -ComputerName $ip -Credential $credential

        # Führe den Befehl aus, um den UniFi-Dienststatus zu überprüfen
        $command = "systemctl is-active unifi"
        $result = Invoke-SSHCommand -SessionId $session.SessionId -Command $command

        if ($result.Output -eq "active") {
            Write-Host "In Ordnung: Der UniFi-Dienst läuft." -ForegroundColor Green
        } else {
            Write-Host "Fehler: Der UniFi-Dienst läuft NICHT! Status: $($result.Output)" -ForegroundColor Red
        }

        # Schließe die SSH-Verbindung
        Remove-SSHSession -SessionId $session.SessionId
    }
    catch {
        Write-Host "Fehler beim Überprüfen des UniFi-Dienstes: $_" -ForegroundColor Red
    }
}

# Funktion zur Überprüfung, ob Updates für den UniFi Controller vorhanden sind
function Check-UniFiUpdates {
    param (
        [string]$ip,
        [string]$username,
        [string]$password
    )

    Write-Host "Überprüfe, ob Updates für den UniFi Controller auf $ip vorhanden sind..." -ForegroundColor Cyan

    try {
        # Erstelle eine SSH-Verbindung über Posh-SSH
        $securePassword = ConvertTo-SecureString $password -AsPlainText -Force
        $credential = New-Object System.Management.Automation.PSCredential ($username, $securePassword)

        # Verbinde zum Server
        $session = New-SSHSession -ComputerName $ip -Credential $credential

        # Führe den Befehl aus, um verfügbare Updates zu überprüfen
        $command = "apt list --upgradable"
        $result = Invoke-SSHCommand -SessionId $session.SessionId -Command $command

        # Überprüfe, ob Updates vorhanden sind
        if ($result.Output -match "unifi") {
            Write-Host "Warnung: Es sind Updates für den UniFi Controller verfügbar:" -ForegroundColor Yellow
            Write-Host $result.Output -ForegroundColor Yellow
        } else {
            Write-Host "In Ordnung: Keine Updates für den UniFi Controller verfügbar." -ForegroundColor Green
        }

        # Schließe die SSH-Verbindung
        Remove-SSHSession -SessionId $session.SessionId
    }
    catch {
        Write-Host "Fehler beim Überprüfen der Updates: $_" -ForegroundColor Red
    }
}

# Hauptskript
Test-Ping -ip $controllerIp
Check-UniFiService -ip $controllerIp -username $sshUsername -password $sshPassword
#Check-UniFiUpdates -ip $controllerIp -username $sshUsername -password $sshPassword

exit