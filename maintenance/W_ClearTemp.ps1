# Pfad zum Hauptbenutzerverzeichnis (in der Regel C:\Users)
$usersPath = "C:\Users"

# Alle Benutzerverzeichnisse abrufen
$users = Get-ChildItem -Path $usersPath | Where-Object { $_.PSIsContainer -and $_.Name -ne "Public" -and $_.Name -ne "Default" -and $_.Name -ne "DefaultAppPool" }

# Schleife durch jeden Benutzerordner
foreach ($user in $users) {
    # Temp-Ordner für den aktuellen Benutzer
    $tempFolder = "$($user.FullName)\AppData\Local\Temp"

    # Überprüfen, ob der Temp-Ordner existiert
    if (Test-Path -Path $tempFolder) {
        # Dateien im Temp-Ordner abrufen, die älter als 4 Wochen sind
        $filesToDelete = Get-ChildItem -Path $tempFolder -Recurse -Force | Where-Object { $_.LastWriteTime -lt (Get-Date).AddDays(-28) }

        # Überprüfen, ob es Dateien gibt, die gelöscht werden können
        if ($filesToDelete) {
            foreach ($file in $filesToDelete) {
                try {
                    # Lösche jede Datei, die älter als 4 Wochen ist
                    Remove-Item -Path $file.FullName -Force -ErrorAction Stop
                    Write-Host "Datei $($file.FullName) erfolgreich gelöscht." -ForegroundColor Green
                } catch {
                    Write-Host "Fehler beim Löschen der Datei $($file.FullName): $_" -ForegroundColor Red
                }
            }
        } else {
            Write-Host "Keine Dateien zum Löschen gefunden für Benutzer $($user.Name)." -ForegroundColor Yellow
        }
    } else {
        Write-Host "Temp-Ordner für Benutzer $($user.Name) nicht gefunden." -ForegroundColor Yellow
    }
}
