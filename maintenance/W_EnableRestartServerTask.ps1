<#
    Dieses Skript überprüft, ob es mit **Administratorrechten** ausgeführt wird. Falls nicht, wird eine Fehlermeldung ausgegeben
    und das Skript beendet. Wenn das Skript mit Administratorrechten ausgeführt wird, sucht es nach einem geplanten Task 
    mit dem angegebenen Namen und aktiviert ihn, falls er gefunden wird.

    Was manuell angepasst werden muss:
    1. **$TaskName**: Der Name des geplanten Tasks, der aktiviert werden soll. Der Standardname im Skript ist „ServerNeustart_19Uhr“.
       Wenn der geplante Task einen anderen Namen hat, ändere die Variable `$TaskName` entsprechend.
       
    Hinweis: Das Skript prüft, ob der Task mit dem angegebenen Namen existiert. Wenn der Task gefunden wird, wird er aktiviert. 
    Andernfalls wird eine Nachricht ausgegeben, dass der Task nicht gefunden wurde.
#>

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

