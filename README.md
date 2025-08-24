# Windows Multi-Monitor Configuration + RustDesk Auto-Switch

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



Three monitor switch/
├── display_config.bat
├── MultiMonitorTool.exe
├── RustDeskWatcher.ps1
├── RustDeskWatcherTask.xml
└── RustDeskWatcher.log # created at runtime


RustDesk server logs are tailed from:



C:\Windows\ServiceProfiles\LocalService\AppData\Roaming\RustDesk\log\server


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


Run with no arguments to get an interactive menu.

🛠 Deploy RustDesk Auto-Switch
1. Place files

Copy these into:

C:\Users\mail\Documents\000 Development\Three monitor switch


display_config.bat

MultiMonitorTool.exe

RustDeskWatcher.ps1

RustDeskWatcherTask.xml

2. Import the task

Open an Admin PowerShell or CMD:

schtasks /Create /TN "RustDeskWatcher" /XML "C:\Users\mail\Documents\000 Development\Three monitor switch\RustDeskWatcherTask.xml" /F


Start it immediately (without reboot):

schtasks /Run /TN "RustDeskWatcher"

3. Test

Connect via RustDesk → layout switches to config2.

Disconnect → layout reverts to config1.

Logs are written to:

RustDeskWatcher.log

🔍 Detection Markers

The watcher looks for these strings in RustDesk logs:

Connect: Connection opened

Disconnect: Connection closed

If your RustDesk version uses different wording, update $ConnectRegex / $DisconnectRegex in RustDeskWatcher.ps1.

🛠 Troubleshooting

Error SUBSCRIBER_EXISTS → The script is already running. Use Task Scheduler instead of starting it twice manually.

MultiMonitorTool.exe not found → Place it in the same folder as display_config.bat.

Different monitor IDs → Dump your mapping:

MultiMonitorTool.exe /stext monitors.txt


Update \\.\DISPLAYx in the batch file accordingly.

📜 License

MIT License

🙏 Credits

Batch + watcher integration: Rob

Multi-monitor control: NirSoft MultiMonitorTool


---

This version removes all the spurious `sql`, `yaml`, etc. code fences and organizes things in a clean developer-friendly format.  

Would you like me to also add a **screenshot/example log snippet** to the README so users can see what the “Connection opened/closed” lines look like in practice?


ChatGP