# Überprüfen, ob das Skript mit Administratorrechten ausgeführt wird
if (-not ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole] "Administrator")) {
    Write-Host "Dieses Skript erfordert Administratorrechte. Bitte führen Sie es als Administrator aus."
    exit
}

# Name des geplanten Tasks
$TaskName = "ServerNeustart_19Uhr"

# Überprüfen, ob der Task existiert
$TaskExists = Get-ScheduledTask -TaskName $TaskName -ErrorAction SilentlyContinue

if ($null -ne $TaskExists) {
    # Task aktivieren
    Enable-ScheduledTask -TaskName $TaskName
    Write-Output "Der geplante Task '$TaskName' wurde erfolgreich aktiviert."
} else {
    Write-Output "Der geplante Task '$TaskName' wurde nicht gefunden."
}

