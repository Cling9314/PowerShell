<#
    Dieses Skript überprüft, ob der Benutzer Administratorrechte hat, und führt dann die folgenden Schritte aus:

    1. **Administratorrechte**: Es wird überprüft, ob das Skript mit Administratorrechten ausgeführt wird. Falls nicht, wird der Benutzer aufgefordert, das Skript als Administrator auszuführen.
    2. **Überprüfung und Starten von automatisch startenden Diensten**: Das Skript durchsucht alle Dienste, die den Starttyp "Automatic" haben. 
       Wenn einer dieser Dienste nicht gestartet ist, wird er automatisch gestartet.
    3. **Auflisten der nicht gestarteten Dienste**: Falls es automatisch startende Dienste gibt, die noch nicht gestartet sind, werden diese am Ende des Skripts in einer Tabelle aufgelistet.
    4. **Benutzereingabe zum Beenden**: Das Skript wartet auf eine Benutzereingabe, bevor es beendet wird.

    Was manuell angepasst werden muss:
    1. **Starttyp**: Das Skript überprüft nur Dienste mit dem Starttyp "Automatic". Falls du auch manuell gestartete oder deaktivierte Dienste 
       einbeziehen möchtest, musst du die Filterbedingungen (`-eq 'Automatic'`) anpassen, z. B. auf `-eq 'Manual'` oder `-eq 'Disabled'`.
    2. **Benachrichtigung**: Wenn du eine andere Form der Benachrichtigung oder Ausgabe für nicht gestartete Dienste möchtest (z. B. E-Mail, Protokollierung), 
       kannst du die Ausgabe in der `Write-Host`-Anweisung anpassen.

    Hinweis: Das Skript kann auch in einer geplanten Aufgabe verwendet werden, um automatisch alle automatisch startenden Dienste zu überwachen und bei Bedarf zu starten.
#>

# Überprüfen, ob der Benutzer Administratorenrechte hat
if (-not ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole] "Administrator")) {
    Write-Host "Dieses Skript erfordert Administratorrechte. Bitte führen Sie es als Administrator aus."
    exit
}

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
    Write-Host "`nFolgende automatisch startende Dienste sind nicht gestartet:`n"
    $gestoppteDienste | Format-Table DisplayName, Status, StartType -AutoSize
} else {
    Write-Host "`nAlle automatisch startenden Dienste sind gestartet.`n"
}
# Warten auf Benutzereingabe, bevor das Skript beendet wird
Write-Host "`nDrücken Sie die Enter-Taste, um das Skript zu beenden..."
$null = $Host.UI.RawUI.ReadKey('NoEcho,IncludeKeyDown')
