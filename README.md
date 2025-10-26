# NetworkBasedShut

A small PowerShell utility that monitors network adapter transfer activity and initiates a system shutdown when traffic remains below a configurable threshold for a configurable grace period.

This repository contains `NetworkBasedShut2.ps1`, a script that presents a simple GUI for selecting a network adapter and a "grace seconds" value. It checks transfer rates once per second and, if the measured rate remains below the configured threshold for the entire grace period, it triggers a shutdown (with a 60 second delay before the actual shutdown).

Important: this script will shut down the machine. Test it in a safe environment (VM) before using on production machines.

---

## Features

- GUI to select network adapter and set grace seconds
- Uses Get-NetAdapter and Get-NetAdapterStatistics to read sent/received bytes
- Monitors bytes per second (KB/s)
- Triggers shutdown.exe when low traffic persists for the configured period
- Simple and lightweight — single PowerShell script

---

## Prerequisites

- Windows 8 / Windows Server 2012 or later (Get-NetAdapter / Get-NetAdapterStatistics are provided by the NetAdapter module in modern Windows releases). PowerShell 5.x or later recommended.
- Run PowerShell as Administrator to allow calling shutdown.exe and reading adapter statistics reliably.
- Execution policy that allows running local scripts (for example):
  - Set-ExecutionPolicy RemoteSigned -Scope CurrentUser -Force
- Warning: The script calls shutdown.exe. Use with caution.

---

## Files

- NetworkBasedShut2.ps1 — main script (GUI + monitoring + shutdown trigger)

---

## Quick start

1. Download or clone the repository.
2. Open an elevated PowerShell prompt (Run as Administrator).
3. From the directory containing `NetworkBasedShut2.ps1`, run:
   powershell -ExecutionPolicy Bypass -File .\NetworkBasedShut2.ps1
4. In the GUI:
   - Select the network adapter you want to monitor.
   - Set "Grace seconds before shutdown" (how many seconds of consecutive low traffic will trigger shutdown).
   - Click "OK".
5. The script will begin monitoring. When the transfer rate measured in KB/s falls below the internal threshold for the entire grace period, the script will launch:
   shutdown.exe /s /t 60
   (i.e., system shutdown after a 60 second countdown).

---

## Configuration and tuning

- Threshold: The script uses a default threshold of 50 KB/s:
  $thresholdKBps = 50
  Lower the value to make the script less sensitive to small activity; raise it to require more traffic before being considered "active".
- Grace period: The GUI field (default 60) sets how many consecutive seconds the measured transfer rate must remain below $thresholdKBps before triggering a shutdown.
- Final shutdown delay: The script calls `shutdown.exe /s /t 60` — the `60` is the delay in seconds before the actual shutdown. Edit this value if you want a longer or shorter warning period.
- Polling interval: The script sleeps for 1 second between checks (Start-Sleep -Seconds 1). Changing this value affects responsiveness and granularity.

Example changes (inside the script):
- Change threshold to 10 KB/s:
  $thresholdKBps = 10
- Change shutdown countdown to 120 seconds:
  Start-Process "shutdown.exe" -ArgumentList "/s /t 120"

If you'd rather pass CLI parameters instead of using the GUI, consider adding a param() block at the top of the script (pull requests welcome).

---

## Safety & testing

- Test in a virtual machine before running on your main workstation or server.
- Be sure no important unsaved work or scheduled jobs will be interrupted.
- The script does not try to gracefully cancel or postpone shutdown for OS-level tasks — it simply launches the shutdown command.

---

## Troubleshooting

- "No adapter selected. Exiting." — You closed the GUI without selecting an adapter. Re-run the script and choose an adapter.
- "Adapter 'X' not found or inaccessible." — Either the adapter name became invalid, or your PowerShell session lacks necessary privileges or module support. Ensure you have the NetAdapter module and run as Administrator.
- Get-NetAdapter/Get-NetAdapterStatistics not found — your Windows version might lack the NetAdapter cmdlets. Ensure you're on Windows 8 / Server 2012 or later, or have the appropriate RSAT/management modules installed.
- Script does not shut down — Check that Start-Process "shutdown.exe" is allowed and that your account can trigger shutdowns. You can test shutdown separately by running `shutdown.exe /s /t 30` in an elevated prompt.

---

## Suggested improvements

- Add command-line parameters to allow non-interactive use (adapter name, threshold, grace, shutdown delay).
- Add logging to file to record why/when shutdowns were triggered.
- Add an option to exclude specific processes or to detect user activity (mouse/keyboard) before shutdown.
- Add a service/daemon mode that runs in the background without GUI.

---


## Contact / Issues

Open an issue on the repository: https://github.com/dnullptr/NetworkBasedShut/issues

---
