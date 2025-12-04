# intunescripts

Eine Sammlung von **PowerShell-Skripten** für die Bereitstellung und Konfiguration von Windows-Einstellungen über **Microsoft Intune** (oder andere RMM/MDM-Lösungen).

-----

## Inhaltsverzeichnis

  * [`disable_fast_startup.ps1`](https://www.google.com/search?q=%23disable_fast_startup.ps1)
  * [`firewallsettingsRDP.ps1`](https://www.google.com/search?q=%23firewallsettingsrdp.ps1)
  * [`networkPrivate_v2.ps1`](https://www.google.com/search?q=%23networkprivate_v2.ps1)
  * [Allgemeine Hinweise](https://www.google.com/search?q=%23allgemeine-hinweise)

-----

## Skript-Übersicht

### `disable_fast_startup.ps1`

| Kategorie | Detail |
| :--- | :--- |
| **Zweck** | Deaktiviert die Funktion **"Schnellstart"** (Fast Startup) in Windows. Dies ist oft notwendig, um Probleme mit Dual-Boot-Systemen oder bestimmten Systemwartungsaufgaben zu vermeiden. |
| **Funktion** | Das Skript setzt den Registry-Wert `HiberbootEnabled` auf `0` unter dem Pfad `HKLM:\SYSTEM\CurrentControlSet\Control\Session Manager\Power`. |
| **Logging** | Die Protokollierung erfolgt in `$env:ProgramData\Microsoft\IntuneManagementExtension\Logs\DisableFastStartup.log`. |

-----

### `firewallsettingsRDP.ps1`

| Kategorie | Detail |
| :--- | :--- |
| **Zweck** | Aktiviert die erforderlichen Windows Defender Firewall-Regeln für **Remote Desktop (RDP)**, beschränkt auf das **Private** Netzwerkprofil. |
| **Funktion** | Das Skript versucht, die RDP-Regeln zunächst über ihre internen Namen zu aktivieren (z.B. `RemoteDesktop-In-TCP-WS`, `RemoteDesktop-UserMode-In-TCP`). Als Fallback werden **Regex-Muster** für Anzeigenamen (Deutsch und Englisch) verwendet, um sprachunabhängig zu sein. Alle aktivierten Regeln werden auf das Profil **Private** beschränkt. |
| **Logging** | Die Protokollierung erfolgt in `$env:ProgramData\Microsoft\IntuneManagementExtension\Logs\FirewallRDP.log` (mit Fallback auf `%TEMP%`). |

-----

### `networkPrivate_v2.ps1`

| Kategorie | Detail |
| :--- | :--- |
| **Zweck** | Stellt sicher, dass das Netzwerkprofil auf **Privat** gesetzt wird, wenn eine **802.1X Authentifizierung** erfolgreich war, um eine korrekte Firewall-Einstellung in Unternehmensumgebungen zu gewährleisten. |
| **Funktion** | Das Intune-Skript erstellt einen **Geplanten Task** (`SetNetworkProfilePrivate`), der alle 5 Minuten als **SYSTEM**-Konto ausgeführt wird. Der Worker-Skript prüft, ob eine 802.1X Authentifizierung aktiv ist und setzt anschließend alle Netzwerkprofile mit der **Category 0 (Öffentlich)** in der Registry (`HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\NetworkList\Profiles`) auf **Category 1 (Privat)**. |
| **Logging** | **Intune Deployment Log:** `$env:ProgramData\Microsoft\IntuneManagementExtension\Logs\NetworkPrivate.log`.<br>**Task Worker Log:** `C:\ProgramData\Scripts\SetNetworkPrivate.log`. |

-----

## Allgemeine Hinweise

Alle Skripte sind für die Ausführung im **System-Kontext** über das **Intune Management Extension** konzipiert und nutzen standardisierte Logging-Pfade und Exit-Codes für das Reporting in Intune.
