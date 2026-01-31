# RustDeskWatcher.ps1
# Watches RustDesk server logs and triggers display_config.bat with args.

$LogDir  = "C:\Windows\ServiceProfiles\LocalService\AppData\Roaming\RustDesk\log\server"
$BaseDir = "C:\Users\mail\Documents\000 Development\Three monitor switch"
$Bat     = Join-Path $BaseDir "display_config.bat"
$HookLog = Join-Path $BaseDir "RustDeskWatcher.log"

# Remove any old subscriptions from previous runs
Unregister-Event -SourceIdentifier "RDRollover" -ErrorAction SilentlyContinue


# Use exact phrases from your log
$ConnectRegex    = 'Connection opened'
$DisconnectRegex = 'Connection closed'

function Log($m) {
    Add-Content -Path $HookLog -Value "$(Get-Date -Format 'yyyy-MM-dd HH:mm:ss.fff') $m"
}

function LatestLog {
    Get-ChildItem -Path $LogDir -Filter "*.log" -File | Sort-Object LastWriteTime -Descending | Select-Object -First 1
}

function Run-Bat([string]$arg) {
    $cmd = "`"$Bat`" $arg"
    Log "RUN: $cmd"
    Start-Process -FilePath "cmd.exe" -ArgumentList "/c $cmd" -WindowStyle Hidden
}

Log "=== RustDeskWatcher starting ==="
$log = (LatestLog).FullName
Log "Watching: $log"

# Handle log rollover
$fsw = New-Object IO.FileSystemWatcher($LogDir, "*.log")
$fsw.EnableRaisingEvents = $true
Register-ObjectEvent -InputObject $fsw -EventName Created -SourceIdentifier "RDRollover" -Action {
    try {
        $script:log = (LatestLog).FullName
        Add-Content -Path $using:HookLog -Value "$(Get-Date -Format 'yyyy-MM-dd HH:mm:ss.fff') Rollover -> $script:log"
    } catch {
        Add-Content -Path $using:HookLog -Value "$(Get-Date -Format 'yyyy-MM-dd HH:mm:ss.fff') Rollover error: $($_.Exception.Message)"
    }
} | Out-Null

# Tail the log
Get-Content -Path $log -Tail 0 -Wait | ForEach-Object {
    $line = $_
    if ($line -match $ConnectRegex) {
        Run-Bat "config2"   # RustDesk entry
    }
    elseif ($line -match $DisconnectRegex) {
        Run-Bat "config1"   # RustDesk closing
    }
}
