# Skript zum Überprüfen der Hyper-V-Replikationen und Statusmeldungen

# Funktion zum Überprüfen des Replikationsstatus einer einzelnen VM
function Check-ReplicationStatus {
    param (
        [Parameter(Mandatory=$true)]
        [string]$VMName
    )
    
    # Hole die Replikationsinformationen der VM
    $replicationInfo = Get-VMReplication -VMName $VMName
    
    if ($replicationInfo) {
        # Status der Replikation ausgeben
        Write-Host "VM: $VMName"
        Write-Host "Replikationsstatus: $($replicationInfo.ReplicationHealth)"
        Write-Host "Letzte erfolgreiche Replikation: $($replicationInfo.ReplicationLastSucceededTime)"
        Write-Host "Letztes Replikationsfehlerdatum: $($replicationInfo.ReplicationLastFailedTime)"
        
        # Prüfen, ob Fehler vorhanden sind
        if ($replicationInfo.ReplicationHealth -ne 'Normal') {
            Write-Host "Fehler: Replikation der VM '$VMName' ist nicht normal. Details:"
            Write-Host "Fehlercode: $($replicationInfo.ReplicationHealth)"
        } else {
            Write-Host "In Ordnung: Replikation für VM '$VMName' ist erfolgreich."
        }
    } else {
        Write-Host "In Ordnung: VM '$VMName' hat keine konfigurierte Replikation."
    }

    Write-Host "-----------------------------------------"
}

# Hole alle VMs, die auf dem Hyper-V-Host vorhanden sind
$VMs = Get-VM

# Überprüfe jede VM auf Replikationsstatus
foreach ($vm in $VMs) {
    Check-ReplicationStatus -VMName $vm.Name
}
