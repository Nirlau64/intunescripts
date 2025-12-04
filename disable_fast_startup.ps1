# Logging für Intune
$logDir = "$env:ProgramData\Microsoft\IntuneManagementExtension\Logs"
$logFile = "$logDir\DisableFastStartup.log"

# Stelle sicher, dass das Log-Verzeichnis existiert
if (-not (Test-Path $logDir)) {
    New-Item -Path $logDir -ItemType Directory -Force | Out-Null
}



$RegistryPath = "HKLM:\SYSTEM\CurrentControlSet\Control\Session Manager\Power"
$PropertyName = "HiberbootEnabled"
$PropertyValue = 0

Write-Output "Script gestartet am: $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')"
Write-Output "Deaktiviere Fast Startup..."
Write-Output "Registry-Pfad: $RegistryPath"

try {
    # Prüfe ob der Registry-Pfad existiert
    if (-not (Test-Path $RegistryPath)) {
        Write-Output "FEHLER: Registry-Pfad existiert nicht: $RegistryPath"
        Add-Content -Path $logFile -Value "FEHLER: Registry-Pfad existiert nicht: $RegistryPath"
        $host.SetShouldExit(1)
        return
    }
    # Prüfe aktuellen Wert
    $currentValue = Get-ItemProperty -Path $RegistryPath -Name $PropertyName -ErrorAction SilentlyContinue
    Write-Output "Aktueller Wert vor Änderung: $($currentValue.HiberbootEnabled)"
    Add-Content -Path $logFile -Value "Aktueller Wert vor Änderung: $($currentValue.HiberbootEnabled)"
    
    # Setze neuen Wert
    try {
        Set-ItemProperty -Path $RegistryPath -Name $PropertyName -Value $PropertyValue -Type DWORD -Force -ErrorAction Stop
    } catch {
        Write-Output "FEHLER: Set-ItemProperty fehlgeschlagen: $_"
        Add-Content -Path $logFile -Value "FEHLER: Set-ItemProperty fehlgeschlagen: $_"
        $host.SetShouldExit(1)
        return
    }
    
    # Verifiziere die Änderung
    $newValue = Get-ItemProperty -Path $RegistryPath -Name $PropertyName -ErrorAction Stop
    Write-Output "Neuer Wert nach Änderung: $($newValue.HiberbootEnabled)"
    Add-Content -Path $logFile -Value "Neuer Wert nach Änderung: $($newValue.HiberbootEnabled)"
    
    if ($newValue.HiberbootEnabled -eq 0) {
        Write-Output "Fast Startup erfolgreich deaktiviert (HiberbootEnabled = 0)"
        Add-Content -Path $logFile -Value "Fast Startup erfolgreich deaktiviert (HiberbootEnabled = 0)"
        $host.SetShouldExit(0)
        return
    } else {
        Write-Output "FEHLER: Registry-Wert wurde nicht korrekt gesetzt!"
        Add-Content -Path $logFile -Value "FEHLER: Registry-Wert wurde nicht korrekt gesetzt!"
        $host.SetShouldExit(1)
        return
    }
    
} catch {
    Write-Output "Fehler beim Deaktivieren von Fast Startup: $_"
    Write-Output "Fehlerdetails: $($_.Exception.Message)"
    Add-Content -Path $logFile -Value "Fehler beim Deaktivieren von Fast Startup: $_"
    Add-Content -Path $logFile -Value "Fehlerdetails: $($_.Exception.Message)"
    $host.SetShouldExit(1)
    return
}