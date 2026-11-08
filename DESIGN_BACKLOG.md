# Nick's Platformer — Design Backlog

This is the agentic design tracking doc. When working with Claude/Copilot, share this file to get
prioritized next-steps. Update it after each work session.

## Current State

- [x] Project scaffolded (Godot 4.3+)
- [x] Core game systems: player, game state, goal trigger
- [x] Level 1 (TileMap terrain, background decorations)
- [x] Level 2 (TileMap terrain, enemies, coins, checkpoint)
- [x] Level 3 (Moving platforms, spike hazards, terrain gaps)
- [x] Main menu (with High Score display)
- [x] Procedural sprite generator (`generate-sprites.py` — Python + Pillow, 53 PNGs)
- [x] Procedural sound synthesizer (`generate-sfx.py` — Python wave synthesis, 6 WAVs)
- [x] Player sprites wired (idle/run/jump/fall/hurt)
- [x] Slime sprites wired (walk/squish)
- [x] Coin sprites wired (idle/collect)
- [x] Goal sprites wired (idle)
- [x] Checkpoint sprites wired (idle/active)
- [x] Moving platform & Spike hazard scenes wired
- [x] Tile atlas + TileSet with physics collision
- [x] All levels converted to TileMapLayer terrain
- [x] Background decorations (sky, clouds, bushes)
- [x] Enemy type 1 (Slime — patrol + stomp)
- [x] HUD (lives, level, score display)
- [x] Checkpoint system & respawning
- [x] Sound effects system (jump, coin, stomp, checkpoint, hurt, win)
- [x] Save/load progress & High Score persistence (`user://savegame.cfg`)
- [x] Copilot instructions + VSCode workspace config
- [x] Level validation suite (`scripts/validate_levels.gd` + `test-game.ps1 -Validate`)
- [x] Input replay playability test suite (`scripts/test_input_replay.gd` + `test-game.ps1 -Replay`)
- [x] Web export + deployment pipeline configured (`staticwebapp.config.json` + `export_presets.cfg`)
- [x] iOS export preset configured (`export_presets.cfg`)
- [x] Monorepo restructuring (`games/platformer/`, `games/tactics/`, `games/toyboxes/`, `shared/`)

## Scenes Inventory

| Scene | Path | Status |
|---|---|---|
| Main Menu | scenes/main_menu.tscn | ✅ Done (High Score display) |
| Level 1 | scenes/level_1.tscn | ✅ Done (TileMap + sprites + HUD) |
| Level 2 | scenes/level_2.tscn | ✅ Done (TileMap + sprites + enemies + checkpoint) |
| Level 3 | scenes/level_3.tscn | ✅ Done (TileMap + moving platforms + spikes) |
| Player | scenes/player.tscn | ✅ Done (17 sprite frames + SFX wired) |
| Slime | scenes/slime.tscn | ✅ Done (6 sprite frames + SFX wired) |
| Coin | scenes/coin.tscn | ✅ Done (10 sprite frames + SFX wired) |
| Goal | scenes/goal.tscn | ✅ Done (2 sprite frames + win SFX + save wired) |
| Checkpoint | scenes/checkpoint.tscn | ✅ Done (6 sprite frames + sfx wired) |
| Moving Platform | scenes/moving_platform.tscn | ✅ Done (32×16 platform + oscillation logic) |
| Spike | scenes/spike.tscn | ✅ Done (16×16 hazard + damage trigger) |

## Art & Sound Pipeline

- Sprites: `python generate-sprites.py` (53 PNGs + tile atlas + `sprites-review.png` contact sheet).
- SFX: `python generate-sfx.py` (6 chiptune WAVs: jump, coin, stomp, checkpoint, hurt, win).

### Sprite Inventory (53 PNGs)

| Entity | Dir | Files | Size |
|--------|-----|-------|------|
| Player | assets/sprites/player/ | 17 PNGs (idle×4, run×6, jump×2, fall×2, hurt×3) | 16×32px |
| Slime | assets/sprites/slime/ | 6 PNGs (walk×4, squish×2) | 16×16px |
| Coin | assets/sprites/coin/ | 10 PNGs (idle×6, collect×4) | 16×16px |
| Goal | assets/sprites/goal/ | 2 PNGs (idle×2) | 16×32px |
| Checkpoint | assets/sprites/checkpoint/ | 6 PNGs (idle×2, active×4) | 16×32px |
| Spike | assets/sprites/spike/ | 1 PNG (idle) | 16×16px |
| Platform | assets/sprites/platform/ | 1 PNG (idle) | 32×16px |
| Tiles | assets/sprites/tiles/ | 7 PNGs + atlas.png | 16×16px |
| BG | assets/sprites/bg/ | 3 PNGs (cloud_left, cloud_right, bush) | 16×16px |

## Testing & Verification Suite

| Tier | Purpose | Execution | Status |
|------|---------|-----------|--------|
| 1. Scene Validation | Headless node, tile, fall threshold & overlap check | `.\test-game.ps1 -Validate` | ✅ Done (32/32 pass) |
| 2. Visual Previews | Sprite sheet review & headless level PNG screenshot capture | `python generate-sprites.py`<br>`.\test-game.ps1 -Preview` | ✅ Done |
| 3. Engine Smoke Test | Headless asset import & GDScript compilation check | `.\test-game.ps1 -Headless` | ✅ Done |
| 4. Input Replay | Golden path playthrough recording & automated replay | `.\test-game.ps1 -Replay` | ✅ Done |

