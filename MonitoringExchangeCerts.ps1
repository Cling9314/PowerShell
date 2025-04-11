# Tage bis Ablauf
$warnungTage = 30
$zertAbgelaufenOderBald = $false

# Exchange Management Shell laden
if (-not (Get-PSSession | Where-Object { $_.ConfigurationName -eq 'Microsoft.Exchange' })) {
    try {
        Add-PSSnapin Microsoft.Exchange.Management.PowerShell.SnapIn -ErrorAction Stop
    } catch {
        try {
            $session = New-PSSession -ConfigurationName Microsoft.Exchange -ConnectionUri http://localhost/PowerShell/ -Authentication Kerberos
            Import-PSSession $session -DisableNameChecking -ErrorAction Stop
        } catch {
            Write-Host "Fehler beim Importieren der Exchange PowerShell-Umgebung." -ForegroundColor Red
            exit 2
        }
    }
}

# Zertifikate abrufen
try {
    $certs = Get-ExchangeCertificate
} catch {
    Write-Host "Fehler beim Abrufen der Exchange-Zertifikate." -ForegroundColor Red
    exit 2
}

# Header
Write-Host "`n--- Exchange-Zertifikate ---`n" -ForegroundColor Cyan
"{0,-40} {1,-40} {2,-15} {3,-10} {4}" -f "Thumbprint", "Subject", "Ablaufdatum", "Tage", "Dienste"
Write-Host ("-"*130)

foreach ($cert in $certs) {
    $tageBisAblauf = ($cert.NotAfter - (Get-Date)).Days
    $farbe = if ($tageBisAblauf -le $warnungTage) { "Red" } else { "Green" }

    $thumb = $cert.Thumbprint.Substring(0, [Math]::Min(40, $cert.Thumbprint.Length))
    $subject = ($cert.Subject -replace "CN=","")
    if ($subject.Length -gt 40) { $subject = $subject.Substring(0, 40) }

    $ablauf = $cert.NotAfter.ToString("yyyy-MM-dd")
    $dienste = if ($cert.Services) { $cert.Services -join "," } else { "-" }

    Write-Host ("{0,-40} {1,-40} {2,-15} {3,-10} {4}" -f `
        $thumb, $subject, $ablauf, $tageBisAblauf, $dienste) -ForegroundColor $farbe

    if ($tageBisAblauf -le $warnungTage) {
        $zertAbgelaufenOderBald = $true
    }
}

# Abschlussmeldung
Write-Host "`n============================="
if ($zertAbgelaufenOderBald) {
    Write-Host "Fehler: Mindestens ein Zertifikat läuft bald ab." -ForegroundColor Red
    exit 1
} else {
    Write-Host "In Ordnung: Alle Exchange-Zertifikate sind gültig." -ForegroundColor Green
    exit 0
}
