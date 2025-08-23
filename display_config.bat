@echo off
setlocal
set MMT=MultiMonitorTool.exe

REM =====================================================
REM  If no args -> show menu
REM My 1 is detected as \\.\DISPLAY2
REM My 2 is detected as \\.\DISPLAY3
REM My 3 is detected as \\.\DISPLAY1
REM =====================================================

if "%~1"=="" (
    echo ==============================
    echo   Select Display Configuration
    echo ==============================
    echo 1. Config 1 - All monitors (3=primary 1920x1080, 1=1920x1080, 2=portrait 1200x1920)
    echo 2. Config 2 - Only Monitor 3 at 1680x1050
    echo 3. Config 3 - Monitor 1 + 3 (both 1920x1080)
    echo 4. Config 4 - Only Monitor 3 at 1920x1080
    set /p choice="Enter choice (1-4): "
    if "%choice%"=="1" goto config1
    if "%choice%"=="2" goto config2
    if "%choice%"=="3" goto config3
    if "%choice%"=="4" goto config4
    goto end
)

if /I "%~1"=="config1" goto config1
if /I "%~1"=="config2" goto config2
if /I "%~1"=="config3" goto config3
if /I "%~1"=="config4" goto config4

echo Unknown option: %~1
goto end

REM =====================================================
REM  CONFIGURATIONS
REM =====================================================

:config1
echo Applying Config 1 (All monitors)...
REM First explicitly enable all monitors so they always come back
%MMT% /enable "\\.\DISPLAY1" "\\.\DISPLAY2" "\\.\DISPLAY3"
REM Apply layout and resolutions (all landscape by default)
%MMT% /SetMonitors "Name=\\.\DISPLAY1 Primary=1 BitsPerPixel=32 Width=1920 Height=1080 DisplayFlags=0 DisplayFrequency=60 DisplayOrientation=0 PositionX=0 PositionY=0" "Name=\\.\DISPLAY2 BitsPerPixel=32 Width=1920 Height=1080 DisplayFlags=0 DisplayFrequency=60 DisplayOrientation=0 PositionX=-1920 PositionY=0" "Name=\\.\DISPLAY3 BitsPerPixel=32 Width=1200 Height=1920 DisplayFlags=0 DisplayFrequency=60 DisplayOrientation=0 PositionX=1920 PositionY=0"
REM Explicitly rotate Display3 (your Monitor 2) to portrait
%MMT% /SetOrientation "\\.\DISPLAY3" 90
goto end




:config2
echo Applying Config 2 (Only Monitor 3 at 1680x1050)...
REM Disable the other two first
%MMT% /disable "\\.\DISPLAY2" "\\.\DISPLAY3"
REM Apply resolution for primary
%MMT% /SetMonitors "Name=\\.\DISPLAY1 Primary=1 BitsPerPixel=32 Width=1680 Height=1050 DisplayFlags=0 DisplayFrequency=60 DisplayOrientation=0 PositionX=0 PositionY=0"
goto end

:config3
echo Applying Config 3 (Only Monitor 1 + 3)...
REM Disable monitor 2
%MMT% /disable "\\.\DISPLAY3"
REM Apply layout for Display1 (primary) + Display2
%MMT% /SetMonitors "Name=\\.\DISPLAY1 Primary=1 BitsPerPixel=32 Width=1920 Height=1080 DisplayFlags=0 DisplayFrequency=60 DisplayOrientation=0 PositionX=0 PositionY=0" "Name=\\.\DISPLAY2 BitsPerPixel=32 Width=1920 Height=1080 DisplayFlags=0 DisplayFrequency=60 DisplayOrientation=0 PositionX=-1920 PositionY=0"
goto end

:config4
echo Applying Config 4 (Only Monitor 3 at 1920x1080)...
REM Disable the other two first
%MMT% /disable "\\.\DISPLAY2" "\\.\DISPLAY3"
REM Apply resolution for primary monitor (Display1 = your Monitor 3)
%MMT% /SetMonitors "Name=\\.\DISPLAY1 Primary=1 BitsPerPixel=32 Width=1920 Height=1080 DisplayFlags=0 DisplayFrequency=60 DisplayOrientation=0 PositionX=0 PositionY=0"
goto end

:end
endlocal
pause
