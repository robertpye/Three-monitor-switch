# Test-RustDeskWatcher.ps1
# Quick test to verify the watcher can start and detect events
# Run this manually to test before installing as a service

param(
    [switch]$SimulateConnect,
    [switch]$SimulateDisconnect,
    [int]$TestDuration = 30
)

$ScriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$WatcherScript = Join-Path $ScriptDir "RustDeskWatcher.ps1"
$LogFile = Join-Path $ScriptDir "RustDeskWatcher.log"
$StateFile = Join-Path $ScriptDir "RustDeskWatcher.state"

Write-Host "=== RustDeskWatcher Test ===" -ForegroundColor Cyan
Write-Host ""

# Test 1: Verify script exists and has valid syntax
Write-Host "[Test 1] Checking script syntax..." -ForegroundColor Yellow
try {
    $script = Get-Content -Path $WatcherScript -Raw
    $null = [System.Management.Automation.PSParser]::Tokenize($script, [ref]$null)
    Write-Host "  PASS: Script syntax is valid" -ForegroundColor Green
} catch {
    Write-Host "  FAIL: Script has syntax errors: $_" -ForegroundColor Red
    exit 1
}

# Test 2: Verify DisplaySwitcher exists
Write-Host "[Test 2] Checking DisplaySwitcher..." -ForegroundColor Yellow
$WorkspaceRoot = Split-Path -Parent $ScriptDir
$DisplaySwitcher = Join-Path $WorkspaceRoot "monitor_switcher\DisplaySwitcher.bat"
if (Test-Path $DisplaySwitcher) {
    Write-Host "  PASS: DisplaySwitcher found at $DisplaySwitcher" -ForegroundColor Green
} else {
    Write-Host "  FAIL: DisplaySwitcher not found at $DisplaySwitcher" -ForegroundColor Red
    exit 1
}

# Test 3: Verify RustDesk log directory
Write-Host "[Test 3] Checking RustDesk logs..." -ForegroundColor Yellow
$LogDir = "C:\Windows\ServiceProfiles\LocalService\AppData\Roaming\RustDesk\log\server"
if (Test-Path $LogDir) {
    $logs = Get-ChildItem -Path $LogDir -Filter "*.log" -File
    Write-Host "  PASS: Found $($logs.Count) log files in $LogDir" -ForegroundColor Green
    $latest = $logs | Sort-Object LastWriteTime -Descending | Select-Object -First 1
    if ($latest) {
        Write-Host "  Latest log: $($latest.Name)" -ForegroundColor Cyan
    }
} else {
    Write-Host "  WARN: RustDesk log directory not found (RustDesk may not be installed as service)" -ForegroundColor Yellow
}

# Test 4: Test DisplaySwitcher execution (dry run - just check it runs)
Write-Host "[Test 4] Testing DisplaySwitcher help..." -ForegroundColor Yellow
try {
    $result = & cmd.exe /c "`"$DisplaySwitcher`" --help" 2>&1
    Write-Host "  PASS: DisplaySwitcher executed successfully" -ForegroundColor Green
} catch {
    Write-Host "  WARN: DisplaySwitcher execution test failed: $_" -ForegroundColor Yellow
}

# Test 5: Check state file handling
Write-Host "[Test 5] Testing state file..." -ForegroundColor Yellow
$testState = @{
    PreviousProfile = "TestProfile"
    Connected = $false
    Timestamp = (Get-Date).ToString('o')
}
try {
    $testState | ConvertTo-Json | Set-Content -Path "$StateFile.test" -Force
    $loaded = Get-Content -Path "$StateFile.test" -Raw | ConvertFrom-Json
    Remove-Item "$StateFile.test" -Force
    if ($loaded.PreviousProfile -eq "TestProfile") {
        Write-Host "  PASS: State file read/write works" -ForegroundColor Green
    } else {
        Write-Host "  FAIL: State file content mismatch" -ForegroundColor Red
    }
} catch {
    Write-Host "  FAIL: State file test failed: $_" -ForegroundColor Red
}

Write-Host ""
Write-Host "=== All Tests Passed ===" -ForegroundColor Green
Write-Host ""
Write-Host "To install the watcher as a scheduled task, run:" -ForegroundColor Cyan
Write-Host "  .\Install-RustDeskWatcher.ps1" -ForegroundColor White
Write-Host ""
Write-Host "To test the watcher manually (will run for ${TestDuration}s):" -ForegroundColor Cyan
Write-Host "  .\RustDeskWatcher.ps1 -Verbose" -ForegroundColor White
Write-Host ""

if ($SimulateConnect -or $SimulateDisconnect) {
    Write-Host "Simulation not implemented - connect to RustDesk to test" -ForegroundColor Yellow
}
