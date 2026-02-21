# Nick's Platformer

A pixel-art 2D platformer built with Godot 4. Deploys to [game.maassel.dev](https://game.maassel.dev).

## Stack

- **Engine**: Godot 4.3+ (GDScript)
- **Art**: Aseprite (sprites) + PixelLab.ai (AI generation)
- **Deployment**: Azure Static Web Apps (Free tier) at `game.maassel.dev`
- **Target platforms**: Web (HTML5), iOS (future)

## Quick Start

1. Install [Godot 4](https://godotengine.org/download) (4.3 or later)
2. Open this folder from the Godot project manager
3. Press **F5** to run

No external dependencies. All scripts are GDScript.

## Controls

| Key | Action |
|---|---|
| A / ← | Move left |
| D / → | Move right |
| W / ↑ / Space | Jump |

## Project Structure

```
scenes/         Scene files (.tscn)
scripts/        GDScript files (.gd)
assets/
  sprites/      Aseprite exports (PNG + JSON)
  tilesets/     Tile textures
  audio/        SFX + music
dist/           HTML5 export output (gitignored, deploy only)
azure/          Bicep templates for Azure SWA
.github/        GitHub Actions CI/CD
```

## Art Pipeline

1. Sketch on paper → photograph or scan
2. [PixelLab.ai](https://www.pixellab.ai) → generate pixel art from sketch/prompt
3. [Aseprite](https://www.aseprite.org) → refine frames, define animation tags
4. Export PNG sprite sheet + JSON from Aseprite
5. Drag `.ase` file into Godot or use PNG + JSON — set texture filter to **Nearest**

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
