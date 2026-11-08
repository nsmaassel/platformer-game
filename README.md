# Nick's Platformer

A pixel-art 2D platformer built with Godot 4. Deploys to [game.maassel.dev](https://game.maassel.dev).

## Stack

- **Engine**: Godot 4.3+ (GDScript)
- **Art**: Procedural pixel art via Python + Pillow (`generate-sprites.py`)
- **Deployment**: Azure Static Web Apps (Free tier) at `game.maassel.dev`
- **Target platforms**: Web (HTML5), iOS (future)

## Quick Start

1. Install [Godot 4](https://godotengine.org/download) (4.3 or later)
2. Install Python 3 + Pillow: `pip install Pillow`
3. Generate sprites: `python generate-sprites.py`
4. Open this folder from the Godot project manager
5. Press **F5** to run

## Controls

| Key | Action |
|---|---|
| A / ← | Move left |
| D / → | Move right |
| W / ↑ / Space | Jump |

## Project Structure

```
scenes/              Scene files (.tscn) — one per entity/level/UI
scripts/             GDScript files (.gd) — one per scene that needs logic
assets/
  sprites/player/    Player animation frames (16×32px PNGs)
  sprites/slime/     Slime animation frames (16×16px)
  sprites/coin/      Coin animation frames (16×16px)
  sprites/goal/      Goal animation frames (16×32px)
  sprites/tiles/     Tile textures + atlas.png (16×16px each)
  sprites/bg/        Background decorations (clouds, bushes)
  tileset.tres       TileSet resource (physics + atlas)
dist/                HTML5 export output (gitignored, deploy only)
azure/               Bicep templates for Azure SWA
generate-sprites.py  Procedural sprite generator (Python + Pillow)
test-game.ps1        Dev feedback loop script (run/validate game)
```

## Art Pipeline

All sprites are generated procedurally — no external art tools required.

```bash
pip install Pillow
python generate-sprites.py
```

This produces 45 individual PNGs across `assets/sprites/` subdirectories, a tile atlas, and a `sprites-review.png` contact sheet for visual review.

The generator (`generate-sprites.py`) draws every pixel in code using Pillow, with a consistent retro palette. To modify sprites, edit the generator functions and re-run.

> **Future**: May switch to Aseprite for hand-drawn sprites later. The scene files reference individual PNGs, so the art source is swappable.

## Testing

```bash
# Run level validation (checks all levels for structural integrity)
.\test-game.ps1 -Validate

# Smoke test (headless import, checks for engine errors)
.\test-game.ps1 -Headless

# Run the game normally
.\test-game.ps1

# Jump to a specific scene
.\test-game.ps1 -Scene scenes/level_2.tscn
```

The validation suite (`scripts/validate_levels.gd`) auto-discovers all `level_*.tscn` files and verifies required nodes, tile data, and entity placement. Run it after adding or editing levels.

## Web Export

```bash
# From Godot editor:
# Project → Export → Web → Export Project → dist/index.html

# Or via CLI (requires Godot export templates installed):
godot --headless --export-release "Web" dist/index.html
```

Then commit `dist/` and push — GitHub Actions deploys to Azure SWA.

## iOS Export (future)

Requires macOS + Xcode. In Godot: Project → Export → iOS → configure signing with Apple Developer account.

## Design Backlog

See [DESIGN_BACKLOG.md](DESIGN_BACKLOG.md) for current state and next priorities.
