<#
    Dieses Skript überprüft und setzt die **PowerShell-Ausführungsrichtlinie** auf „RemoteSigned“ (wenn sie noch nicht gesetzt ist).
    Anschließend löscht es alle Log-Dateien, die älter als eine festgelegte Anzahl von Tagen sind, aus den angegebenen Log-Verzeichnissen.

    Was manuell angepasst werden muss:
    1. **Ausführungsrichtlinie**: Standardmäßig wird die Ausführungsrichtlinie auf „RemoteSigned“ gesetzt. Wenn du eine andere Richtlinie benötigst, 
       kannst du den Wert in der Zeile `Set-ExecutionPolicy RemoteSigned -Force` ändern (z. B. `Unrestricted`).
    2. **$days**: In der Variablen `$days` kannst du die Anzahl der Tage festlegen, nach denen Log-Dateien gelöscht werden sollen. Der Standardwert ist **1 Tag**.
    3. **Log-Pfade**: Du kannst die Log-Verzeichnisse anpassen:
       - **$IISLogPath**: Pfad zu den IIS-Protokollen (standardmäßig `C:\inetpub\logs\LogFiles\`).
       - **$ExchangeLoggingPath**: Pfad zu den Exchange-Server-Protokollen.
       - **$ETLLoggingPath** und **$ETLLoggingPath2**: Pfade zu den ETL-Log-Dateien von Exchange.
       
       Stelle sicher, dass diese Pfade auf deinem System korrekt sind.

    Hinweis: Das Skript löscht alle Log-Dateien mit den Erweiterungen `.log`, `.blg` und `.etl`, die älter sind als die in `$days` angegebene Anzahl von Tagen. 
    Dateien, die diesen Kriterien entsprechen, werden ohne Bestätigung gelöscht.
#>

# Set execution policy if not set
$ExecutionPolicy = Get-ExecutionPolicy
if ($ExecutionPolicy -ne "RemoteSigned") {
    Set-ExecutionPolicy RemoteSigned -Force
}

# Cleanup logs older than the set of days in numbers
$days = 1

# Path of the logs that you like to cleanup
$IISLogPath = "C:\inetpub\logs\LogFiles\"
$ExchangeLoggingPath = "E:\Exchange Server\Logging"
$ETLLoggingPath = "E:\Exchange Server\Bin\Search\Ceres\Diagnostics\ETLTraces\"
$ETLLoggingPath2 = "E:\Exchange Server\Bin\Search\Ceres\Diagnostics\Logs\"

# Clean the logs
Function CleanLogfiles($TargetFolder) {
    Write-Host -Debug -ForegroundColor Yellow -BackgroundColor Cyan $TargetFolder

    if (Test-Path $TargetFolder) {
        $Now = Get-Date
        $LastWrite = $Now.AddDays(-$days)
        $Files = Get-ChildItem $TargetFolder -Recurse | Where-Object { $_.Name -like "*.log" -or $_.Name -like "*.blg" -or $_.Name -like "*.etl" } | Where-Object { $_.lastWriteTime -le "$lastwrite" } | Select-Object FullName  
        foreach ($File in $Files) {
            $FullFileName = $File.FullName  
            Write-Host "Deleting file $FullFileName" -ForegroundColor "yellow"; 
            Remove-Item $FullFileName -ErrorAction SilentlyContinue | out-null
        }
    }
    Else {
        Write-Host "The folder $TargetFolder doesn't exist! Check the folder path!" -ForegroundColor "red"
    }
}
CleanLogfiles($IISLogPath)
CleanLogfiles($ExchangeLoggingPath)
CleanLogfiles($ETLLoggingPath)
CleanLogfiles($ETLLoggingPath2)
