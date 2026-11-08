@echo off
title Opening Godot Editor...
echo Opening Nick's Platformer in Godot Editor...

set PROJ_DIR=%~dp0
if "%PROJ_DIR:~-1%"=="\" set PROJ_DIR=%PROJ_DIR:~0,-1%

set GODOT_EXE=%LOCALAPPDATA%\Microsoft\WinGet\Packages\GodotEngine.GodotEngine_Microsoft.Winget.Source_8wekyb3d8bbwe\Godot_v4.6.1-stable_win64.exe

if exist "%GODOT_EXE%" (
    start "" "%GODOT_EXE%" -e --path "%PROJ_DIR%"
) else (
    godot -e --path "%PROJ_DIR%"
)

