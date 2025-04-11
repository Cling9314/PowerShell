
# Liste von Diensten, die ignoriert werden sollen
# Abfrage im Monitoring:
# enthält "In Ordnung"
# enthält nicht "Fehler"

# Liste von Diensten, die ignoriert werden sollen
$IgnoredServices = @(
    "AGSService",
    "sppsvc",
    "edgeupdate",
    "RemoteRegistry",
    "GoogleUpdaterInternalService136.0.7079.0",
    "GoogleUpdaterService136.0.7079.0",
    "iphlpsvc",
    "gupdate",     
    "gupdatem"
)

# Alle Dienste abrufen, die auf "Automatisch" eingestellt sind
$AutoServices = Get-Service | Where-Object { $_.StartType -eq 'Automatic' -and $_.Name -notin $IgnoredServices }

# Prüfen, ob die Dienste laufen
$StoppedServices = $AutoServices | Where-Object { $_.Status -ne 'Running' }

if ($StoppedServices.Count -gt 0) {
    Write-Host "Fehler. Die folgenden automatisch startenden Dienste sind nicht gestartet:" -ForegroundColor Red
    $StoppedServices | ForEach-Object { Write-Host $_.Name -ForegroundColor Yellow }
} else {
    Write-Host "In Ordnung. Alle automatisch startenden Dienste laufen." -ForegroundColor Green
}
