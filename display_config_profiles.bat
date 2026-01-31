@echo off
setlocal enableextensions enabledelayedexpansion

rem ===== Paths =====
set "SCRIPT_DIR=%~dp0"
pushd "%SCRIPT_DIR%"
set "MMT=%SCRIPT_DIR%MultiMonitorTool.exe"
if not exist "%MMT%" (
  echo [%date% %time%] ERROR: MultiMonitorTool.exe not found at "%MMT%"
  goto :end
)

rem ===== Configs (saved after setting CopySetMonitorsMode=2 in the GUI) =====
set "CFG1=%SCRIPT_DIR%config1.cfg"
set "CFG2=%SCRIPT_DIR%config2.cfg"
set "CFG3=%SCRIPT_DIR%config3.cfg"
set "CFG4=%SCRIPT_DIR%config4.cfg"

set "LOGFILE=%SCRIPT_DIR%display_config.log"
set "APPLIED_LABEL="

rem Optional: hint about elevation (some GPU drivers require admin)
whoami /groups | find "S-1-16-12288" >nul || echo [INFO] Not elevated. If nothing changes, try Run as Administrator.

goto :main

:loadcfg
rem %1 = cfg path, %2 = label
if not exist "%~1" (
  echo [%date% %time%] ERROR: Missing config: "%~1"
  >>"%LOGFILE%" echo [%date% %time%] ERROR: Missing config "%~1"
  goto :end
)

echo Applying %~2 ...
rem Directly load the saved layout; uses Monitor IDs thanks to CopySetMonitorsMode=2
"%MMT%" /LoadConfig "%~1"
if errorlevel 1 (
  echo [%date% %time%] ERROR: Failed loading "%~1"
  >>"%LOGFILE%" echo [%date% %time%] ERROR: Failed loading "%~1"
  goto :end
)
set "APPLIED_LABEL=%~2"
goto :eof

:main
rem ===== Arg parsing =====
set "choice=%~1"
if "%choice%"=="" goto :menu

set "choice=%choice:"=%"
set "choice=%choice: =%"

if /I "%choice%"=="1"       call :loadcfg "%CFG1%" "Config 1" & goto :done
if /I "%choice%"=="2"       call :loadcfg "%CFG2%" "Config 2" & goto :done
if /I "%choice%"=="3"       call :loadcfg "%CFG3%" "Config 3" & goto :done
if /I "%choice%"=="4"       call :loadcfg "%CFG4%" "Config 4" & goto :done
if /I "%choice%"=="config1" call :loadcfg "%CFG1%" "Config 1" & goto :done
if /I "%choice%"=="config2" call :loadcfg "%CFG2%" "Config 2" & goto :done
if /I "%choice%"=="config3" call :loadcfg "%CFG3%" "Config 3" & goto :done
if /I "%choice%"=="config4" call :loadcfg "%CFG4%" "Config 4" & goto :done

echo Unknown option: %~1
goto :end

:menu
echo =====================================================
echo  DISPLAY LAYOUTS  (saved with Monitor ID names)
echo    1. Config 1 - All monitors (L portrait, C primary landscape, R landscape)
echo    2. Config 2 - Only Center (primary) at 1680x1050
echo    3. Config 3 - Left + Center (portrait + landscape)
echo    4. Config 4 - Center + Right (both landscape)
echo =====================================================
set /p choice="Enter choice (1-4): "

if /I "%choice%"=="1" goto :c1
if /I "%choice%"=="2" goto :c2
if /I "%choice%"=="3" goto :c3
if /I "%choice%"=="4" goto :c4
echo Invalid choice.
goto :end

:c1
call :loadcfg "%CFG1%" "Config 1"
goto :done
:c2
call :loadcfg "%CFG2%" "Config 2"
goto :done
:c3
call :loadcfg "%CFG3%" "Config 3"
goto :done
:c4
call :loadcfg "%CFG4%" "Config 4"
goto :done

:done
if defined APPLIED_LABEL (
  >>"%LOGFILE%" echo [%date% %time%] Applied %APPLIED_LABEL%
)
goto :end

:end
popd
endlocal
