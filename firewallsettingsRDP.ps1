
# Logging für Intune
$logFile = "$env:ProgramData\Microsoft\IntuneManagementExtension\Logs\FirewallRDP.log"

# Stelle sicher, dass das Log-Verzeichnis existiert
$logDir = Split-Path -Path $logFile -Parent
if (-not (Test-Path -Path $logDir)) {
    try {
        New-Item -Path $logDir -ItemType Directory -Force -ErrorAction Stop | Out-Null
    }
    catch {
        # Fallback auf TEMP wenn Intune-Verzeichnis nicht verfügbar
        $logFile = "$env:TEMP\FirewallRDP.log"
    }
}

try {
    Start-Transcript -Path $logFile -Force -ErrorAction Stop
}
catch {
    # Fallback auf TEMP wenn primäres Log fehlschlägt
    $logFile = "$env:TEMP\FirewallRDP.log"
    Start-Transcript -Path $logFile -Force
}

Write-Output "Aktiviere Remote Desktop Firewallregeln..."
Write-Output "Log-Datei: $logFile"

# Bevorzugt: Aktivierung über die stabile Regel-ID (Name), unabhängig von Sprache/Unicode
$firewallRuleNames = @(
    'RemoteDesktop-In-TCP-WS',
    'RemoteDesktop-In-TCP-WSS',
    'RemoteDesktop-UserMode-In-TCP',
    'RemoteDesktop-UserMode-In-UDP',
    'RemoteDesktop-Shadow-In-TCP'
)

# Fallback: Aktivierung über Anzeigenamen per Regex (tolerant gegenüber Unicode-Bindestrichen und variabler Leerzeichen)
$firewallDisplayNamePatterns = @(
    # Deutsch
    '^Remotedesktop\s*[-–—]\s*\(TCP-WS eingehend\)$',
    '^Remotedesktop\s*[-–—]\s*\(TCP-WSS-in\)$',
    '^Remotedesktop\s*[-–—]\s*Benutzermodus\s*\(TCP eingehend\)$',
    '^Remotedesktop\s*[-–—]\s*Benutzermodus\s*\(UDP eingehend\)$',
    '^Remotedesktop\s*[-–—]\s*Schatten\s*\(TCP eingehend\)$',
    # Englisch
    '^Remote Desktop\s*[-–—]\s*\(TCP-WS-In\)$',
    '^Remote Desktop\s*[-–—]\s*\(TCP-WSS-in\)$',
    '^Remote Desktop\s*[-–—]\s*User Mode\s*\(TCP-In\)$',
    '^Remote Desktop\s*[-–—]\s*User Mode\s*\(UDP-In\)$',
    '^Remote Desktop\s*[-–—]\s*Shadow\s*\(TCP-In\)$'
)

# Zähler für Reporting
$alreadyEnabled = 0
$successfullyEnabled = 0
$failed = 0

# Zuerst versuchen wir über die internen Regelnamen
foreach ($ruleName in $firewallRuleNames) {
    try {
        $rule = Get-NetFirewallRule -Name $ruleName -ErrorAction Stop
        if ($rule.Enabled -eq $true) {
            Write-Output "[INFO] Regel (Name) bereits aktiviert: $ruleName"
            $alreadyEnabled++
        } else {
            Set-NetFirewallRule -Name $ruleName -Enabled True -Profile Private -ErrorAction Stop
            Write-Output "[OK] Regel (Name) aktiviert: $ruleName (nur Private Netzwerke)"
            $successfullyEnabled++
        }
    } catch {
        Write-Output "[HINWEIS] Regel (Name) nicht gefunden: $ruleName"
    }
}

# Fallback: über Anzeigenamen aktivieren, falls nichts aktiviert wurde
if ($successfullyEnabled -eq 0 -and $alreadyEnabled -eq 0) {
    $allRules = Get-NetFirewallRule -ErrorAction SilentlyContinue
    foreach ($pattern in $firewallDisplayNamePatterns) {
        try {
            $matched = $allRules | Where-Object { $_.DisplayName -match $pattern }
            if ($matched) {
                foreach ($rule in $matched) {
                    if ($rule.Enabled -eq $true) {
                        Write-Output "[INFO] Regel (Regex) bereits aktiviert: $($rule.DisplayName)"
                        $alreadyEnabled++
                    } else {
                        Set-NetFirewallRule -Name $rule.Name -Enabled True -Profile Private -ErrorAction Stop | Out-Null
                        Write-Output "[OK] Regel (Regex) aktiviert: $($rule.DisplayName) (nur Private Netzwerke)"
                        $successfullyEnabled++
                    }
                }
            } else {
                Write-Output "[HINWEIS] Keine Übereinstimmung (Regex) für: $pattern"
            }
        } catch {
            Write-Output "[FEHLER] Regex-Aktivierung fehlgeschlagen für Muster: $pattern"
            Write-Output "        Fehlerdetails: $($_.Exception.Message)"
            $failed++
        }
    }
}

Write-Output ""
Write-Output "=== Zusammenfassung ==="
Write-Output "Bereits aktiviert: $alreadyEnabled"
Write-Output "Neu aktiviert: $successfullyEnabled"
Write-Output "Fehlgeschlagen: $failed"

# Exit Code für Intune: Fehler wenn keine Regel aktiviert wurde und auch keine schon aktiv war
if ($successfullyEnabled -eq 0 -and $alreadyEnabled -eq 0) {
    Write-Output ""
    Write-Output "[FEHLER] Keine einzige Firewallregel konnte aktiviert werden!"
    Write-Output "Das kann folgende Ursachen haben:"
    Write-Output "  - Remote Desktop ist nicht installiert oder aktiviert"
    Write-Output "  - Die Firewallregeln haben andere Namen (z.B. andere Sprachversion)"
    Write-Output "  - Fehlende Berechtigungen"
    Stop-Transcript
    exit 1
}

Write-Output ""
Write-Output "Fertig! Skript erfolgreich ausgeführt."
Stop-Transcript
exit 0
