# Windows Multi-Monitor Configuration + RustDesk Auto-Switch

- **`Win + P = project menu to cycle through display modes!`**



This repo provides:

- **`display_config.bat`** — Predefined monitor layouts using NirSoft [MultiMonitorTool](https://www.nirsoft.net/utils/multi_monitor_tool.html).
- **`RustDeskWatcher.ps1`** — A PowerShell script that tails RustDesk **server logs** and triggers monitor configs automatically:
  - On **RustDesk connect** → `display_config.bat config2`
  - On **RustDesk disconnect** → `display_config.bat config1`
- **`RustDeskWatcherTask.xml`** — Importable Scheduled Task that runs the watcher at boot.

---

## 🚀 Features
- Quickly switch between monitor configs from the menu or command-line.
- Auto-switch layout when RustDesk sessions start/end.
- Lightweight, no external dependencies beyond MultiMonitorTool + PowerShell.

---

## 📂 Project Structure

```
Three monitor switch/
├── display_config.bat
├── MultiMonitorTool.exe
├── RustDeskWatcher.ps1
├── RustDeskWatcherTask.xml
├── RustDeskWatcher.log        # created at runtime
└── suspend_vms/
    └── suspend_vms.bat
```

RustDesk server logs are tailed from:

```
C:\Windows\ServiceProfiles\LocalService\AppData\Roaming\RustDesk\log\server
```

---

## 🔧 Configurations

`display_config.bat` defines 4 monitor layouts:

1. **config1** — All monitors (restores baseline)
2. **config2** — Only Monitor 3 at 1680×1050
3. **config3** — Monitor 1 + 3 only
4. **config4** — Only Monitor 3 at 1920×1080

Run directly from the command line:

```bat
display_config.bat config1
display_config.bat config2
display_config.bat config3
display_config.bat config4
```

Run with **no arguments** to get an interactive menu.

---

## 🛠 Deploy RustDesk Auto-Switch

### 1. Place files
Copy these into:

```
C:\Users\mail\Documents\000 Development\Three monitor switch
```

- `display_config.bat`
- `MultiMonitorTool.exe`
- `RustDeskWatcher.ps1`
- `RustDeskWatcherTask.xml`

### 2. Import the task
Open an **Admin** PowerShell or CMD:

```cmd
schtasks /Create /TN "RustDeskWatcher" /XML "C:\Users\mail\Documents\000 Development\Three monitor switch\RustDeskWatcherTask.xml" /F
```

Start it immediately (without reboot):

```cmd
schtasks /Run /TN "RustDeskWatcher"
```

### 3. Test
- Connect via RustDesk → layout switches to **config2**.
- Disconnect → layout reverts to **config1**.

Logs are written to:

```
RustDeskWatcher.log
```

---

## 🔍 Detection Markers

The watcher looks for these strings in RustDesk logs:

- **Connect:** `Connection opened`
- **Disconnect:** `Connection closed`

If your RustDesk version uses different wording, update `$ConnectRegex` / `$DisconnectRegex` in `RustDeskWatcher.ps1`.

---

## 🛠 Troubleshooting
- **Error `SUBSCRIBER_EXISTS`** → The script is already running. Use Task Scheduler instead of starting it twice manually.
- **MultiMonitorTool.exe not found** → Place it in the same folder as `display_config.bat`.
- **Different monitor IDs** → Dump your mapping:

```cmd
MultiMonitorTool.exe /stext monitors.txt
```

Update `\\.\DISPLAYx` in the batch file accordingly.

## 17/09/2025 A note on the recent changes. Monitor position and orientation

You control that “sticks up a bit” with PositionY on the left screen.
MultiMonitorTool (and Windows) use a virtual desktop where the primary’s top-left = (0,0). X grows to the right, Y grows downward. Negative Y moves a display up.

Given your config1:

Center (primary) = 1920×1080 at (0,0)

Left (portrait) = 1080×1920 at (-1920,0) ← this X is wrong for portrait; should be -1080

Right = 1920×1200 at (1920,0)

Pick the vertical alignment you want for the left monitor

Let Hc=1080 (center height), Hl=1920 (left height), Δ=Hl−Hc=840.

Top aligned: PositionY = 0 (what you have now)

Centered vertically: PositionY = (Hc−Hl)/2 = (1080−1920)/2 = -420

Bottom aligned: PositionY = Hc−Hl = 1080−1920 = -840

From your screenshot, “sticks up a bit” usually means centered. So use PositionY=-420.

Also fix the left X for portrait width: PositionX=-1080 (not -1920).

---

## suspend_vms — VMware VM Auto-Suspend

`suspend_vms/suspend_vms.bat` suspends all running VMware Workstation/Player VMs using `vmrun`. It is intended to be called by **APC PowerChute Serial Shutdown** during a power event, but can also be run manually.

### How it works
1. Locates `vmrun.exe` (checks PATH, then common install directories).
2. Runs `vmrun list` to enumerate running VMs.
3. Suspends each VM (tries soft suspend first, falls back to hard suspend).
4. Logs all activity to `C:\ProgramData\APC\PowerChute\Logs\VMWare2.log`.

### Usage

```bat
suspend_vms\suspend_vms.bat
```

To integrate with PowerChute, configure it as the shutdown command script in the PowerChute Serial Shutdown settings.

---

## 📜 License
MIT License

---

## 🙏 Credits
- Batch + watcher integration: Rob  
- Multi-monitor control: NirSoft MultiMonitorTool
