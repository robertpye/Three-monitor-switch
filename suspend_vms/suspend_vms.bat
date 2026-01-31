@echo off
setlocal EnableExtensions EnableDelayedExpansion

rem -----------------------------------------------------------------
rem VMWare2.cmd
rem Suspends all running VMware Workstation/Player VMs (vmrun-based).
rem Intended to be called by APC PowerChute Serial Shutdown.
rem -----------------------------------------------------------------

set "LOGFILE=%~dp0suspend_vms.log"

call :log "==== VMWare2.cmd starting ===="

rem Prefer vmrun from PATH, otherwise probe common install locations
set "VMRUN="
for /f "delims=" %%F in ('where vmrun.exe 2^>nul') do if not defined VMRUN set "VMRUN=%%F"
if not defined VMRUN if exist "%ProgramFiles%\VMware\VMware Workstation\vmrun.exe" set "VMRUN=%ProgramFiles%\VMware\VMware Workstation\vmrun.exe"
if not defined VMRUN if exist "%ProgramFiles(x86)%\VMware\VMware Workstation\vmrun.exe" set "VMRUN=%ProgramFiles(x86)%\VMware\VMware Workstation\vmrun.exe"
if not defined VMRUN if exist "%ProgramFiles%\VMware\VMware Player\vmrun.exe" set "VMRUN=%ProgramFiles%\VMware\VMware Player\vmrun.exe"
if not defined VMRUN if exist "%ProgramFiles(x86)%\VMware\VMware Player\vmrun.exe" set "VMRUN=%ProgramFiles(x86)%\VMware\VMware Player\vmrun.exe"

if not defined VMRUN (
  call :log "ERROR: vmrun not found. Ensure VMware Workstation/Player is installed."
  exit /b 2
)

call :log "Using vmrun: %VMRUN%"

rem Ask vmrun for list of running VMs; parse output lines that end with .vmx
set "VMLIST=%TEMP%\vmrun_list_%RANDOM%.txt"
"%VMRUN%" list > "%VMLIST%" 2>&1
if errorlevel 1 (
  call :log "ERROR: vmrun list failed. Output:"
  for /f "usebackq delims=" %%L in ("%VMLIST%") do call :log "  %%L"
  del /q "%VMLIST%" >nul 2>&1
  exit /b 3
)

set /a COUNT=0
set /a FAIL=0
for /f "usebackq delims=" %%L in ("%VMLIST%") do (
  echo %%L| findstr /i /r "\.vmx" >nul
  if not errorlevel 1 (
    set /a COUNT+=1
    call :suspendvm "%%L"
  )
)

del /q "%VMLIST%" >nul 2>&1

if %COUNT% EQU 0 (
  call :log "No running VMs detected."
) else if %FAIL% GTR 0 (
  call :log "Attempted %COUNT% VM(s), %FAIL% failed to suspend."
) else (
  call :log "Suspended %COUNT% VM(s) successfully."
)

call :log "==== VMWare2.cmd completed ===="
exit /b 0

:suspendvm
set "VMX=%~1"
call :log "Suspending VM (%COUNT%): %VMX%"
"%VMRUN%" suspend "%VMX%" soft >> "%LOGFILE%" 2>&1
if not errorlevel 1 exit /b 0
call :log "WARN: soft suspend failed; trying hard suspend: %VMX%"
"%VMRUN%" suspend "%VMX%" hard >> "%LOGFILE%" 2>&1
if not errorlevel 1 exit /b 0
call :log "ERROR: hard suspend failed: %VMX%"
set /a FAIL+=1
exit /b 1

:log
set "TS=%DATE% %TIME%"
>> "%LOGFILE%" echo [%TS%] %*
exit /b 0
