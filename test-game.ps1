<#
.SYNOPSIS
    Runs the Godot game with logging and error filtering.
.DESCRIPTION
    Launches the game, captures stdout+stderr to log files, and on exit,
    prints a filtered summary of warnings, errors, and script issues.
.PARAMETER Scene
    Optional scene to run directly (e.g. "scenes/level_1.tscn").
    Defaults to the main scene from project.godot.
.PARAMETER Headless
    Run headless (no window) - useful for import/validation checks.
.PARAMETER Verbose
    Pass --verbose to Godot for extra debug output.
.PARAMETER Validate
    Run the headless level validation suite (scripts/validate_levels.gd).
    Checks every level_*.tscn for required nodes, valid tile data, and
    entity placement. Returns exit code 0 on pass, 1 on failure.
.EXAMPLE
    .\test-game.ps1                     # Run game normally
    .\test-game.ps1 -Scene scenes/level_2.tscn   # Jump to level 2
    .\test-game.ps1 -Headless           # Headless validation
    .\test-game.ps1 -Verbose            # Verbose logging
    .\test-game.ps1 -Validate           # Run level validation suite
#>
param(
    [string]$Scene,
    [switch]$Headless,
    [switch]$Verbose,
    [switch]$Validate,
    [switch]$Preview,
    [switch]$Replay,
    [switch]$Test,
    [switch]$Pixel
)



$ErrorActionPreference = "Stop"

# --- Find Godot ---
$godotConsole = Get-ChildItem "$env:LOCALAPPDATA\Microsoft\WinGet\Packages\GodotEngine*" `
    -Filter "*console.exe" -Recurse -ErrorAction SilentlyContinue |
    Sort-Object LastWriteTime -Descending |
    Select-Object -First 1 -ExpandProperty FullName

$godotGui = Get-ChildItem "$env:LOCALAPPDATA\Microsoft\WinGet\Packages\GodotEngine*" `
    -Filter "*win64.exe" -Recurse -ErrorAction SilentlyContinue |
    Where-Object { $_.Name -notmatch "console" } |
    Sort-Object LastWriteTime -Descending |
    Select-Object -First 1 -ExpandProperty FullName

if (-not $godotConsole) {
    $godotConsole = (Get-Command godot -ErrorAction SilentlyContinue).Source
}
if (-not $godotGui) {
    $godotGui = $godotConsole
}
if (-not $godotConsole) {
    Write-Host "ERROR: Godot console executable not found." -ForegroundColor Red
    Write-Host "Install via: winget install GodotEngine.GodotEngine"
    exit 1
}


Write-Host "Using Godot: $godotConsole" -ForegroundColor DarkGray

# --- Prepare log files ---
$timestamp = Get-Date -Format "yyyyMMdd_HHmmss"
$logDir = Join-Path $PSScriptRoot "logs"
if (-not (Test-Path $logDir)) { New-Item -ItemType Directory -Path $logDir | Out-Null }

$stdoutLog = Join-Path $logDir "godot_stdout_$timestamp.log"
$stderrLog = Join-Path $logDir "godot_stderr_$timestamp.log"

# --- Validate mode: run level validation suite and exit ---
if ($Validate) {
    Write-Host ""
    Write-Host "=== Running Level Validation ===" -ForegroundColor Cyan
    Write-Host ""

    $validateOut = Join-Path $logDir "validate_stdout_$timestamp.log"
    $validateErr = Join-Path $logDir "validate_stderr_$timestamp.log"

    $vArgs = @("--headless", "--path", $PSScriptRoot, "--script", "tools/godot_scripts/validate_levels.gd")
    $vProc = Start-Process -FilePath $godotConsole `
        -ArgumentList $vArgs `
        -NoNewWindow -Wait -PassThru `
        -RedirectStandardOutput $validateOut `
        -RedirectStandardError $validateErr

    # Display validation output
    Get-Content $validateOut -ErrorAction SilentlyContinue

    # Show any engine errors from stderr (filter expected autoload noise)
    $vErrors = Get-Content $validateErr -ErrorAction SilentlyContinue |
        Where-Object { $_ -match "ERROR" -and $_ -notmatch "Identifier not found: GameState" -and $_ -notmatch "Compilation failed" }
    if ($vErrors) {
        Write-Host ""
        Write-Host "ENGINE ERRORS:" -ForegroundColor Red
        $vErrors | ForEach-Object { Write-Host "  $_" -ForegroundColor Red }
    }

    exit $vProc.ExitCode
}

# --- Preview mode: capture visual screenshots of all levels and exit ---
if ($Preview) {
    Write-Host ""
    Write-Host "=== Capturing Level & Tactical Previews ===" -ForegroundColor Cyan
    Write-Host ""

    python tools/python_scripts/render-level-previews.py
    exit $LASTEXITCODE
}

# --- Replay mode: run automated input replay playability test suite and exit ---
if ($Replay) {
    Write-Host ""
    Write-Host "=== Running Automated Autonomous Playtest Suite ===" -ForegroundColor Cyan
    Write-Host ""

    # 1. Platformer input replay verification
    Write-Host "--- 1. Platformer Level Playthrough Replay ---" -ForegroundColor Yellow
    $rOut = Join-Path $logDir "replay_stdout_$timestamp.log"
    $rErr = Join-Path $logDir "replay_stderr_$timestamp.log"
    $rArgs = @("--headless", "--path", $PSScriptRoot, "--script", "tools/godot_scripts/test_input_replay.gd")
    $rProc = Start-Process -FilePath $godotConsole -ArgumentList $rArgs -NoNewWindow -Wait -PassThru -RedirectStandardOutput $rOut -RedirectStandardError $rErr
    Get-Content $rOut -ErrorAction SilentlyContinue
    if ($rProc.ExitCode -ne 0) { exit $rProc.ExitCode }

    # 2. Tactics Grid autonomous bot playtest
    Write-Host ""
    Write-Host "--- 2. Tactical Grid Autonomous Bot Playtest ---" -ForegroundColor Yellow
    $tOut = Join-Path $logDir "tactics_bot_stdout_$timestamp.log"
    $tErr = Join-Path $logDir "tactics_bot_stderr_$timestamp.log"
    $tArgs = @("--headless", "--path", $PSScriptRoot, "--script", "games/tactics/scripts/bot_playtest_tactics.gd")
    $tProc = Start-Process -FilePath $godotConsole -ArgumentList $tArgs -NoNewWindow -Wait -PassThru -RedirectStandardOutput $tOut -RedirectStandardError $tErr
    Get-Content $tOut -ErrorAction SilentlyContinue
    if ($tProc.ExitCode -ne 0) { exit $tProc.ExitCode }

    # 3. Boss Arena autonomous combat bot playtest
    Write-Host ""
    Write-Host "--- 3. Boss Arena Autonomous Combat Bot Playtest ---" -ForegroundColor Yellow
    $bOut = Join-Path $logDir "boss_bot_stdout_$timestamp.log"
    $bErr = Join-Path $logDir "boss_bot_stderr_$timestamp.log"
    $bArgs = @("--headless", "--path", $PSScriptRoot, "--script", "games/tactics/scripts/bot_playtest_boss.gd")
    $bProc = Start-Process -FilePath $godotConsole -ArgumentList $bArgs -NoNewWindow -Wait -PassThru -RedirectStandardOutput $bOut -RedirectStandardError $bErr
    Get-Content $bOut -ErrorAction SilentlyContinue
    exit $bProc.ExitCode
}

# --- Pixel mode: run automated pixel art crispness & polish audit ---
if ($Pixel) {
    python tools/python_scripts/validate_pixel_crispness.py
    exit $LASTEXITCODE
}


# --- Test mode: run GDScript unit test runner ---
if ($Test) {
    Write-Host ""
    Write-Host "=== Running GDScript Unit Test Suite ===" -ForegroundColor Cyan
    Write-Host ""

    $tOut = Join-Path $logDir "test_stdout_$timestamp.log"
    $tErr = Join-Path $logDir "test_stderr_$timestamp.log"

    $tArgs = @("--headless", "--path", $PSScriptRoot, "--script", "games/tactics/tests/run_all_tests.gd")
    $tProc = Start-Process -FilePath $godotConsole `
        -ArgumentList $tArgs `
        -NoNewWindow -Wait -PassThru `
        -RedirectStandardOutput $tOut `
        -RedirectStandardError $tErr

    Get-Content $tOut -ErrorAction SilentlyContinue
    exit $tProc.ExitCode
}



# --- Build arguments ---
$args = @("--path", $PSScriptRoot)

if ($Headless) { $args += "--headless" }
if ($Verbose) { $args += "--verbose" }

if ($Scene) {
    $args += "--main-scene"
    $args += "res://$Scene"
}

Write-Host ""
Write-Host "=== Starting Godot ===" -ForegroundColor Cyan
Write-Host "Args: $($args -join ' ')" -ForegroundColor DarkGray
Write-Host "Logs: $logDir" -ForegroundColor DarkGray
Write-Host "Press Ctrl+C or close the game window to stop." -ForegroundColor DarkGray
Write-Host ""

# --- Run Godot ---
$godotExe = if ($Headless) { $godotConsole } else { $godotGui }
if ($Headless) {
    $process = Start-Process -FilePath $godotExe `
        -ArgumentList $args `
        -NoNewWindow -Wait -PassThru `
        -RedirectStandardOutput $stdoutLog `
        -RedirectStandardError $stderrLog
    $exitCode = $process.ExitCode
} else {
    $process = Start-Process -FilePath $godotExe `
        -ArgumentList $args `
        -PassThru
    $exitCode = 0
}


# --- Analyze logs ---
Write-Host ""
Write-Host "=== Game Exited (code: $exitCode) ===" -ForegroundColor Cyan
Write-Host ""

$stderrContent = Get-Content $stderrLog -ErrorAction SilentlyContinue
$stdoutContent = Get-Content $stdoutLog -ErrorAction SilentlyContinue

# Filter for important messages
$warnings = @()
$errors = @()
$scriptErrors = @()

foreach ($line in $stderrContent) {
    if ($line -match "^WARNING:") { $warnings += $line }
    elseif ($line -match "^ERROR:|SCRIPT ERROR|^   at:") { $errors += $line }
}

foreach ($line in $stdoutContent) {
    if ($line -match "SCRIPT ERROR|GDScript|error|Error" -and $line -notmatch "SilentlyContinue|ErrorAction") {
        $scriptErrors += $line
    }
}

# Print summary
if ($errors.Count -gt 0) {
    Write-Host "ERRORS ($($errors.Count)):" -ForegroundColor Red
    $errors | ForEach-Object { Write-Host "  $_" -ForegroundColor Red }
    Write-Host ""
}

if ($scriptErrors.Count -gt 0) {
    Write-Host "SCRIPT ISSUES ($($scriptErrors.Count)):" -ForegroundColor Yellow
    $scriptErrors | ForEach-Object { Write-Host "  $_" -ForegroundColor Yellow }
    Write-Host ""
}

if ($warnings.Count -gt 0) {
    Write-Host "WARNINGS ($($warnings.Count)):" -ForegroundColor DarkYellow
    $warnings | ForEach-Object { Write-Host "  $_" -ForegroundColor DarkYellow }
    Write-Host ""
}

if ($errors.Count -eq 0 -and $scriptErrors.Count -eq 0 -and $warnings.Count -eq 0) {
    Write-Host "No errors or warnings detected!" -ForegroundColor Green
}

Write-Host "Full logs: $stdoutLog" -ForegroundColor DarkGray
Write-Host "           $stderrLog" -ForegroundColor DarkGray
