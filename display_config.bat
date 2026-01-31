@echo off
setlocal enableextensions enabledelayedexpansion

rem ======== EDIT THESE THREE (exact Monitor IDs from MMT) ========
rem Example formats:
rem   MONITOR\GSM587E\{4d36e96e-e325-11ce-bfc1-08002be10318}\0003
rem   MONITOR\GSM587E\{4d36e96e-e325-11ce-bfc1-08002be10318}\0001
rem   MONITOR\HWP286A\{4d36e96e-e325-11ce-bfc1-08002be10318}\0002
set "MID_LEFT=MONITOR\GSM587E\{4d36e96e-e325-11ce-bfc1-08002be10318}\0001"
set "MID_CENTER=MONITOR\GSM587E\{4d36e96e-e325-11ce-bfc1-08002be10318}\0003"
set "MID_RIGHT=MONITOR\HWP286A\{4d36e96e-e325-11ce-bfc1-08002be10318}\0002"
rem ===============================================================

set "SCRIPT_DIR=%~dp0"
pushd "%SCRIPT_DIR%"
set "MMT=%SCRIPT_DIR%MultiMonitorTool.exe"
if not exist "%MMT%" (
  echo [%date% %time%] ERROR: MultiMonitorTool.exe not found at "%MMT%"
  goto :end
)

rem Some stacks need elevation for topology changes:
whoami /groups | find "S-1-16-12288" >nul || echo [INFO] Not elevated. If nothing changes, Run as Administrator.

rem ---- Arg parsing ----
set "choice=%~1"
if "%choice%"=="" goto :menu
set "choice=%choice:"=%"
set "choice=%choice: =%"
if /I "%choice%"=="1" set "choice=config1"
if /I "%choice%"=="2" set "choice=config2"
if /I "%choice%"=="3" set "choice=config3"
if /I "%choice%"=="4" set "choice=config4"
if /I "%choice%"=="5" set "choice=config5"
if /I "%choice%"=="config1" goto :config1
if /I "%choice%"=="config2" goto :config2
if /I "%choice%"=="config3" goto :config3
if /I "%choice%"=="config4" goto :config4
if /I "%choice%"=="config5" goto :config5
echo Unknown option: %~1
goto :end

:menu
echo ===========================================
echo   Select Display Configuration (LANDSCAPE)
echo ===========================================
echo 1. All monitors  (Center primary, L and R landscape)
echo 2. Center only   (primary 1680x1050)
echo 3. Left + Center (both landscape)
echo 4. Center + Right (both landscape)
echo 5. Right only    (primary 1920x1200)
set /p choice="Enter choice (1-5): "
if /I "%choice%"=="1" goto :config1
if /I "%choice%"=="2" goto :config2
if /I "%choice%"=="3" goto :config3
if /I "%choice%"=="4" goto :config4
if /I "%choice%"=="5" goto :config5
echo Invalid choice.
goto :end


rem ========== CONFIGS (all landscape) ==========

:config1
echo Applying Config 1 (All monitors, center primary)...
"%MMT%" /enable "%MID_CENTER%" 
timeout /t 1 /nobreak >nul
"%MMT%" /enable "%MID_LEFT%" 
timeout /t 1 /nobreak >nul
"%MMT%" /enable "%MID_RIGHT%"
timeout /t 1 /nobreak >nul

rem Landscape everywhere, top-aligned for simplicity
"%MMT%" /SetMonitors ^
 "Name=%MID_LEFT%   BitsPerPixel=32 Width=1920 Height=1080 DisplayOrientation=0 PositionX=-1920 PositionY=0" ^
 "Name=%MID_CENTER% Primary=1 BitsPerPixel=32 Width=1920 Height=1080 DisplayOrientation=0 PositionX=0 PositionY=0" ^
 "Name=%MID_RIGHT%  BitsPerPixel=32 Width=1920 Height=1200 DisplayOrientation=0 PositionX=1920 PositionY=0"
"%MMT%" /SetPrimary "%MID_CENTER%"
goto :done

:config2
echo Applying Config 2 (Center only @ 1680x1050)...
"%MMT%" /enable "%MID_CENTER%"
timeout /t 1 /nobreak >nul
"%MMT%" /SetMonitors "Name=%MID_CENTER% Primary=1 BitsPerPixel=32 Width=1920 Height=1080 DisplayOrientation=0 PositionX=0 PositionY=0"
"%MMT%" /disable "%MID_LEFT%" "%MID_RIGHT%"
goto :done

:config3
echo Applying Config 3 (Left + Center)...
"%MMT%" /enable "%MID_CENTER%" "%MID_LEFT%"
"%MMT%" /disable "%MID_RIGHT%"
timeout /t 1 /nobreak >nul
"%MMT%" /SetMonitors ^
 "Name=%MID_LEFT%   BitsPerPixel=32 Width=1920 Height=1080 DisplayOrientation=0 PositionX=-1920 PositionY=0" ^
 "Name=%MID_CENTER% Primary=1 BitsPerPixel=32 Width=1920 Height=1080 DisplayOrientation=0 PositionX=0 PositionY=0"
goto :done

:config4
echo Applying Config 4 (Center + Right)...
"%MMT%" /enable "%MID_CENTER%" "%MID_RIGHT%"
"%MMT%" /disable "%MID_LEFT%"
timeout /t 1 /nobreak >nul
"%MMT%" /SetMonitors ^
 "Name=%MID_CENTER% Primary=1 BitsPerPixel=32 Width=1920 Height=1080 DisplayOrientation=0 PositionX=0 PositionY=0" ^
 "Name=%MID_RIGHT%  BitsPerPixel=32 Width=1920 Height=1200 DisplayOrientation=0 PositionX=1920 PositionY=0"
goto :done

:config5
echo Applying Config 5 (Right only, primary)...
"%MMT%" /disable "%MID_LEFT%" "%MID_CENTER%"
timeout /t 1 /nobreak >nul
"%MMT%" /SetMonitors "Name=%MID_RIGHT% Primary=1 BitsPerPixel=32 Width=1920 Height=1200 DisplayOrientation=0 PositionX=0 PositionY=0"
goto :done

:done
>>"%SCRIPT_DIR%display_config.log" echo [%date% %time%] Applied %choice%
goto :end

:end
popd
endlocal
