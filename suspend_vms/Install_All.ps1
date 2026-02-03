#Requires -RunAsAdministrator
<#
.SYNOPSIS
    Complete installer for VM suspension on shutdown/sleep.

.DESCRIPTION
    Creates scheduled tasks to suspend VMware VMs before:
    1. System shutdown/restart (Event ID 1074)
    2. System sleep/hibernate (Event ID 42)

    IMPORTANT: VMware VMs are registered per-user. The tasks must run as
    the same user who owns the VMs (typically 'mail') for vmrun to see them.
    This installer configures tasks to run as user 'mail' with stored credentials.

    NOTE: VMware Workstation has a built-in setting for this:
    Edit > Preferences > Workspace > "When closing Workstation" and
    "Suspend virtual machines on host sleep/shutdown"
    Consider using that instead if it meets your needs.

.NOTES
    Must be run as Administrator.
#>

param(
    [string]$VMUser = "mail"
)

$ErrorActionPreference = "Stop"

$scriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$suspendScript = Join-Path $scriptDir "suspend_vms.bat"

Write-Host "========================================" -ForegroundColor Cyan
Write-Host "VM Suspension Installer" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""
Write-Host "NOTE: VMware Workstation has a built-in setting for this!" -ForegroundColor Yellow
Write-Host "  Edit > Preferences > Workspace > 'Suspend VMs on host sleep/shutdown'"
Write-Host "  Consider enabling that instead for a simpler solution."
Write-Host ""

if (-not (Test-Path $suspendScript)) {
    Write-Error "suspend_vms.bat not found at: $suspendScript"
    exit 1
}

# Get password for the user upfront
Write-Host "The tasks will run as user '$VMUser' (required for vmrun to see VMs)." -ForegroundColor Magenta
Write-Host ""
$securePassword = Read-Host "Enter password for $VMUser" -AsSecureString
$BSTR = [System.Runtime.InteropServices.Marshal]::SecureStringToBSTR($securePassword)
$password = [System.Runtime.InteropServices.Marshal]::PtrToStringAuto($BSTR)
[System.Runtime.InteropServices.Marshal]::ZeroFreeBSTR($BSTR)

Write-Host ""

# --- Step 1: Shutdown Scheduled Task ---
Write-Host "Step 1: Creating Shutdown Scheduled Task" -ForegroundColor Yellow
Write-Host "-" * 50

$shutdownTaskName = "SuspendVMware_on_shutdown"

# Remove existing task
$existingTask = Get-ScheduledTask -TaskName $shutdownTaskName -ErrorAction SilentlyContinue
if ($existingTask) {
    Unregister-ScheduledTask -TaskName $shutdownTaskName -Confirm:$false
    Write-Host "  Removed existing task"
}

# Event ID 1074 is logged when shutdown is initiated by user/app
# We use this instead of Group Policy because GP runs as SYSTEM which can't see user's VMs
$shutdownTaskXml = @"
<?xml version="1.0" encoding="UTF-16"?>
<Task version="1.4" xmlns="http://schemas.microsoft.com/windows/2004/02/mit/task">
  <RegistrationInfo>
    <Description>Suspends running VMware VMs when system shutdown or restart is initiated.</Description>
  </RegistrationInfo>
  <Triggers>
    <EventTrigger>
      <Enabled>true</Enabled>
      <Subscription>&lt;QueryList&gt;&lt;Query Id="0" Path="System"&gt;&lt;Select Path="System"&gt;*[System[Provider[@Name='User32'] and EventID=1074]]&lt;/Select&gt;&lt;/Query&gt;&lt;/QueryList&gt;</Subscription>
    </EventTrigger>
  </Triggers>
  <Principals>
    <Principal id="Author">
      <UserId>$VMUser</UserId>
      <LogonType>Password</LogonType>
      <RunLevel>HighestAvailable</RunLevel>
    </Principal>
  </Principals>
  <Settings>
    <MultipleInstancesPolicy>IgnoreNew</MultipleInstancesPolicy>
    <DisallowStartIfOnBatteries>false</DisallowStartIfOnBatteries>
    <StopIfGoingOnBatteries>false</StopIfGoingOnBatteries>
    <AllowHardTerminate>false</AllowHardTerminate>
    <StartWhenAvailable>false</StartWhenAvailable>
    <RunOnlyIfNetworkAvailable>false</RunOnlyIfNetworkAvailable>
    <IdleSettings>
      <StopOnIdleEnd>false</StopOnIdleEnd>
      <RestartOnIdle>false</RestartOnIdle>
    </IdleSettings>
    <AllowStartOnDemand>true</AllowStartOnDemand>
    <Enabled>true</Enabled>
    <Hidden>false</Hidden>
    <RunOnlyIfIdle>false</RunOnlyIfIdle>
    <UseUnifiedSchedulingEngine>true</UseUnifiedSchedulingEngine>
    <WakeToRun>false</WakeToRun>
    <ExecutionTimeLimit>PT10M</ExecutionTimeLimit>
    <Priority>4</Priority>
  </Settings>
  <Actions Context="Author">
    <Exec>
      <Command>cmd.exe</Command>
      <Arguments>/c "$suspendScript"</Arguments>
      <WorkingDirectory>$scriptDir</WorkingDirectory>
    </Exec>
  </Actions>
</Task>
"@

try {
    Register-ScheduledTask -TaskName $shutdownTaskName -Xml $shutdownTaskXml -User $VMUser -Password $password | Out-Null
    Write-Host "  Created task: $shutdownTaskName"
    Write-Host "  Trigger: Event ID 1074 (shutdown initiated)"
}
catch {
    Write-Host "  ERROR: Could not create shutdown task: $_" -ForegroundColor Red
}

Write-Host ""

# --- Step 2: Sleep/Hibernate Scheduled Task ---
Write-Host "Step 2: Creating Sleep/Hibernate Scheduled Task" -ForegroundColor Yellow
Write-Host "-" * 50

$sleepTaskName = "SuspendVMware_on_sleep"

# Remove existing task
$existingTask = Get-ScheduledTask -TaskName $sleepTaskName -ErrorAction SilentlyContinue
if ($existingTask) {
    Unregister-ScheduledTask -TaskName $sleepTaskName -Confirm:$false
    Write-Host "  Removed existing task"
}

# Event ID 42 from Kernel-Power fires when entering sleep/hibernate
$sleepTaskXml = @"
<?xml version="1.0" encoding="UTF-16"?>
<Task version="1.4" xmlns="http://schemas.microsoft.com/windows/2004/02/mit/task">
  <RegistrationInfo>
    <Description>Suspends running VMware VMs when the system enters sleep or hibernate mode.</Description>
  </RegistrationInfo>
  <Triggers>
    <EventTrigger>
      <Enabled>true</Enabled>
      <Subscription>&lt;QueryList&gt;&lt;Query Id="0" Path="System"&gt;&lt;Select Path="System"&gt;*[System[Provider[@Name='Microsoft-Windows-Kernel-Power'] and EventID=42]]&lt;/Select&gt;&lt;/Query&gt;&lt;/QueryList&gt;</Subscription>
    </EventTrigger>
  </Triggers>
  <Principals>
    <Principal id="Author">
      <UserId>$VMUser</UserId>
      <LogonType>Password</LogonType>
      <RunLevel>HighestAvailable</RunLevel>
    </Principal>
  </Principals>
  <Settings>
    <MultipleInstancesPolicy>IgnoreNew</MultipleInstancesPolicy>
    <DisallowStartIfOnBatteries>false</DisallowStartIfOnBatteries>
    <StopIfGoingOnBatteries>false</StopIfGoingOnBatteries>
    <AllowHardTerminate>false</AllowHardTerminate>
    <StartWhenAvailable>false</StartWhenAvailable>
    <RunOnlyIfNetworkAvailable>false</RunOnlyIfNetworkAvailable>
    <IdleSettings>
      <StopOnIdleEnd>false</StopOnIdleEnd>
      <RestartOnIdle>false</RestartOnIdle>
    </IdleSettings>
    <AllowStartOnDemand>true</AllowStartOnDemand>
    <Enabled>true</Enabled>
    <Hidden>false</Hidden>
    <RunOnlyIfIdle>false</RunOnlyIfIdle>
    <UseUnifiedSchedulingEngine>true</UseUnifiedSchedulingEngine>
    <WakeToRun>false</WakeToRun>
    <ExecutionTimeLimit>PT10M</ExecutionTimeLimit>
    <Priority>4</Priority>
  </Settings>
  <Actions Context="Author">
    <Exec>
      <Command>cmd.exe</Command>
      <Arguments>/c "$suspendScript"</Arguments>
      <WorkingDirectory>$scriptDir</WorkingDirectory>
    </Exec>
  </Actions>
</Task>
"@

try {
    Register-ScheduledTask -TaskName $sleepTaskName -Xml $sleepTaskXml -User $VMUser -Password $password | Out-Null
    Write-Host "  Created task: $sleepTaskName"
    Write-Host "  Trigger: Event ID 42 (entering sleep/hibernate)"
}
catch {
    Write-Host "  ERROR: Could not create sleep task: $_" -ForegroundColor Red
}

# Clear password from memory
$password = $null

Write-Host ""

# --- Step 3: Clean up old task ---
Write-Host "Step 3: Cleaning Up Old Configuration" -ForegroundColor Yellow
Write-Host "-" * 50

$oldTask = Get-ScheduledTask -TaskName "SuspendVMware_on_shutdown_or_suspend" -ErrorAction SilentlyContinue
if ($oldTask) {
    Write-Host "  Found old task 'SuspendVMware_on_shutdown_or_suspend'"
    $response = Read-Host "  Remove it? (y/n)"
    if ($response -eq 'y') {
        Unregister-ScheduledTask -TaskName "SuspendVMware_on_shutdown_or_suspend" -Confirm:$false
        Write-Host "  Old task removed"
    }
}
else {
    Write-Host "  No old tasks to clean up"
}

Write-Host ""
Write-Host "========================================" -ForegroundColor Green
Write-Host "Installation Complete!" -ForegroundColor Green
Write-Host "========================================" -ForegroundColor Green
Write-Host ""
Write-Host "Created scheduled tasks:"
Write-Host "  - $shutdownTaskName (triggers on shutdown/restart)"
Write-Host "  - $sleepTaskName (triggers on sleep/hibernate)"
Write-Host ""
Write-Host "Both run as user '$VMUser' so vmrun can see your VMs."
Write-Host ""
Write-Host "IMPORTANT CAVEAT:" -ForegroundColor Yellow
Write-Host "  Event-triggered tasks may have limited time before Windows"
Write-Host "  forcibly terminates processes during shutdown. For most reliable"
Write-Host "  results, use VMware's built-in setting instead:"
Write-Host "  Edit > Preferences > Workspace > 'Suspend VMs on host sleep/shutdown'"
Write-Host ""
Write-Host "To verify tasks: Run taskschd.msc"
Write-Host "To test: Run each task manually and check suspend_vms.log"
Write-Host ""
