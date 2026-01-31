# RustDeskWatcher.ps1
# Watches RustDesk server logs and triggers DisplaySwitcher with profile names.
# Tracks previous profile state to restore on disconnect.

param(
    [switch]$Verbose,
    [int]$DebounceSeconds = 5
)

# ============================================================================
# CONFIGURATION
# ============================================================================

$ScriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$WorkspaceRoot = Split-Path -Parent $ScriptDir

# Paths
$LogDir = "C:\Windows\ServiceProfiles\LocalService\AppData\Roaming\RustDesk\log\server"
$DisplaySwitcher = Join-Path $WorkspaceRoot "monitor_switcher\DisplaySwitcher.bat"
$HookLog = Join-Path $ScriptDir "RustDeskWatcher.log"
$StateFile = Join-Path $ScriptDir "RustDeskWatcher.state"

# Profile configuration
$RustDeskProfile = "RustDesk"
$DefaultProfile = "TripleMonitor"

# Timing
$DebounceMs = $DebounceSeconds * 1000
$LastEventTime = [DateTime]::MinValue
$LastEventType = ""

# Connection state
$IsConnected = $false

# Log patterns - exact phrases from RustDesk logs
$ConnectPattern = 'Connection opened'
$DisconnectPattern = 'Connection closed'

# ============================================================================
# LOGGING
# ============================================================================

function Write-Log {
    param(
        [string]$Level,
        [string]$Message
    )
    $timestamp = Get-Date -Format 'yyyy-MM-dd HH:mm:ss.fff'
    $entry = "[$timestamp] [$Level] $Message"
    
    # Console output
    switch ($Level) {
        "ERROR"   { Write-Host $entry -ForegroundColor Red }
        "WARNING" { Write-Host $entry -ForegroundColor Yellow }
        "INFO"    { Write-Host $entry -ForegroundColor White }
        "DEBUG"   { if ($Verbose) { Write-Host $entry -ForegroundColor Gray } }
        default   { Write-Host $entry }
    }
    
    # File output
    try {
        Add-Content -Path $HookLog -Value $entry -ErrorAction Stop
    } catch {
        Write-Host "Failed to write to log file: $_" -ForegroundColor Red
    }
}

function Log-Info    { param([string]$Msg) Write-Log "INFO" $Msg }
function Log-Warning { param([string]$Msg) Write-Log "WARNING" $Msg }
function Log-Error   { param([string]$Msg) Write-Log "ERROR" $Msg }
function Log-Debug   { param([string]$Msg) Write-Log "DEBUG" $Msg }

# ============================================================================
# STATE MANAGEMENT
# ============================================================================

function Save-State {
    param(
        [string]$PreviousProfile,
        [bool]$Connected
    )
    
    $state = @{
        PreviousProfile = $PreviousProfile
        Connected = $Connected
        Timestamp = (Get-Date).ToString('o')
    }
    
    try {
        $state | ConvertTo-Json | Set-Content -Path $StateFile -Force
        Log-Debug "State saved: PreviousProfile=$PreviousProfile, Connected=$Connected"
    } catch {
        Log-Error "Failed to save state: $_"
    }
}

function Load-State {
    if (Test-Path $StateFile) {
        try {
            $state = Get-Content -Path $StateFile -Raw | ConvertFrom-Json
            Log-Debug "State loaded: PreviousProfile=$($state.PreviousProfile), Connected=$($state.Connected)"
            return $state
        } catch {
            Log-Warning "Failed to load state file, using defaults: $_"
        }
    }
    
    return @{
        PreviousProfile = $DefaultProfile
        Connected = $false
    }
}

function Get-CurrentProfile {
    # Try to determine current profile from DisplaySwitcher log
    $switcherLog = Join-Path $WorkspaceRoot "monitor_switcher\DisplaySwitcher.log"
    
    if (Test-Path $switcherLog) {
        try {
            $lastLines = Get-Content -Path $switcherLog -Tail 50 -ErrorAction SilentlyContinue
            foreach ($line in ($lastLines | Sort-Object -Descending)) {
                if ($line -match "Applying DisplayFusion profile:\s*(\S+)") {
                    $profile = $Matches[1]
                    Log-Debug "Detected current profile from log: $profile"
                    return $profile
                }
            }
        } catch {
            Log-Debug "Could not read DisplaySwitcher log: $_"
        }
    }
    
    return $DefaultProfile
}

# ============================================================================
# DISPLAY SWITCHING
# ============================================================================

function Invoke-DisplaySwitcher {
    param(
        [string]$Profile
    )
    
    if (-not (Test-Path $DisplaySwitcher)) {
        Log-Error "DisplaySwitcher not found at: $DisplaySwitcher"
        return $false
    }
    
    Log-Info "Switching to profile: $Profile"
    Log-Debug "Executing: $DisplaySwitcher $Profile"
    
    try {
        $process = Start-Process -FilePath "cmd.exe" `
            -ArgumentList "/c `"$DisplaySwitcher`" $Profile" `
            -WindowStyle Hidden `
            -PassThru `
            -Wait
        
        if ($process.ExitCode -eq 0) {
            Log-Info "Profile switch successful: $Profile"
            return $true
        } else {
            Log-Error "Profile switch failed with exit code: $($process.ExitCode)"
            return $false
        }
    } catch {
        Log-Error "Failed to execute DisplaySwitcher: $_"
        return $false
    }
}

# ============================================================================
# EVENT HANDLING WITH DEBOUNCE
# ============================================================================

function Test-Debounce {
    param(
        [string]$EventType
    )
    
    $now = Get-Date
    $elapsed = ($now - $script:LastEventTime).TotalMilliseconds
    
    # Same event type within debounce window - skip
    if ($EventType -eq $script:LastEventType -and $elapsed -lt $DebounceMs) {
        Log-Debug "Debounced $EventType event (${elapsed}ms < ${DebounceMs}ms)"
        return $false
    }
    
    $script:LastEventTime = $now
    $script:LastEventType = $EventType
    return $true
}

function Handle-Connect {
    if (-not (Test-Debounce "connect")) {
        return
    }
    
    if ($script:IsConnected) {
        Log-Debug "Already connected, ignoring duplicate connect event"
        return
    }
    
    Log-Info "=== RustDesk Connection Opened ==="
    
    # Get current profile before switching
    $currentProfile = Get-CurrentProfile
    Log-Info "Current profile before RustDesk: $currentProfile"
    
    # Save state
    Save-State -PreviousProfile $currentProfile -Connected $true
    $script:IsConnected = $true
    
    # Switch to RustDesk profile
    $success = Invoke-DisplaySwitcher -Profile $RustDeskProfile
    
    if (-not $success) {
        Log-Warning "Failed to switch to RustDesk profile, will retry on next event"
    }
}

function Handle-Disconnect {
    if (-not (Test-Debounce "disconnect")) {
        return
    }
    
    if (-not $script:IsConnected) {
        Log-Debug "Not connected, ignoring disconnect event"
        return
    }
    
    Log-Info "=== RustDesk Connection Closed ==="
    
    # Load saved state to get previous profile
    $state = Load-State
    $restoreProfile = $state.PreviousProfile
    
    if ([string]::IsNullOrEmpty($restoreProfile)) {
        $restoreProfile = $DefaultProfile
        Log-Warning "No previous profile saved, using default: $restoreProfile"
    }
    
    Log-Info "Restoring previous profile: $restoreProfile"
    
    # Update state
    Save-State -PreviousProfile $restoreProfile -Connected $false
    $script:IsConnected = $false
    
    # Switch back to previous profile
    $success = Invoke-DisplaySwitcher -Profile $restoreProfile
    
    if (-not $success) {
        Log-Warning "Failed to restore profile, will retry on next event"
    }
}

# ============================================================================
# LOG FILE MONITORING
# ============================================================================

function Get-LatestLogFile {
    try {
        $logs = Get-ChildItem -Path $LogDir -Filter "*.log" -File -ErrorAction Stop
        $latest = $logs | Sort-Object LastWriteTime -Descending | Select-Object -First 1
        return $latest
    } catch {
        Log-Error "Failed to enumerate log files in $LogDir : $_"
        return $null
    }
}

function Start-LogWatcher {
    $logFile = Get-LatestLogFile
    
    if (-not $logFile) {
        Log-Error "No RustDesk log files found in: $LogDir"
        Log-Info "Waiting for log files to appear..."
        
        # Wait for log directory/files to exist
        while (-not $logFile) {
            Start-Sleep -Seconds 5
            $logFile = Get-LatestLogFile
        }
    }
    
    $currentLogPath = $logFile.FullName
    Log-Info "Watching log file: $currentLogPath"
    
    # Set up FileSystemWatcher for log rollover
    $watcher = New-Object System.IO.FileSystemWatcher
    $watcher.Path = $LogDir
    $watcher.Filter = "*.log"
    $watcher.NotifyFilter = [System.IO.NotifyFilters]::FileName -bor [System.IO.NotifyFilters]::LastWrite
    $watcher.EnableRaisingEvents = $true
    
    # Handle new log file creation (rollover)
    $rolloverAction = {
        $newLog = Get-LatestLogFile
        if ($newLog -and $newLog.FullName -ne $script:currentLogPath) {
            $script:currentLogPath = $newLog.FullName
            Log-Info "Log rollover detected, now watching: $($script:currentLogPath)"
        }
    }
    
    Register-ObjectEvent -InputObject $watcher -EventName Created -Action $rolloverAction | Out-Null
    
    # Main log tailing loop with error recovery
    while ($true) {
        try {
            Log-Debug "Starting log tail on: $currentLogPath"
            
            Get-Content -Path $currentLogPath -Tail 0 -Wait -ErrorAction Stop | ForEach-Object {
                $line = $_
                
                if ($line -match $ConnectPattern) {
                    Handle-Connect
                }
                elseif ($line -match $DisconnectPattern) {
                    Handle-Disconnect
                }
            }
        } catch {
            Log-Warning "Log tail interrupted: $_"
            Log-Info "Attempting to recover in 5 seconds..."
            Start-Sleep -Seconds 5
            
            # Check for new log file
            $newLog = Get-LatestLogFile
            if ($newLog) {
                $currentLogPath = $newLog.FullName
                Log-Info "Recovered, now watching: $currentLogPath"
            }
        }
    }
}

# ============================================================================
# MAIN ENTRY POINT
# ============================================================================

function Main {
    Log-Info "=========================================="
    Log-Info "RustDeskWatcher starting..."
    Log-Info "=========================================="
    Log-Info "Script directory: $ScriptDir"
    Log-Info "DisplaySwitcher: $DisplaySwitcher"
    Log-Info "RustDesk log directory: $LogDir"
    Log-Info "Debounce interval: ${DebounceSeconds}s"
    
    # Verify DisplaySwitcher exists
    if (-not (Test-Path $DisplaySwitcher)) {
        Log-Error "DisplaySwitcher.bat not found at: $DisplaySwitcher"
        Log-Error "Please ensure the monitor_switcher folder is set up correctly"
        exit 1
    }
    
    # Load previous state (in case of restart during active session)
    $state = Load-State
    $script:IsConnected = $state.Connected
    
    if ($script:IsConnected) {
        Log-Warning "Previous state indicates active connection - may need manual profile restore"
    }
    
    # Start watching
    Start-LogWatcher
}

# Run main
Main
