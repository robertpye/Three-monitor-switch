@echo off
setlocal enabledelayedexpansion

:: ============================================================================
:: DisplaySwitcher.bat - Windows Display Configuration Manager
:: ============================================================================
:: A robust batch script solution for managing 3-monitor configurations using
:: DisplayFusion. Provides reliable switching with validation and error recovery.
:: ============================================================================

:: ============================================================================
:: CONFIGURATION VARIABLES - 3-Monitor Setup
:: ============================================================================

:: Left Monitor - Portrait
set "LEFT_MONITOR_ID=1"
set "LEFT_RESOLUTION=1920x1080"
set "LEFT_ORIENTATION=Portrait"
set "LEFT_POSITION=0,0"

:: Center Monitor - Primary Landscape
set "CENTER_MONITOR_ID=2"
set "CENTER_RESOLUTION=3840x2160"
set "CENTER_ORIENTATION=Landscape"
set "CENTER_POSITION=1080,0"
set "CENTER_PRIMARY=true"

:: Right Monitor - Landscape
set "RIGHT_MONITOR_ID=3"
set "RIGHT_RESOLUTION=1920x1200"
set "RIGHT_ORIENTATION=Landscape"
set "RIGHT_POSITION=4920,0"

:: Profile Names
set "PROFILE_ALL_MONITORS=TripleMonitor"
set "PROFILE_CENTER_ONLY=SingleCenter"
set "PROFILE_CENTER_RIGHT=DualWork"
set "PROFILE_CENTER_LEFT=DualVertical"
set "PROFILE_RUSTDESK=RustDesk"

:: System Configuration
set "LOG_FILE=%~dp0DisplaySwitcher.log"
set "MAX_LOG_ENTRIES=100"
set "VERBOSE_MODE=false"
set "SCRIPT_VERSION=1.0.0"

:: DisplayFusion executable path
set "DF_COMMAND=C:\Program Files\DisplayFusion\DisplayFusionCommand.exe"

:: Timing configuration (in seconds)
set "DEFAULT_STABILIZATION_DELAY=3"
set "MIN_STABILIZATION_DELAY=1"
set "MAX_STABILIZATION_DELAY=10"
set "POLL_INTERVAL=1"
set "MAX_POLL_ATTEMPTS=15"

:: State Variables
set "CURRENT_PROFILE="
set "BACKUP_PROFILE="
set "LAST_SUCCESSFUL_CONFIG="
set "VALIDATION_STATUS="
set "EXIT_CODE=0"

:: ============================================================================
:: MAIN ENTRY POINT
:: ============================================================================

call :InitializeSystem
if !ERRORLEVEL! neq 0 (
    echo ERROR: System initialization failed
    exit /b 1
)

call :ParseArguments %*
if !ERRORLEVEL! neq 0 (
    call :DisplayUsage
    exit /b 1
)

call :ExecuteConfiguration
set "EXIT_CODE=!ERRORLEVEL!"

call :Cleanup
exit /b !EXIT_CODE!

:: ============================================================================
:: SYSTEM INITIALIZATION
:: ============================================================================

:InitializeSystem
    call :LogInfo "DisplaySwitcher v%SCRIPT_VERSION% starting..."
    call :LogInfo "Initializing system..."
    
    :: Verify log file is writable
    echo. >> "%LOG_FILE%" 2>nul
    if !ERRORLEVEL! neq 0 (
        echo ERROR: Cannot write to log file: %LOG_FILE%
        exit /b 1
    )
    
    call :LogInfo "System initialization complete"
    exit /b 0

:: ============================================================================
:: COMMAND-LINE ARGUMENT PARSING
:: ============================================================================

:ParseArguments
    set "REQUESTED_PROFILE="
    set "ARG_COUNT=0"
    
    :: Count arguments
    for %%a in (%*) do set /a ARG_COUNT+=1
    
    :: If no arguments, display usage
    if !ARG_COUNT! equ 0 (
        call :LogInfo "No arguments provided"
        exit /b 1
    )
    
    :: Parse first argument as profile name or command
    set "FIRST_ARG=%~1"
    
    :: Check for help flag
    if /i "!FIRST_ARG!"=="/?" goto :ShowHelp
    if /i "!FIRST_ARG!"=="-h" goto :ShowHelp
    if /i "!FIRST_ARG!"=="--help" goto :ShowHelp
    if /i "!FIRST_ARG!"=="help" goto :ShowHelp
    
    :: Check for verbose flag
    if /i "!FIRST_ARG!"=="-v" (
        set "VERBOSE_MODE=true"
        call :LogInfo "Verbose mode enabled"
        set "FIRST_ARG=%~2"
        if "!FIRST_ARG!"=="" (
            call :LogInfo "No profile specified after verbose flag"
            exit /b 1
        )
    )
    if /i "!FIRST_ARG!"=="--verbose" (
        set "VERBOSE_MODE=true"
        call :LogInfo "Verbose mode enabled"
        set "FIRST_ARG=%~2"
        if "!FIRST_ARG!"=="" (
            call :LogInfo "No profile specified after verbose flag"
            exit /b 1
        )
    )
    
    :: Parse profile name
    if /i "!FIRST_ARG!"=="triple" set "REQUESTED_PROFILE=%PROFILE_ALL_MONITORS%"
    if /i "!FIRST_ARG!"=="all" set "REQUESTED_PROFILE=%PROFILE_ALL_MONITORS%"
    if /i "!FIRST_ARG!"=="single" set "REQUESTED_PROFILE=%PROFILE_CENTER_ONLY%"
    if /i "!FIRST_ARG!"=="center" set "REQUESTED_PROFILE=%PROFILE_CENTER_ONLY%"
    if /i "!FIRST_ARG!"=="dual" set "REQUESTED_PROFILE=%PROFILE_CENTER_RIGHT%"
    if /i "!FIRST_ARG!"=="work" set "REQUESTED_PROFILE=%PROFILE_CENTER_RIGHT%"
    if /i "!FIRST_ARG!"=="vertical" set "REQUESTED_PROFILE=%PROFILE_CENTER_LEFT%"
    if /i "!FIRST_ARG!"=="left" set "REQUESTED_PROFILE=%PROFILE_CENTER_LEFT%"
    if /i "!FIRST_ARG!"=="rustdesk" set "REQUESTED_PROFILE=%PROFILE_RUSTDESK%"
    if /i "!FIRST_ARG!"=="remote" set "REQUESTED_PROFILE=%PROFILE_RUSTDESK%"
    
    :: If profile not recognized, try as direct profile name
    if "!REQUESTED_PROFILE!"=="" (
        set "REQUESTED_PROFILE=!FIRST_ARG!"
        call :LogInfo "Using custom profile name: !REQUESTED_PROFILE!"
    )
    
    call :LogInfo "Requested profile: !REQUESTED_PROFILE!"
    exit /b 0

:ShowHelp
    call :DisplayUsage
    exit /b 1

:: ============================================================================
:: CONFIGURATION EXECUTION (Placeholder)
:: ============================================================================

:ExecuteConfiguration
    call :LogInfo "Executing configuration for profile: !REQUESTED_PROFILE!"
    
    :: Query current state before making changes
    call :QueryDisplayFusionState CURRENT_MONITOR_COUNT
    call :LogInfo "Current monitor count: !DF_STATE_MONITOR_COUNT!"
    
    :: Apply the requested DisplayFusion profile
    call :ApplyDisplayFusionProfile "!REQUESTED_PROFILE!"
    set "APPLY_RESULT=!ERRORLEVEL!"
    
    if !APPLY_RESULT! neq 0 (
        call :LogError "Failed to apply configuration profile"
        exit /b !APPLY_RESULT!
    )
    
    :: Query state after changes
    call :QueryDisplayFusionState NEW_MONITOR_COUNT
    call :LogInfo "Monitor count after change: !DF_STATE_MONITOR_COUNT!"
    
    call :LogInfo "Configuration applied successfully"
    exit /b 0

:: ============================================================================
:: USAGE DISPLAY
:: ============================================================================

:DisplayUsage
    echo.
    echo DisplaySwitcher v%SCRIPT_VERSION% - Windows Display Configuration Manager
    echo.
    echo Usage: DisplaySwitcher.bat [options] ^<profile^>
    echo.
    echo Profiles:
    echo   triple, all      - Enable all three monitors (Left Portrait, Center Primary, Right)
    echo   single, center   - Enable center monitor only
    echo   dual, work       - Enable center and right monitors
    echo   vertical, left   - Enable center and left monitors
    echo   rustdesk, remote - RustDesk remote access configuration
    echo.
    echo Options:
    echo   -v, --verbose    - Enable verbose logging
    echo   -h, --help, /?   - Display this help message
    echo.
    echo Monitor Configuration:
    echo   Left:   1920x1080 %LEFT_ORIENTATION% at %LEFT_POSITION%
    echo   Center: 3840x2160 %CENTER_ORIENTATION% (Primary) at %CENTER_POSITION%
    echo   Right:  %RIGHT_RESOLUTION% %RIGHT_ORIENTATION% at %RIGHT_POSITION%
    echo.
    echo Examples:
    echo   DisplaySwitcher.bat triple
    echo   DisplaySwitcher.bat -v single
    echo   DisplaySwitcher.bat work
    echo.
    exit /b 0

:: ============================================================================
:: LOGGING INFRASTRUCTURE
:: ============================================================================

:LogInfo
    set "LOG_MESSAGE=%~1"
    call :WriteLog "INFO" "!LOG_MESSAGE!"
    exit /b 0

:LogWarning
    set "LOG_MESSAGE=%~1"
    call :WriteLog "WARNING" "!LOG_MESSAGE!"
    exit /b 0

:LogError
    set "LOG_MESSAGE=%~1"
    call :WriteLog "ERROR" "!LOG_MESSAGE!"
    exit /b 0

:LogVerbose
    if "!VERBOSE_MODE!"=="true" (
        set "LOG_MESSAGE=%~1"
        call :WriteLog "VERBOSE" "!LOG_MESSAGE!"
    )
    exit /b 0

:WriteLog
    set "LOG_LEVEL=%~1"
    set "LOG_MESSAGE=%~2"
    
    :: Get timestamp
    call :GetTimestamp TIMESTAMP
    
    :: Format log entry
    set "LOG_ENTRY=[!TIMESTAMP!] [!LOG_LEVEL!] !LOG_MESSAGE!"
    
    :: Write to console
    echo !LOG_ENTRY!
    
    :: Write to log file
    echo !LOG_ENTRY! >> "%LOG_FILE%"
    
    :: TODO: Implement rolling log with MAX_LOG_ENTRIES limit in future tasks
    
    exit /b 0

:GetTimestamp
    :: Generate timestamp in format: YYYY-MM-DD HH:MM:SS
    for /f "tokens=1-4 delims=/ " %%a in ('date /t') do (
        set "DATE_PART=%%d-%%b-%%c"
    )
    for /f "tokens=1-2 delims=: " %%a in ('time /t') do (
        set "TIME_PART=%%a:%%b"
    )
    
    :: Use more reliable timestamp method
    for /f "tokens=1-6 delims=/:. " %%a in ("%date% %time%") do (
        set "YEAR=%%c"
        set "MONTH=%%a"
        set "DAY=%%b"
        set "HOUR=%%d"
        set "MINUTE=%%e"
        set "SECOND=%%f"
    )
    
    :: Pad single digits with zero
    if "!MONTH:~1,1!"=="" set "MONTH=0!MONTH!"
    if "!DAY:~1,1!"=="" set "DAY=0!DAY!"
    if "!HOUR:~1,1!"=="" set "HOUR=0!HOUR!"
    if "!MINUTE:~1,1!"=="" set "MINUTE=0!MINUTE!"
    if "!SECOND:~1,1!"=="" set "SECOND=0!SECOND!"
    
    set "%~1=!YEAR!-!MONTH!-!DAY! !HOUR!:!MINUTE!:!SECOND!"
    exit /b 0

:: ============================================================================
:: DISPLAYFUSION INTERFACE LAYER
:: ============================================================================

:ApplyDisplayFusionProfile
    :: Applies a DisplayFusion monitor profile
    :: Parameters: %1 = Profile name
    :: Returns: 0 on success, non-zero on failure
    set "PROFILE_TO_APPLY=%~1"
    
    if "!PROFILE_TO_APPLY!"=="" (
        call :LogError "ApplyDisplayFusionProfile: No profile name provided"
        exit /b 1
    )
    
    call :LogInfo "Applying DisplayFusion profile: !PROFILE_TO_APPLY!"
    call :LogVerbose "Executing: ""%DF_COMMAND%"" -monitorloadprofile ""!PROFILE_TO_APPLY!"""
    
    :: Execute DisplayFusion command to load monitor profile
    "!DF_COMMAND!" -monitorloadprofile "!PROFILE_TO_APPLY!"
    set "DF_RESULT=!ERRORLEVEL!"
    
    :: DisplayFusion returns 0 on success
    if !DF_RESULT! equ 0 (
        call :LogInfo "Profile command sent successfully: !PROFILE_TO_APPLY!"
        :: Wait for monitors to stabilize after profile change
        call :CalculateAdaptiveDelay "profile" PROFILE_DELAY
        call :WaitForStabilization !PROFILE_DELAY!
        exit /b 0
    )
    
    :: Handle DisplayFusion error codes
    call :HandleDisplayFusionError !DF_RESULT! "monitorloadprofile"
    call :LogError "Failed to apply profile: !PROFILE_TO_APPLY! (Error: !DF_RESULT!)"
    exit /b !DF_RESULT!

:EnableMonitor
    :: Enables a specific monitor via DisplayFusion function/profile
    :: Note: DisplayFusion doesn't have direct enable command - uses profiles or functions
    :: Parameters: %1 = Monitor ID or identifier
    :: Returns: 0 on success, non-zero on failure
    set "MONITOR_TO_ENABLE=%~1"
    
    if "!MONITOR_TO_ENABLE!"=="" (
        call :LogError "EnableMonitor: No monitor ID provided"
        exit /b 1
    )
    
    call :LogInfo "Enabling monitor: !MONITOR_TO_ENABLE!"
    
    :: Try to run a DisplayFusion function named "Enable Monitor X"
    :: User must create this function in DisplayFusion settings
    set "FUNCTION_NAME=Enable Monitor !MONITOR_TO_ENABLE!"
    call :LogVerbose "Attempting to run function: !FUNCTION_NAME!"
    
    "!DF_COMMAND!" -functionrun "!FUNCTION_NAME!"
    set "DF_RESULT=!ERRORLEVEL!"
    
    if !DF_RESULT! equ 0 (
        call :LogInfo "Monitor enable command sent: !MONITOR_TO_ENABLE!"
        call :WaitForStabilization 3
        exit /b 0
    )
    
    :: Function may not exist - log warning but don't fail
    call :LogWarning "Enable function not found for monitor !MONITOR_TO_ENABLE! - use profile-based switching instead"
    exit /b !DF_RESULT!

:DisableMonitor
    :: Disables a specific monitor via DisplayFusion function/profile
    :: Note: DisplayFusion doesn't have direct disable command - uses profiles or functions
    :: Parameters: %1 = Monitor ID or identifier
    :: Returns: 0 on success, non-zero on failure
    set "MONITOR_TO_DISABLE=%~1"
    
    if "!MONITOR_TO_DISABLE!"=="" (
        call :LogError "DisableMonitor: No monitor ID provided"
        exit /b 1
    )
    
    call :LogInfo "Disabling monitor: !MONITOR_TO_DISABLE!"
    
    :: Try to run a DisplayFusion function named "Disable Monitor X"
    :: User must create this function in DisplayFusion settings
    set "FUNCTION_NAME=Disable Monitor !MONITOR_TO_DISABLE!"
    call :LogVerbose "Attempting to run function: !FUNCTION_NAME!"
    
    "!DF_COMMAND!" -functionrun "!FUNCTION_NAME!"
    set "DF_RESULT=!ERRORLEVEL!"
    
    if !DF_RESULT! equ 0 (
        call :LogInfo "Monitor disable command sent: !MONITOR_TO_DISABLE!"
        call :WaitForStabilization 2
        exit /b 0
    )
    
    :: Function may not exist - log warning but don't fail
    call :LogWarning "Disable function not found for monitor !MONITOR_TO_DISABLE! - use profile-based switching instead"
    exit /b !DF_RESULT!

:QueryDisplayFusionState
    :: Queries the current display state
    :: Note: DisplayFusion CLI doesn't have a direct query command
    :: This function uses Windows WMI to get monitor information
    :: Parameters: %1 = Output variable name for monitor count
    :: Returns: 0 on success, sets DF_STATE_* variables
    set "OUTPUT_VAR=%~1"
    
    call :LogInfo "Querying display state..."
    
    :: Use PowerShell to query monitor information via WMI
    set "TEMP_STATE_FILE=%TEMP%\df_state_%RANDOM%.txt"
    
    powershell -NoProfile -Command "Get-CimInstance -Namespace root\wmi -ClassName WmiMonitorBasicDisplayParams -ErrorAction SilentlyContinue | ForEach-Object { $_.InstanceName }" > "!TEMP_STATE_FILE!" 2>nul
    set "QUERY_RESULT=!ERRORLEVEL!"
    
    if !QUERY_RESULT! neq 0 (
        call :LogWarning "Could not query monitor state via WMI"
        :: Try alternative method using Get-CimInstance Win32_DesktopMonitor
        powershell -NoProfile -Command "Get-CimInstance Win32_DesktopMonitor | Select-Object -ExpandProperty DeviceID" > "!TEMP_STATE_FILE!" 2>nul
    )
    
    :: Count monitors from output
    set "DF_STATE_MONITOR_COUNT=0"
    if exist "!TEMP_STATE_FILE!" (
        for /f "usebackq tokens=*" %%a in ("!TEMP_STATE_FILE!") do (
            if not "%%a"=="" (
                set /a DF_STATE_MONITOR_COUNT+=1
                set "DF_STATE_MONITOR_!DF_STATE_MONITOR_COUNT!=%%a"
                call :LogVerbose "Found monitor: %%a"
            )
        )
        del "!TEMP_STATE_FILE!" 2>nul
    )
    
    call :LogInfo "Display state query complete. Found !DF_STATE_MONITOR_COUNT! monitors."
    
    :: Set output variable if provided
    if not "!OUTPUT_VAR!"=="" (
        set "!OUTPUT_VAR!=!DF_STATE_MONITOR_COUNT!"
    )
    
    exit /b 0

:HandleDisplayFusionError
    :: Handles DisplayFusion command error codes
    :: Parameters: %1 = Error code, %2 = Command name
    :: Returns: 0 if no error, 1 if error occurred
    set "ERROR_CODE=%~1"
    set "COMMAND_NAME=%~2"
    
    :: Error code 0 = success
    if "!ERROR_CODE!"=="0" (
        call :LogVerbose "DisplayFusion command '!COMMAND_NAME!' completed successfully"
        exit /b 0
    )
    
    :: Error code 1 = general failure
    if "!ERROR_CODE!"=="1" (
        call :LogError "DisplayFusion command '!COMMAND_NAME!' failed: General error"
        exit /b 1
    )
    
    :: Error code 2 = invalid parameters
    if "!ERROR_CODE!"=="2" (
        call :LogError "DisplayFusion command '!COMMAND_NAME!' failed: Invalid parameters"
        exit /b 1
    )
    
    :: Error code 3 = profile not found
    if "!ERROR_CODE!"=="3" (
        call :LogError "DisplayFusion command '!COMMAND_NAME!' failed: Profile not found"
        exit /b 1
    )
    
    :: Error code 4 = monitor not found
    if "!ERROR_CODE!"=="4" (
        call :LogError "DisplayFusion command '!COMMAND_NAME!' failed: Monitor not found"
        exit /b 1
    )
    
    :: Error code 5 = DisplayFusion not running
    if "!ERROR_CODE!"=="5" (
        call :LogError "DisplayFusion command '!COMMAND_NAME!' failed: DisplayFusion not running"
        exit /b 1
    )
    
    :: Error code 9009 = command not found (DisplayFusion not installed)
    if "!ERROR_CODE!"=="9009" (
        call :LogError "DisplayFusion command '!COMMAND_NAME!' failed: DisplayFusionCommand.exe not found"
        exit /b 1
    )
    
    :: Unknown error code
    call :LogWarning "DisplayFusion command '!COMMAND_NAME!' returned unknown error code: !ERROR_CODE!"
    exit /b 1

:: ============================================================================
:: TIMING AND STABILIZATION FUNCTIONS
:: ============================================================================

:WaitForStabilization
    :: Waits for monitors to stabilize after a configuration change
    :: Parameters: %1 = Delay in seconds (optional, defaults to DEFAULT_STABILIZATION_DELAY)
    :: Returns: 0 on success
    set "WAIT_DELAY=%~1"
    
    :: Use default if not specified
    if "!WAIT_DELAY!"=="" set "WAIT_DELAY=!DEFAULT_STABILIZATION_DELAY!"
    
    :: Validate delay is within bounds
    if !WAIT_DELAY! lss !MIN_STABILIZATION_DELAY! set "WAIT_DELAY=!MIN_STABILIZATION_DELAY!"
    if !WAIT_DELAY! gtr !MAX_STABILIZATION_DELAY! set "WAIT_DELAY=!MAX_STABILIZATION_DELAY!"
    
    call :LogInfo "Waiting !WAIT_DELAY! seconds for monitor stabilization..."
    call :LogVerbose "Stabilization delay: !WAIT_DELAY!s (min: !MIN_STABILIZATION_DELAY!s, max: !MAX_STABILIZATION_DELAY!s)"
    
    :: Wait for the specified duration
    timeout /t !WAIT_DELAY! /nobreak >nul 2>&1
    
    call :LogVerbose "Stabilization wait complete"
    exit /b 0

:WaitForMonitorStabilization
    :: Waits for a specific monitor to stabilize by polling its state
    :: Parameters: %1 = Monitor ID, %2 = Expected state (enabled/disabled), %3 = Max wait time (optional)
    :: Returns: 0 if monitor reached expected state, 1 if timeout
    set "MONITOR_ID=%~1"
    set "EXPECTED_STATE=%~2"
    set "MAX_WAIT=%~3"
    
    if "!MONITOR_ID!"=="" (
        call :LogError "WaitForMonitorStabilization: No monitor ID provided"
        exit /b 1
    )
    
    if "!EXPECTED_STATE!"=="" set "EXPECTED_STATE=enabled"
    if "!MAX_WAIT!"=="" set "MAX_WAIT=!MAX_POLL_ATTEMPTS!"
    
    call :LogInfo "Waiting for monitor !MONITOR_ID! to reach state: !EXPECTED_STATE!"
    call :LogVerbose "Max poll attempts: !MAX_WAIT!, Poll interval: !POLL_INTERVAL!s"
    
    set "POLL_COUNT=0"
    
    :PollMonitorLoop
        set /a POLL_COUNT+=1
        
        if !POLL_COUNT! gtr !MAX_WAIT! (
            call :LogWarning "Monitor !MONITOR_ID! did not reach expected state within timeout"
            exit /b 1
        )
        
        call :LogVerbose "Poll attempt !POLL_COUNT!/!MAX_WAIT! for monitor !MONITOR_ID!"
        
        :: Check current monitor state
        call :CheckMonitorState "!MONITOR_ID!" CURRENT_STATE
        
        if /i "!CURRENT_STATE!"=="!EXPECTED_STATE!" (
            call :LogInfo "Monitor !MONITOR_ID! reached expected state: !EXPECTED_STATE!"
            exit /b 0
        )
        
        :: Wait before next poll
        timeout /t !POLL_INTERVAL! /nobreak >nul 2>&1
        goto :PollMonitorLoop

:CheckMonitorState
    :: Checks the current state of monitors using Windows APIs
    :: Parameters: %1 = Monitor ID (not used directly - checks all monitors), %2 = Output variable name
    :: Returns: Sets output variable to monitor count or "unknown"
    set "CHECK_MONITOR_ID=%~1"
    set "STATE_OUTPUT_VAR=%~2"
    
    call :LogVerbose "Checking monitor state..."
    
    :: Query current monitor count using PowerShell
    for /f %%a in ('powershell -NoProfile -Command "(Get-CimInstance Win32_DesktopMonitor).Count" 2^>nul') do (
        set "MONITOR_COUNT=%%a"
    )
    
    if defined MONITOR_COUNT (
        call :LogVerbose "Current monitor count: !MONITOR_COUNT!"
        set "!STATE_OUTPUT_VAR!=!MONITOR_COUNT!"
    ) else (
        call :LogVerbose "Could not determine monitor state"
        set "!STATE_OUTPUT_VAR!=unknown"
    )
    
    exit /b 0

:DetectMonitorChangeComplete
    :: Detects when monitors have finished processing configuration changes
    :: Parameters: %1 = Expected monitor count (optional)
    :: Returns: 0 when changes are complete, 1 on timeout
    set "EXPECTED_COUNT=%~1"
    
    call :LogInfo "Detecting monitor change completion..."
    
    :: Initial delay to let changes start
    call :WaitForStabilization 1
    
    :: Query initial state
    call :QueryDisplayFusionState INITIAL_COUNT
    set "PREV_COUNT=!DF_STATE_MONITOR_COUNT!"
    
    call :LogVerbose "Initial monitor count: !PREV_COUNT!"
    
    :: Poll until state stabilizes
    set "STABLE_CHECKS=0"
    set "REQUIRED_STABLE_CHECKS=3"
    set "DETECT_ATTEMPTS=0"
    set "MAX_DETECT_ATTEMPTS=10"
    
    :DetectChangeLoop
        set /a DETECT_ATTEMPTS+=1
        
        if !DETECT_ATTEMPTS! gtr !MAX_DETECT_ATTEMPTS! (
            call :LogWarning "Monitor change detection timed out"
            exit /b 1
        )
        
        :: Wait between checks
        timeout /t !POLL_INTERVAL! /nobreak >nul 2>&1
        
        :: Query current state
        call :QueryDisplayFusionState CURRENT_COUNT
        set "CURR_COUNT=!DF_STATE_MONITOR_COUNT!"
        
        call :LogVerbose "Detection attempt !DETECT_ATTEMPTS!: Previous=!PREV_COUNT!, Current=!CURR_COUNT!"
        
        :: Check if state is stable
        if "!CURR_COUNT!"=="!PREV_COUNT!" (
            set /a STABLE_CHECKS+=1
            call :LogVerbose "Stable check !STABLE_CHECKS!/!REQUIRED_STABLE_CHECKS!"
            
            if !STABLE_CHECKS! geq !REQUIRED_STABLE_CHECKS! (
                call :LogInfo "Monitor configuration stabilized after !DETECT_ATTEMPTS! checks"
                
                :: Verify expected count if provided
                if not "!EXPECTED_COUNT!"=="" (
                    if not "!CURR_COUNT!"=="!EXPECTED_COUNT!" (
                        call :LogWarning "Monitor count mismatch: Expected !EXPECTED_COUNT!, Got !CURR_COUNT!"
                    )
                )
                
                exit /b 0
            )
        ) else (
            :: State changed, reset stable counter
            set "STABLE_CHECKS=0"
            call :LogVerbose "State changed, resetting stability counter"
        )
        
        set "PREV_COUNT=!CURR_COUNT!"
        goto :DetectChangeLoop

:CalculateAdaptiveDelay
    :: Calculates an adaptive delay based on the type of operation
    :: Parameters: %1 = Operation type (profile/enable/disable), %2 = Output variable name
    :: Returns: Sets output variable to recommended delay in seconds
    set "OPERATION_TYPE=%~1"
    set "DELAY_OUTPUT_VAR=%~2"
    
    :: Default delay
    set "CALCULATED_DELAY=!DEFAULT_STABILIZATION_DELAY!"
    
    :: Adjust based on operation type
    if /i "!OPERATION_TYPE!"=="profile" (
        :: Profile changes may affect multiple monitors, need longer delay
        set "CALCULATED_DELAY=5"
    )
    
    if /i "!OPERATION_TYPE!"=="enable" (
        :: Enabling a monitor typically needs moderate delay
        set "CALCULATED_DELAY=3"
    )
    
    if /i "!OPERATION_TYPE!"=="disable" (
        :: Disabling is usually faster
        set "CALCULATED_DELAY=2"
    )
    
    if /i "!OPERATION_TYPE!"=="resolution" (
        :: Resolution changes need time for display to adjust
        set "CALCULATED_DELAY=4"
    )
    
    if /i "!OPERATION_TYPE!"=="orientation" (
        :: Orientation changes need time for rendering adjustment
        set "CALCULATED_DELAY=4"
    )
    
    call :LogVerbose "Calculated adaptive delay for '!OPERATION_TYPE!': !CALCULATED_DELAY!s"
    set "!DELAY_OUTPUT_VAR!=!CALCULATED_DELAY!"
    exit /b 0

:: ============================================================================
:: CLEANUP
:: ============================================================================

:Cleanup
    call :LogInfo "DisplaySwitcher execution complete with exit code: !EXIT_CODE!"
    exit /b 0
