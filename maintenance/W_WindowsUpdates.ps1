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