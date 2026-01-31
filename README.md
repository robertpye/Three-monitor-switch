# Windows Multi-Monitor Configuration

This repo provides solutions for managing multi-monitor configurations and VM auto-suspend.

## 📂 Project Structure

```
Three monitor switch/
├── monitor_switcher/
│   ├── DisplaySwitcher.bat                    # Main monitor switching script
│   ├── DisableDisplayFusionConfirmPrompt.reg  # Disable confirmation dialog
│   ├── EnableDisplayFusionConfirmPrompt.reg   # Re-enable confirmation dialog
│   ├── DisplaySwitcher.log                    # Runtime log
│   └── requirements/                          # Spec documentation
│       ├── requirements.md                    # Requirements document
│       ├── design.md                          # Design document
│       └── tasks.md                           # Implementation tasks
├── rust_desk/
│   ├── RustDeskWatcher.ps1                    # RustDesk auto-switch monitor watcher
│   ├── RustDeskWatcherTask.xml                # Scheduled task definition
│   ├── Install-RustDeskWatcher.ps1            # Install/uninstall script
│   ├── Test-RustDeskWatcher.ps1               # Verification tests
│   ├── RustDeskWatcher.log                    # Runtime log
│   └── RustDeskWatcher.state                  # State persistence file
├── suspend_vms/
│   └── suspend_vms.bat                        # VM auto-suspend script
└── README.md
```

---

## DisplaySwitcher (DisplayFusion)

**`monitor_switcher/DisplaySwitcher.bat`** — A robust batch script for switching monitor configurations using DisplayFusion.

### Features
- Reliable first-attempt configuration switching
- Verbose logging with timestamps
- Automatic monitor state detection
- Support for 3-monitor setup (Left portrait, Center primary, Right landscape)

### Usage

```bat
DisplaySwitcher triple      # Enable all three monitors
DisplaySwitcher single      # Center monitor only
DisplaySwitcher dual        # Center + right monitors
DisplaySwitcher vertical    # Center + left monitors
DisplaySwitcher rustdesk    # RustDesk remote access config
DisplaySwitcher -v triple   # Verbose mode
DisplaySwitcher --help      # Show help
```

### Installation

Add `monitor_switcher` folder to your PATH for easy access:
```powershell
[Environment]::SetEnvironmentVariable("PATH", $env:PATH + ";C:\Users\mail\Documents\000 Development\Three monitor switch\monitor_switcher", "User")
```
Restart your terminal after adding to PATH.

### Prerequisites

1. **DisplayFusion Pro** installed (https://www.displayfusion.com/)

2. **Create Monitor Profiles** in DisplayFusion with these exact names:
   - `TripleMonitor` - All 3 monitors enabled
   - `SingleCenter` - Only center monitor
   - `DualWork` - Center + right monitors
   - `DualVertical` - Center + left monitors
   - `RustDesk` - Remote access configuration

3. **Disable confirmation dialog** - Run the registry file to prevent the "Keep changes?" popup:
   ```bat
   regedit /s monitor_switcher\DisableDisplayFusionConfirmPrompt.reg
   ```
   Then restart DisplayFusion.

### Registry Setting

The confirmation dialog is disabled via this registry key:
```
HKEY_CURRENT_USER\Software\Binary Fortress Software\DisplayFusion
Value: MonitorConfigDontShowConfirmPrompt (DWORD) = 1
```

To re-enable the confirmation dialog:
```bat
regedit /s monitor_switcher\EnableDisplayFusionConfirmPrompt.reg
```

---

## RustDesk Auto-Switch

**`rust_desk/RustDeskWatcher.ps1`** — Monitors RustDesk server logs and automatically switches monitor profiles when remote sessions connect/disconnect.

### How it works

1. Watches RustDesk server logs for "Connection opened" / "Connection closed" events
2. On connect: Saves current profile, switches to `RustDesk` profile (single monitor, low res)
3. On disconnect: Restores the previous profile automatically
4. Includes 5-second debounce to prevent rapid switching from connection flapping

### Installation

Run PowerShell as Administrator:
```powershell
cd "C:\Users\mail\Documents\000 Development\Three monitor switch\rust_desk"

# Run tests first
.\Test-RustDeskWatcher.ps1

# Install as scheduled task (runs at user logon)
.\Install-RustDeskWatcher.ps1
```

### Manual Testing

```powershell
# Run interactively with verbose output (Ctrl+C to stop)
.\RustDeskWatcher.ps1 -Verbose

# Adjust debounce interval (default 5 seconds)
.\RustDeskWatcher.ps1 -DebounceSeconds 3
```

### Uninstall

```powershell
.\Install-RustDeskWatcher.ps1 -Uninstall
```

### Files

| File | Purpose |
|------|---------|
| `RustDeskWatcher.ps1` | Main watcher script |
| `RustDeskWatcherTask.xml` | Task Scheduler definition |
| `Install-RustDeskWatcher.ps1` | Install/uninstall helper |
| `Test-RustDeskWatcher.ps1` | Pre-flight verification |
| `RustDeskWatcher.log` | Runtime log |
| `RustDeskWatcher.state` | Persists previous profile for restore |

### Prerequisites

- RustDesk installed as a Windows service (logs to `C:\Windows\ServiceProfiles\LocalService\...`)
- DisplayFusion with `RustDesk` profile configured
- DisplaySwitcher.bat in `monitor_switcher/` folder

---

## suspend_vms — VMware VM Auto-Suspend

**`suspend_vms/suspend_vms.bat`** — Suspends all running VMware Workstation/Player VMs using `vmrun`. Intended for APC PowerChute Serial Shutdown during power events.

### How it works
1. Locates `vmrun.exe` (checks PATH, then common install directories)
2. Runs `vmrun list` to enumerate running VMs
3. Suspends each VM (tries soft suspend first, falls back to hard suspend)
4. Logs all activity to `C:\ProgramData\APC\PowerChute\Logs\VMWare2.log`

### Usage

```bat
suspend_vms\suspend_vms.bat
```

---

## 📜 License
MIT License
