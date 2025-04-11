# Definiere den Pfad zur Textdatei
$filepath = "c:\monitoring\MonitoringSynologyCheck.txt"

# Überprüfe, ob die Datei existiert
if (Test-Path $filepath) {
    # Lese den Inhalt der Datei
    $fileContent = Get-Content -Path $filepath
    
    # Gib den Inhalt der Datei aus
    Write-Output $fileContent
} else {
    Write-Output "Die Datei existiert nicht: $filepath"
}

exit
