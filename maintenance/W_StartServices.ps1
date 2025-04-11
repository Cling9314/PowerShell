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