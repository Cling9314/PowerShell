<#
    Dieses Skript überprüft, ob das PowerShell-Modul PSWindowsUpdate installiert ist und installiert es bei Bedarf. 
    Danach wird das Modul verwendet, um alle Windows-Updates von Microsoft und anderen Quellen zu installieren. 
    Das Skript führt zudem einen Fix für TLS-Protokolle durch, falls die Installation fehlschlägt.

    Was das Skript tut:
    1. **TLS-Protokoll Fix**: Das Skript stellt sicher, dass das TLS 1.2-Protokoll verwendet wird, um Kommunikationsprobleme zu vermeiden, die beim Herunterladen von Updates auftreten können.
    2. **PSWindowsUpdate-Modul überprüfen**: Es wird überprüft, ob das Modul `PSWindowsUpdate` installiert ist. Falls nicht, wird es automatisch installiert.
    3. **Windows Update durchführen**: Nach der Installation des Moduls wird es verwendet, um alle verfügbaren Updates von Microsoft und anderen Quellen zu listen und zu installieren.
    4. **Benutzereingabe zum Beenden**: Das Skript wartet auf eine Benutzereingabe (Enter-Taste), bevor es beendet wird.

    Was manuell angepasst werden muss:
    1. **Installationsquellen**: Der Befehl `Install-WindowsUpdate` akzeptiert verschiedene Parameter, die angepasst werden können. Wenn du nur bestimmte Updates installieren möchtest oder Updates von einer bestimmten Quelle ausschließen möchtest, kann der Befehl entsprechend angepasst werden.
    2. **Update-Strategie**: Das Skript akzeptiert alle Updates automatisch mit `-AcceptAll` und ignoriert Neustarts mit `-IgnoreReboot`. Falls du diese Optionen ändern möchtest, kannst du die Parameter anpassen.
    
    Hinweis: Dieses Skript eignet sich zur Aktualisierung von Windows-Servern oder -Clients, und sollte regelmäßig verwendet werden, um das System aktuell zu halten.
#>

 #For erster Ausführung folgenden Befehl eingeben:

# Falls Installation fehlschlägt, TLS fixen:
[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12

# Überprüfen, ob das PSWindowsUpdate-Modul installiert ist
if (-not (Get-Module -ListAvailable -Name PSWindowsUpdate)) {
    # Falls nicht installiert, versuche es zu installieren
    try {
        Write-Host "Das Modul PSWindowsUpdate wird installiert..."
        Install-Module -Name PSWindowsUpdate -Force -Confirm:$false
        Write-Host "Das Modul PSWindowsUpdate wurde erfolgreich installiert."
    } catch {
        Write-Error "Fehler beim Installieren des Moduls PSWindowsUpdate: $_"
    }
} else {
    Write-Host "Das Modul PSWindowsUpdate ist bereits installiert."
}

Add-WUServiceManager -ServiceID "7971f918-a847-4430-9279-4a52d1efe18d" -AddServiceFlag 7 -Confirm:$false


Import-Module PSWindowsUpdate
Get-WUList -MicrosoftUpdate
Install-WindowsUpdate -MicrosoftUpdate -AcceptAll -IgnoreReboot

# Warten auf Benutzereingabe, bevor das Skript beendet wird
Write-Host "`nDrücken Sie die Enter-Taste, um das Skript zu beenden..."
$null = $Host.UI.RawUI.ReadKey('NoEcho,IncludeKeyDown')
