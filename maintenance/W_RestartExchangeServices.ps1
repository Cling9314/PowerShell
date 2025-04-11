<#
    Dieses Skript sucht nach allen Exchange-Diensten, die den Namen „Exchange“ im DisplayName enthalten und deren Starttyp 
    auf „Automatisch“ gesetzt ist. Diese Dienste werden dann automatisch neu gestartet.

    Was manuell angepasst werden muss:
    1. **Dienstfilter**: Der Filter `*Exchange*` im `DisplayName` sucht nach allen Exchange-Diensten. Wenn du nach anderen Diensten suchen möchtest, 
       kannst du diesen Filter anpassen, um nach spezifischen Dienstnamen oder anderen Kriterien zu suchen.
    2. **Starttyp**: Das Skript filtert nur Dienste mit dem Starttyp „Automatic“. Falls du auch andere Starttypen einbeziehen möchtest, 
       kannst du die Bedingung `-and $_.StartType -eq 'Automatic'` ändern, um z. B. `-eq 'Manual'` oder `-eq 'Disabled'` zu verwenden.
       
    Hinweis: Das Skript startet die gefundenen Dienste neu, ohne nach einer Bestätigung zu fragen. Stelle sicher, dass du die Dienste neu starten möchtest,
    da dies Auswirkungen auf die Verfügbarkeit des Servers haben kann.
#>

 Get-Service | Where-Object { $_.DisplayName -like "*Exchange*" -and $_.StartType -eq 'Automatic' } | Restart-Service
