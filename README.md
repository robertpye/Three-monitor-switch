# Windows Multi-Monitor Configuration + RustDesk Auto-Switch

This repo provides:

- `display_config.bat` — Predefined monitor layouts using NirSoft [MultiMonitorTool](https://www.nirsoft.net/utils/multi_monitor_tool.html).
- `RustDeskWatcher.ps1` — A PowerShell script that tails RustDesk **server logs** and triggers monitor configs automatically:
  - On **RustDesk connect** → `display_config.bat config2`
  - On **RustDesk disconnect** → `display_config.bat config1`
- `RustDeskWatcherTask.xml` — Importable Scheduled Task that runs the watcher at boot.

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
└── RustDeskWatcher.log (created at runtime)

sql
Copy
Edit

RustDesk logs are watched at:
C:\Windows\ServiceProfiles\LocalService\AppData\Roaming\RustDesk\log\server

yaml
Copy
Edit

---

## 🔧 Configurations

`display_config.bat` defines 4 options:

1. **config1** — All monitors (restores baseline)
2. **config2** — Only Monitor 3 at 1680×1050
3. **config3** — Monitor 1 + 3 only
4. **config4** — Only Monitor 3 at 1920×1080

Run directly:
```bat
display_config.bat config1
display_config.bat config2
Run without args for an interactive menu.

🛠 Deploy RustDesk Auto-Switch
1. Place files
Copy display_config.bat, MultiMonitorTool.exe, RustDeskWatcher.ps1, and RustDeskWatcherTask.xml into:

cpp
Copy
Edit
C:\Users\mail\Documents\000 Development\Three monitor switch
2. Import the task
Open an Admin shell:

cmd
Copy
Edit
schtasks /Create /TN "RustDeskWatcher" /XML "C:\Users\mail\Documents\000 Development\Three monitor switch\RustDeskWatcherTask.xml" /F
Start it immediately (no reboot):

cmd
Copy
Edit
schtasks /Run /TN "RustDeskWatcher"
3. Test
Connect via RustDesk → layout switches to config2.

Disconnect → layout reverts to config1.

Logs are written to:

bash
Copy
Edit
RustDeskWatcher.log
🔍 Detection Markers
Watcher looks for these lines in RustDesk logs:

Connect: Connection opened

Disconnect: Connection closed

If your RustDesk version uses different wording, update $ConnectRegex / $DisconnectRegex in RustDeskWatcher.ps1.

🛠 Troubleshooting
If you see SUBSCRIBER_EXISTS, the script was already running — use Task Scheduler instead of running it twice manually.

Ensure MultiMonitorTool.exe is present in the same folder.

To adjust monitor IDs, run:

c
Copy
Edit
MultiMonitorTool.exe /stext monitors.txt
📜 License
MIT License

🙏 Credits
Batch + watcher integration: Rob

Multi-monitor control: NirSoft MultiMonitorTool

yaml
Copy
Edit

As Admin is Powershell

PS C:\Users\mail\Documents\000 Development\Three monitor switch> schtasks /Create /TN "RustDeskWatcher" /XML "C:\Users\mail\Documents\000 Development\Three monitor switch\RustDeskWatcherTask.xml" /F
>>
SUCCESS: The scheduled task "RustDeskWatcher" has successfully been created.
PS C:\Users\mail\Documents\000 Development\Three monitor switch>