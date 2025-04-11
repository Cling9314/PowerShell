# Funktion zur Überprüfung und Aktualisierung von MS Office

    Write-Host "Prüfe, ob MS Office installiert ist..."
    $officePath = "C:\Program Files\Common Files\Microsoft Shared\ClickToRun\OfficeC2RClient.exe"
    if (Test-Path $officePath) {
        Write-Host "MS Office ist installiert. Führe Aktualisierung durch..."
        Start-Process $officePath -ArgumentList "/update" -Wait
        Write-Host "MS Office wurde aktualisiert."
    } else {
        Write-Host "MS Office ist nicht installiert."
    }
    
# Check for installed browsers and update them
$installedBrowsers = @()

# Check for Google Chrome
$chromePath = "C:\Program Files\Google\Chrome\Application\chrome.exe"
if (Test-Path $chromePath) {
    $installedBrowsers += "Google Chrome"
    Write-Output "Google Chrome is installed."
    Write-Output "Updating Google Chrome..."
    & "$chromePath" --headless --disable-gpu --remote-debugging-port=9222 --user-data-dir="C:\temp" --check-for-update
    Write-Output "Google Chrome update initiated."
} else {
    Write-Output "Google Chrome is not installed."
}

# Check for Mozilla Firefox
$firefoxPath = "C:\Program Files\Mozilla Firefox\firefox.exe"
$firefoxPath = "C:\Program Files (x86)\Mozilla Firefox\firefox.exe"

if (Test-Path $firefoxPath) {
    $installedBrowsers += "Mozilla Firefox"
    Write-Output "Mozilla Firefox is installed."
    Write-Output "Updating Mozilla Firefox..."
    Start-Process "$firefoxPath" -ArgumentList "-silent -update" -Wait
    Write-Output "Mozilla Firefox update initiated."
} else {
    Write-Output "Mozilla Firefox is not installed."
}

# Check for Microsoft Edge
$edgePath = "C:\Program Files (x86)\Microsoft\Edge\Application\msedge.exe"
if (Test-Path $edgePath) {
    $installedBrowsers += "Microsoft Edge"
    Write-Output "Microsoft Edge is installed."
    Write-Output "Updating Microsoft Edge..."
    Start-Process "$edgePath" -ArgumentList "--check-for-update" -Wait
    Write-Output "Microsoft Edge update initiated."
} else {
    Write-Output "Microsoft Edge is not installed."
}

# Output installed browsers
if ($installedBrowsers.Count -gt 0) {
    Write-Output "Installed Browsers: $installedBrowsers"
} else {
    Write-Output "No known browsers are installed."
}

# Check if Adobe Acrobat is installed and update
$acrobatPath = Get-ItemProperty -Path "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall\*" | Where-Object { $_.DisplayName -like "*Adobe Acrobat*" } | Select-Object -ExpandProperty InstallLocation -ErrorAction SilentlyContinue

if ($acrobatPath) {
    Write-Output "Adobe Acrobat is installed."
    $acrobatUpdater = Join-Path $acrobatPath "Acrobat\Acrobat.exe"
    if (Test-Path $acrobatUpdater) {
        Write-Output "Updating Adobe Acrobat..."
        Start-Process "$acrobatUpdater" -ArgumentList "/update" -Wait
        Write-Output "Adobe Acrobat updated successfully."
    } else {
        Write-Output "Adobe Acrobat updater not found. Update skipped."
    }
} else {
    Write-Output "Adobe Acrobat is not installed."
}
