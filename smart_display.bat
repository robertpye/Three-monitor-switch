@echo off
setlocal enableextensions enabledelayedexpansion

set "MMT=%~dp0MultiMonitorTool.exe"
if not exist "%MMT%" (
  echo [%date% %time%] ERROR: MultiMonitorTool.exe not found at "%MMT%"
  exit /b 1
)

set "MAP=%TEMP%\mmt_now_%RANDOM%.csv"

rem === Dump current display state to CSV ===
"%MMT%" /scomma "%MAP%" >nul 2>&1
if errorlevel 1 (
  echo [%date% %time%] ERROR: Failed to query displays.
  del /q "%MAP%" >nul 2>&1
  exit /b 2
)

rem === DEBUG: Show CSV contents ===
echo --- CSV DUMP ---
type "%MAP%"
echo --- END CSV DUMP ---

set "PSOUT=%TEMP%\smart_display_json_%RANDOM%.txt"

powershell -NoProfile -ExecutionPolicy Bypass -Command ^
  "$csv=Import-Csv -Delimiter ',' '%MAP%';" ^
  "$rows = $csv | Where-Object { $_.'Monitor ID' };" ^
  "$act  = $rows | Where-Object { $_.Active -ne 'No' };" ^
  "$prim = $act  | Where-Object { $_.Primary -match 'Yes' } | Select-Object -First 1;" ^
  "if(-not $prim){ $prim = $act | Select-Object -First 1 }" ^
  "$left  = $act | Sort-Object {[int]($_.'Left-Top' -replace ' ','' -split ',')[0]} | Select-Object -First 1;" ^
  "$right = $act | Sort-Object {[int]($_.'Left-Top' -replace ' ','' -split ',')[0]} -Descending | Select-Object -First 1;" ^
  "$out = [ordered]@{};" ^
  "foreach($r in $act){" ^
  "  $id = $r.'Monitor ID';" ^
  "  $res = $r.Resolution -replace ' ','' -split 'X'; $w=[int]$res[0]; $h=[int]$res[1];" ^
  "  $pos = $r.'Left-Top' -replace ' ','' -split ','; $x=[int]$pos[0]; $y=[int]$pos[1];" ^
  "  $out[$id] = [ordered]@{ Device=$r.Name; Primary=$r.Primary; Width=$w; Height=$h; X=$x; Y=$y; Hz=[int]$r.Frequency }" ^
  "}" ^
  "$summary = [ordered]@{ CENTER=$prim.'Monitor ID'; LEFT=$left.'Monitor ID'; RIGHT=$right.'Monitor ID'; DISPLAYS=$out }" ^
  "($summary | ConvertTo-Json -Depth 5) -replace '\\\\','\\\\\\'" ^
  > "%PSOUT%"

set "JSON="
for /f "usebackq delims=" %%A in ("%PSOUT%") do set "JSON=%%A"

del /q "%MAP%" "%PSOUT%" >nul 2>&1

if not defined JSON (
  echo [%date% %time%] ERROR: Could not parse display data.
  exit /b 3
)

rem --- Tiny JSON getter (PowerShell) so we can fetch fields when needed ---
set "JQ=powershell -NoProfile -ExecutionPolicy Bypass -Command"
set "JEXP=$j=%JSON%; $key='%~1'; $prop='%~2'; $val=$j.DISPLAYS[$key].$prop; if($val -is [string]){$val} else {$val.ToString()}"

rem Helper to echo a line in a nice table format (via PowerShell)
set "PRINT=%JQ% \"$j=%JSON%;$c=$j.CENTER;$ids=$j.DISPLAYS.Keys;foreach($id in $ids){$d=$j.DISPLAYS[$id];$p=($id -eq $c)?'Yes':'No';'{0,-3} {1,-5} {2,-6} {3,-18} {4,-9} {5,-10} {6,-9}' -f ([string]$p),$d.Hz+'Hz',$d.Width+'x'+$d.Height,$d.Device,$d.X+','+$d.Y,($id -split '\\\\')[-1],$id }\""

rem === Commands ===
if /I "%~1"=="info" (
  echo Primary Hz   Res     Device             Position   InstID   MonitorID
  echo ------- ----- ------- ------------------ ---------- -------- -----------------------------------------------
  %PRINT%
  exit /b 0
)

if /I "%~1"=="left" (
  if /I "%~2"=="on"  goto :LEFT_ON
  if /I "%~2"=="off" goto :LEFT_OFF
  echo Usage: %~nx0 left on ^| left off
  exit /b 0
)

if /I "%~1"=="row3" goto :ROW3

echo Usage:
echo   %~nx0 info
echo   %~nx0 left on
echo   %~nx0 left off
echo   %~nx0 row3          ^(L,C,R in one row — keeps each current resolution^)
exit /b 0


:LEFT_ON
for /f %%R in ('%JQ% "$j=%JSON%; $j.LEFT"') do set "LEFT_ID=%%R"
for /f %%R in ('%JQ% "$j=%JSON%; $j.CENTER"') do set "CENTER_ID=%%R"
for /f %%R in ('%JQ% "$j=%JSON%; $j.DISPLAYS[$j.LEFT].Width"') do set "LW=%%R"

echo Enabling LEFT and keeping CENTER primary...
"%MMT%" /enable     "%CENTER_ID%"
"%MMT%" /SetPrimary "%CENTER_ID%"
set "X=-1920"
if defined LW set "X=-%LW%"
"%MMT%" /EnableAtPosition "%LEFT_ID%" %X% 0
exit /b 0


:LEFT_OFF
for /f %%R in ('%JQ% "$j=%JSON%; $j.LEFT"') do set "LEFT_ID=%%R"
for /f %%R in ('%JQ% "$j=%JSON%; $j.CENTER"') do set "CENTER_ID=%%R"
echo Disabling LEFT and keeping CENTER primary...
"%MMT%" /enable     "%CENTER_ID%"
"%MMT%" /SetPrimary "%CENTER_ID%"
"%MMT%" /disable    "%LEFT_ID%"
exit /b 0


:ROW3
for /f %%R in ('%JQ% "$j=%JSON%; $j.CENTER"') do set "CENTER_ID=%%R"
for /f %%R in ('%JQ% "$j=%JSON%; $j.LEFT"') do set "LEFT_ID=%%R"
for /f %%R in ('%JQ% "$j=%JSON%; $j.RIGHT"') do set "RIGHT_ID=%%R"
for /f %%R in ('%JQ% "$j=%JSON%; $j.DISPLAYS[$j.LEFT].Width"') do set "LW=%%R"
for /f %%R in ('%JQ% "$j=%JSON%; $j.DISPLAYS[$j.CENTER].Width"') do set "CW=%%R"

set /a RX=%LW%+%CW%
echo Forcing simple 3-wide row using current resolutions...
"%MMT%" /enable "%CENTER_ID%" "%LEFT_ID%" "%RIGHT_ID%"
"%MMT%" /SetPrimary "%CENTER_ID%"
rem Keep ALL LANDSCAPE (no orientation changes), just place them by current widths
"%MMT%" /EnableAtPosition "%LEFT_ID%"   -%LW% 0
"%MMT%" /EnableAtPosition "%CENTER_ID%" 0     0
"%MMT%" /EnableAtPosition "%RIGHT_ID%"  %RX%  0
exit /b 0