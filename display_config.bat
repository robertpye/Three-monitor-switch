@echo off
setlocal enableextensions enabledelayedexpansion

rem === Resolve script dir so MMT works no matter where called from ===
set "SCRIPT_DIR=%~dp0"
pushd "%SCRIPT_DIR%"

REM ===================================================== 
REM If no args -> show menu 
REM My 1 is detected as \\.\DISPLAY2 
REM My 2 is detected as \\.\DISPLAY3 
REM My 3 is detected as \\.\DISPLAY1 
REM =====================================================

rem === ABS path to MultiMonitorTool (edit if it lives elsewhere) ===
set "MMT=%SCRIPT_DIR%MultiMonitorTool.exe"

if not exist "%MMT%" (
  echo [%date% %time%] ERROR: MultiMonitorTool.exe not found at "%MMT%"
  goto :end
)

rem =====================================================
rem  Arg parsing
rem  Supports: display_config.bat 1|2|3|4  OR  config1|config2|config3|config4
rem =====================================================
set "choice=%~1"
if "%choice%"=="" goto :menu
set "choice=%choice:"=%"    rem strip any quotes
set "choice=%choice: =%"    rem trim spaces

rem map numeric to labels
if /I "%choice%"=="1" set "choice=config1"
if /I "%choice%"=="2" set "choice=config2"
if /I "%choice%"=="3" set "choice=config3"
if /I "%choice%"=="4" set "choice=config4"

if /I "%choice%"=="config1" goto :config1
if /I "%choice%"=="config2" goto :config2
if /I "%choice%"=="config3" goto :config3
if /I "%choice%"=="config4" goto :config4

echo Unknown option: %~1
goto :end

:menu
echo ==============================
echo   Select Display Configuration
echo ==============================
echo 1. Config 1 - All monitors (3=primary 1920x1080, 1=1920x1080, 2=portrait 1200x1920)
echo 2. Config 2 - Only Monitor 3 at 1680x1050
echo 3. Config 3 - Monitor 1 + 3 (both 1920x1080)
echo 4. Config 4 - Only Monitor 3 at 1920x1080
set /p choice="Enter choice (1-4): "
if "%choice%"=="1" goto :config1
if "%choice%"=="2" goto :config2
if "%choice%"=="3" goto :config3
if "%choice%"=="4" goto :config4
echo Invalid choice.
goto :end


rem =====================================================
rem  CONFIGURATIONS    (uses your mapping notes)
rem  My 1 -> \\.\DISPLAY2
rem  My 2 -> \\.\DISPLAY3
rem  My 3 -> \\.\DISPLAY1
rem =====================================================

:config1
echo Applying Config 1 (All monitors)...
"%MMT%" /enable "\\.\DISPLAY1" "\\.\DISPLAY2" "\\.\DISPLAY3"
"%MMT%" /SetMonitors ^
 "Name=\\.\DISPLAY1 Primary=1 BitsPerPixel=32 Width=1920 Height=1080 DisplayFlags=0 DisplayFrequency=60 DisplayOrientation=0 PositionX=0 PositionY=0" ^
 "Name=\\.\DISPLAY2 BitsPerPixel=32 Width=1920 Height=1080 DisplayFlags=0 DisplayFrequency=60 DisplayOrientation=0 PositionX=-1920 PositionY=0" ^
 "Name=\\.\DISPLAY3 BitsPerPixel=32 Width=1200 Height=1920 DisplayFlags=0 DisplayFrequency=60 DisplayOrientation=0 PositionX=1920 PositionY=0"
"%MMT%" /SetOrientation "\\.\DISPLAY3" 90
goto :done

:config2
echo Applying Config 2 (Only Monitor 3 at 1680x1050)...
rem Monitor 3 == \\.\DISPLAY1 in your mapping
"%MMT%" /disable "\\.\DISPLAY2" "\\.\DISPLAY3"
"%MMT%" /SetMonitors ^
 "Name=\\.\DISPLAY1 Primary=1 BitsPerPixel=32 Width=1680 Height=1050 DisplayFlags=0 DisplayFrequency=60 DisplayOrientation=0 PositionX=0 PositionY=0"
goto :done

:config3
echo Applying Config 3 (Monitor 1 + 3)...
rem Disable middle (your monitor 2 == \\.\DISPLAY3)
"%MMT%" /disable "\\.\DISPLAY3"
"%MMT%" /SetMonitors ^
 "Name=\\.\DISPLAY1 Primary=1 BitsPerPixel=32 Width=1920 Height=1080 DisplayFlags=0 DisplayFrequency=60 DisplayOrientation=0 PositionX=0 PositionY=0" ^
 "Name=\\.\DISPLAY2 BitsPerPixel=32 Width=1920 Height=1080 DisplayFlags=0 DisplayFrequency=60 DisplayOrientation=0 PositionX=-1920 PositionY=0"
goto :done

:config4
echo Applying Config 4 (Only Monitor 3 at 1920x1080)...
"%MMT%" /disable "\\.\DISPLAY2" "\\.\DISPLAY3"
"%MMT%" /SetMonitors ^
 "Name=\\.\DISPLAY1 Primary=1 BitsPerPixel=32 Width=1920 Height=1080 DisplayFlags=0 DisplayFrequency=60 DisplayOrientation=0 PositionX=0 PositionY=0"
goto :done

:done
echo [%date% %time%] Applied %choice% >> "%SCRIPT_DIR%display_config.log"

:end
popd
endlocal
