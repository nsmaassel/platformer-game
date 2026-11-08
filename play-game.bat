@echo off
title Nick's Platformer Game
echo ===================================================
echo  Starting Nick's Platformer...
echo  (Keep this window open while playing)
echo ===================================================

set PROJ_DIR=%~dp0
if "%PROJ_DIR:~-1%"=="\" set PROJ_DIR=%PROJ_DIR:~0,-1%

set GODOT_EXE=%LOCALAPPDATA%\Microsoft\WinGet\Packages\GodotEngine.GodotEngine_Microsoft.Winget.Source_8wekyb3d8bbwe\Godot_v4.6.1-stable_win64_console.exe

if exist "%GODOT_EXE%" (
    "%GODOT_EXE%" --path "%PROJ_DIR%" --main-scene scenes/main_menu.tscn
) else (
    godot --path "%PROJ_DIR%" --main-scene scenes/main_menu.tscn
)

echo.
echo Game finished. Press any key to exit.
pause > nul

