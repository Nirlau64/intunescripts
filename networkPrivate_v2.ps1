# Intune Deployment Script - Netzwerkprofil auf Privat setzen wenn 802.1X authentifiziert
# Logging für Intune
$logFile = "$env:ProgramData\Microsoft\IntuneManagementExtension\Logs\NetworkPrivate.log"
Start-Transcript -Path $logFile -Force

Write-Output "Erstelle Scheduled Task für Netzwerkprofil-Verwaltung..."

# Das eigentliche Worker-Script
$workerScript = @'
# Worker Script - läuft alle 5 Minuten
$logFile = "C:\ProgramData\Scripts\SetNetworkPrivate.log"
$logDir = "C:\ProgramData\Scripts"

if (-not (Test-Path $logDir)) {
    New-Item -ItemType Directory -Path $logDir -Force | Out-Null
}

Start-Transcript -Path $logFile -Append -Force

Write-Output "`n=== $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss') ==="

# Prüfe 802.1X auf allen LAN-Interfaces
$lan = netsh lan show interfaces 2>&1
$authenticatedInterface = $null

# Finde das Interface mit aktiver 802.1X-Authentifizierung
$lan -split "`n" | ForEach-Object {
    if ($_ -match "^(\S+)\s+" -and $_ -match "(Authentifizierung erfolgreich|Authentication.*:\s*Authenticated)") {
        $authenticatedInterface = $matches[1]
        Write-Output "Interface mit 802.1X Authentifizierung gefunden: $authenticatedInterface"
    }
}

if ($authenticatedInterface) {
    Write-Output "Nutze Adapter-Name als Identifikator: $authenticatedInterface"
    
    # Finde das Profil für diesen Adapter in der Registry
    $regPath = "HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\NetworkList\Profiles"
    $profiles = Get-ChildItem -Path $regPath -ErrorAction SilentlyContinue
    $changedCount = 0
    
    foreach ($profile in $profiles) {
        $category = (Get-ItemProperty -Path $profile.PSPath -Name "Category" -ErrorAction SilentlyContinue).Category
        $profileName = (Get-ItemProperty -Path $profile.PSPath -Name "ProfileName" -ErrorAction SilentlyContinue).ProfileName
        $description = (Get-ItemProperty -Path $profile.PSPath -Name "Description" -ErrorAction SilentlyContinue).Description
        
        # Prüfe, ob dieses Profil dem authentifizierten Adapter entspricht
        if (($profileName -eq $authenticatedInterface -or $description -match $authenticatedInterface) -and $category -eq 0) {
            Write-Output "Setze '$profileName' (802.1X-Adapter: $authenticatedInterface) auf Privat"
            Set-ItemProperty -Path $profile.PSPath -Name "Category" -Value 1 -ErrorAction SilentlyContinue
            Set-ItemProperty -Path $profile.PSPath -Name "CategoryType" -Value 0 -ErrorAction SilentlyContinue
            $changedCount++
        }
    }
    
    Write-Output "Geänderte Profile: $changedCount"
} else {
    Write-Output "Keine 802.1X Authentifizierung aktiv"
}

Stop-Transcript
exit 0
'@

# Speichere Worker-Script
$scriptPath = "$env:ProgramData\Scripts\SetNetworkPrivate.ps1"
$scriptDir = Split-Path -Parent $scriptPath

if (-not (Test-Path $scriptDir)) {
    New-Item -ItemType Directory -Path $scriptDir -Force | Out-Null
}

Set-Content -Path $scriptPath -Value $workerScript -Force

# Erstelle Scheduled Task
$taskName = "SetNetworkProfilePrivate"
$taskPath = "\Custom\"

# Erstelle Task-Ordner falls nicht vorhanden
try {
    $scheduleService = New-Object -ComObject Schedule.Service
    $scheduleService.Connect()
    $rootFolder = $scheduleService.GetFolder("\")
    try {
        $rootFolder.GetFolder("Custom") | Out-Null
        Write-Output "Task-Ordner 'Custom' existiert bereits"
    } catch {
        $rootFolder.CreateFolder("Custom") | Out-Null
        Write-Output "Task-Ordner 'Custom' erstellt"
    }
} catch {
    Write-Output "Warnung: Konnte Task-Ordner nicht erstellen: $_"
    # Fallback auf Root
    $taskPath = "\"
}

$existingTask = Get-ScheduledTask -TaskName $taskName -TaskPath $taskPath -ErrorAction SilentlyContinue
if ($existingTask) {
    Unregister-ScheduledTask -TaskName $taskName -TaskPath $taskPath -Confirm:$false
    Write-Output "Bestehender Task entfernt"
}

$trigger = New-ScheduledTaskTrigger -AtLogOn
$trigger.Repetition = (New-ScheduledTaskTrigger -Once -At (Get-Date) -RepetitionInterval (New-TimeSpan -Minutes 5)).Repetition

$action = New-ScheduledTaskAction -Execute "powershell.exe" -Argument "-ExecutionPolicy Bypass -NoProfile -WindowStyle Hidden -File `"$scriptPath`""
$principal = New-ScheduledTaskPrincipal -UserId "NT AUTHORITY\SYSTEM" -LogonType ServiceAccount -RunLevel Highest
$settings = New-ScheduledTaskSettingsSet -AllowStartIfOnBatteries -DontStopIfGoingOnBatteries -StartWhenAvailable

Register-ScheduledTask -TaskName $taskName -TaskPath $taskPath -Trigger $trigger -Action $action -Principal $principal -Settings $settings -ErrorAction Stop

Write-Output "Task '$taskName' erfolgreich erstellt in: $taskPath"
Write-Output "Script: $scriptPath"

Stop-Transcript
exit 0
