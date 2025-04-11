<#
    Dieses Skript überprüft, ob verschiedene Softwareprodukte installiert sind (MS Office, Google Chrome, Mozilla Firefox, Microsoft Edge, Adobe Acrobat) 
    und führt dann jeweils die verfügbaren Updates für diese Produkte durch.

    1. **MS Office**: Das Skript prüft, ob MS Office installiert ist, und führt dann die Aktualisierung mit dem „OfficeC2RClient.exe“ aus, wenn es gefunden wird.
    2. **Google Chrome**: Es prüft, ob Google Chrome installiert ist, und startet dann den Update-Prozess.
    3. **Mozilla Firefox**: Es prüft, ob Mozilla Firefox installiert ist, und führt die Aktualisierung über die Befehlszeile aus.
    4. **Microsoft Edge**: Das Skript prüft, ob Microsoft Edge installiert ist, und führt die Aktualisierung mit dem entsprechenden Argument aus.
    5. **Adobe Acrobat**: Es prüft, ob Adobe Acrobat installiert ist und startet den Adobe Acrobat Updater, um die Software zu aktualisieren.

    Was manuell angepasst werden muss:
    1. **Installationspfade**: Die Pfade zu den Programmen (z. B. MS Office, Chrome, Firefox, Edge, Acrobat) sind auf Standard-Installationspfade eingestellt. 
       Falls die Software an einem anderen Ort installiert ist, musst du die Pfade zu den jeweiligen Programmen anpassen.
    2. **Update-Methoden**: Die Update-Methoden für die einzelnen Programme sind spezifisch für die jeweilige Software. Wenn eine andere Methode erforderlich ist, 
       solltest du die Argumente oder die Art und Weise, wie das Update durchgeführt wird, ändern.
    3. **Adobe Acrobat Pfad**: Der Pfad für Adobe Acrobat wird über die Registrierung ausgelesen. Falls die Software nicht korrekt registriert ist oder 
       sich in einem anderen Zweig der Registrierung befindet, kann dies angepasst werden.

    Hinweis: Das Skript führt die Updates ohne Benutzerinteraktion aus. Stelle sicher, dass die Programme korrekt installiert und konfiguriert sind, 
    bevor du das Skript ausführst.
#>

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
