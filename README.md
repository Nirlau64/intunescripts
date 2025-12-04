# intunescripts

A collection of **PowerShell scripts** designed for the deployment and configuration of Windows settings via **Microsoft Intune** (or other RMM/MDM solutions).

-----

## Table of Contents

  * [`disable_fast_startup.ps1`]
  * [`firewallsettingsRDP.ps1`]
  * [`networkPrivate_v2.ps1`]
  * [General Notes]

-----

## Script Overview and Details

### `disable_fast_startup.ps1` (Disable Fast Startup)

| Category | Detail |
| :--- | :--- |
| **Purpose** | Disables the **"Fast Startup"** feature in Windows. This is often necessary to avoid issues with dual-boot systems or specific system maintenance tasks. |
| **Function** | The script sets the Registry value `HiberbootEnabled` to `0` (DWORD) under the path `HKLM:\SYSTEM\CurrentControlSet\Control\Session Manager\Power`. |
| **Source** | [disable\_fast\_startup.ps1](https://github.com/Nirlau64/intunescripts/blob/main/disable_fast_startup.ps1) |

-----

### `firewallsettingsRDP.ps1` (RDP Firewall Rules)

| Category | Detail |
| :--- | :--- |
| **Purpose** | Enables the required Windows Defender Firewall rules for **Remote Desktop (RDP)**, restricted to the **Private** network profile. |
| **Function** | The script attempts to enable RDP rules first via their internal names (e.g., `RemoteDesktop-In-TCP-WS`). A fallback uses **Regex patterns** for display names (German and English) for language independence. All enabled rules are explicitly restricted to the **Private** profile. |
| **Source** | [firewallsettingsRDP.ps1](https://github.com/Nirlau64/intunescripts/blob/main/firewallsettingsRDP.ps1) |

-----

### `networkPrivate_v2.ps1` (Network Profile to Private with 802.1X)

| Category | Detail |
| :--- | :--- |
| **Purpose** | Ensures the network profile is set to **Private** when a successful **802.1X authentication** is detected, which is common in corporate environments. |
| **Function** | The Intune script creates a **Scheduled Task** (`SetNetworkProfilePrivate`) that runs every 5 minutes as the **SYSTEM** account. The worker script checks for active 802.1X authentication using `netsh lan show interfaces`. It then identifies the authenticated adapter and sets the corresponding network profile's **Category** from `0` (Public) to `1` (Private) in the Registry if the profile's `ProfileName` or `Description` matches the authenticated adapter's name. |
| **Source** | [networkPrivate\_v2.ps1](https://github.com/Nirlau64/intunescripts/blob/main/networkPrivate_v2.ps1) |

-----

## General Notes

All scripts are designed to run in the **System Context** via the **Intune Management Extension**. They use standardized logging paths and exit codes (`0` for success, `1` for failure) for proper reporting within Intune.
