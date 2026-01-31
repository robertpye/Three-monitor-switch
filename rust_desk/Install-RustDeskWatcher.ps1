# Install-RustDeskWatcher.ps1
# Installs or updates the RustDeskWatcher scheduled task
# Run as Administrator

param(
    [switch]$Uninstall,
    [switch]$Force
)

$TaskName = "RustDeskWatcher"
$ScriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$TaskXml = Join-Path $ScriptDir "RustDeskWatcherTask.xml"
$WatcherScript = Join-Path $ScriptDir "RustDeskWatcher.ps1"

# Check for admin rights
$isAdmin = ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)

if (-not $isAdmin) {
    Write-Host "ERROR: This script must be run as Administrator" -ForegroundColor Red
    Write-Host "Right-click PowerShell and select 'Run as Administrator'" -ForegroundColor Yellow
    exit 1
}

function Stop-ExistingTask {
    $task = Get-ScheduledTask -TaskName $TaskName -ErrorAction SilentlyContinue
    if ($task) {
        Write-Host "Stopping existing task..." -ForegroundColor Yellow
        Stop-ScheduledTask -TaskName $TaskName -ErrorAction SilentlyContinue
        Start-Sleep -Seconds 2
    }
}

function Uninstall-Task {
    Write-Host "Uninstalling $TaskName..." -ForegroundColor Yellow
    
    Stop-ExistingTask
    
    $task = Get-ScheduledTask -TaskName $TaskName -ErrorAction SilentlyContinue
    if ($task) {
        Unregister-ScheduledTask -TaskName $TaskName -Confirm:$false
        Write-Host "Task uninstalled successfully" -ForegroundColor Green
    } else {
        Write-Host "Task was not installed" -ForegroundColor Yellow
    }
}

function Install-Task {
    Write-Host "Installing $TaskName..." -ForegroundColor Cyan
    
    # Verify files exist
    if (-not (Test-Path $TaskXml)) {
        Write-Host "ERROR: Task XML not found: $TaskXml" -ForegroundColor Red
        exit 1
    }
    
    if (-not (Test-Path $WatcherScript)) {
        Write-Host "ERROR: Watcher script not found: $WatcherScript" -ForegroundColor Red
        exit 1
    }
    
    # Check for existing task
    $existingTask = Get-ScheduledTask -TaskName $TaskName -ErrorAction SilentlyContinue
    
    if ($existingTask -and -not $Force) {
        Write-Host "Task already exists. Use -Force to reinstall or -Uninstall to remove." -ForegroundColor Yellow
        $response = Read-Host "Reinstall? (y/N)"
        if ($response -ne 'y' -and $response -ne 'Y') {
            Write-Host "Installation cancelled" -ForegroundColor Yellow
            exit 0
        }
    }
    
    # Stop and remove existing task
    if ($existingTask) {
        Stop-ExistingTask
        Unregister-ScheduledTask -TaskName $TaskName -Confirm:$false
        Write-Host "Removed existing task" -ForegroundColor Yellow
    }
    
    # Register new task
    Write-Host "Registering scheduled task from: $TaskXml" -ForegroundColor Cyan
    
    try {
        Register-ScheduledTask -TaskName $TaskName -Xml (Get-Content $TaskXml -Raw) -Force
        Write-Host "Task registered successfully" -ForegroundColor Green
    } catch {
        Write-Host "ERROR: Failed to register task: $_" -ForegroundColor Red
        exit 1
    }
    
    # Start the task
    Write-Host "Starting task..." -ForegroundColor Cyan
    Start-ScheduledTask -TaskName $TaskName
    
    Start-Sleep -Seconds 2
    
    # Verify it's running
    $task = Get-ScheduledTask -TaskName $TaskName
    $info = Get-ScheduledTaskInfo -TaskName $TaskName
    
    Write-Host ""
    Write-Host "=== Installation Complete ===" -ForegroundColor Green
    Write-Host "Task Name: $TaskName"
    Write-Host "State: $($task.State)"
    Write-Host "Last Run: $($info.LastRunTime)"
    Write-Host ""
    Write-Host "Log file: $ScriptDir\RustDeskWatcher.log" -ForegroundColor Cyan
    Write-Host "State file: $ScriptDir\RustDeskWatcher.state" -ForegroundColor Cyan
}

# Main
if ($Uninstall) {
    Uninstall-Task
} else {
    Install-Task
}
