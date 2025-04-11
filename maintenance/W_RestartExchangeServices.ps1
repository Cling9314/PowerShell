Get-Service | Where-Object { $_.DisplayName -like "*Exchange*" -and $_.StartType -eq 'Automatic' } | Restart-Service
