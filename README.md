# Windows Multi-Monitor Configuration Script

A simple batch script wrapper around [MultiMonitorTool](https://www.nirsoft.net/utils/multi_monitor_tool.html)  
to quickly switch between predefined monitor layouts on **Windows 11**.

---

## 🚀 Features
- Toggle between multiple monitor configurations with a menu or command-line argument.
- Automatically enable/disable monitors as needed.
- Set resolution, refresh rate, orientation, and primary display.
- Fully offline, lightweight (uses NirSoft's `MultiMonitorTool.exe`).

---

## 📂 Project Structure


├── display_config.bat # Main batch script
├── display_config.bak # Backup of last batch edit
├── MultiMonitorTool.exe # NirSoft utility (required)
├── MultiMonitorTool.cfg # Tool configuration
├── MultiMonitorTool.chm # Help file from NirSoft
├── readme-multimonitor.txt # Original NirSoft readme
└── monitors.txt # Sample monitor dump


---

## ⚙️ Configurations

The batch script provides **4 predefined options**:

1. **All monitors enabled**  
   - Monitor 3 (`\\.\DISPLAY1`) → Primary, 1920×1080 (landscape)  
   - Monitor 1 (`\\.\DISPLAY2`) → Secondary, 1920×1080 (landscape)  
   - Monitor 2 (`\\.\DISPLAY3`) → Portrait, 1200×1920  

2. **Only Monitor 3 at 1680×1050**

3. **Monitor 1 + 3 only**  
   - Monitor 3 (`\\.\DISPLAY1`) → Primary, 1920×1080  
   - Monitor 1 (`\\.\DISPLAY2`) → Secondary, 1920×1080  

4. **Only Monitor 3 at 1920×1080**

---

## 🔧 Usage

### Interactive Mode
Double-click `display_config.bat` and choose from the menu (1–4).

### Command-Line Mode
Run with argument:
```bat
display_config.bat config1
display_config.bat config2
display_config.bat config3
display_config.bat config4

🖥 Requirements

Windows 10/11

MultiMonitorTool
 (place MultiMonitorTool.exe in the same folder as the script)

📝 Notes

Monitor mappings (\\.\DISPLAYx) may differ by system. Run:

MultiMonitorTool.exe /stext monitors.txt


to identify your setup and adjust the script accordingly.

Orientation changes are handled with MultiMonitorTool.exe /SetOrientation.

Disabling monitors may cause Windows to reshuffle their layout. Config 1 explicitly re-enables all monitors to restore consistency.

🛠 Customization

Edit display_config.bat and adjust Width, Height, PositionX, PositionY, or DisplayOrientation for your monitors.

You can generate your own /SetMonitors commands directly from the MultiMonitorTool GUI:
Edit → Copy /SetMonitors Command.

📜 License

This project is released under the MIT License
.

🙏 Credits

Batch script wrapper: your name here

Multi-monitor control: NirSoft MultiMonitorTool