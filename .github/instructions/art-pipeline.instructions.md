---
applyTo: 'generate-sprites.py,assets/sprites/**'
---

# Art Pipeline Instructions

## Overview

Sprites are generated procedurally using Python + Pillow (`generate-sprites.py`), NOT drawn in Aseprite or AI tools. This approach was chosen for rapid iteration and reproducibility.

## Running the Generator

```powershell
cd C:\Workspace\platformer-game
python generate-sprites.py
```

**Output:** 45 individual PNGs in `assets/sprites/` subdirectories + `assets/sprites/tiles/atlas.png` + `sprites-review.png` contact sheet.

## Generator Architecture

`generate-sprites.py` (~650 lines):
- `PAL` dict: 30+ named colors (palette constants)
- `rect()`, `line()`, `pixel()` helpers: draw primitives on PIL Image
- Entity functions: `make_player()`, `make_slime()`, `make_coin()`, `make_goal()`, `make_tiles()`, `make_bg()`
- Each returns a list of `(filename, Image)` tuples
- Contact sheet at 4× zoom for visual review
- Bounds guard: `if w <= 0 or h <= 0: return` in rect() for animation frames that shrink

## After Generating Sprites

1. Sprites go into `assets/sprites/{entity}/` directories
2. Scene files (.tscn) must reference them as ext_resources with `type="Texture2D"`
3. SpriteFrames sub_resources define animation names, frame counts, speeds
4. **Godot must re-import** new sprites — close and reopen project, or `godot --headless --import`

## Wiring Sprites into Scenes

Use a Python script to rewrite .tscn files (don't do it by hand — SpriteFrames format is complex). The script should:
1. Define ext_resource entries for each PNG
2. Build SpriteFrames sub_resource with animation arrays
3. Preserve existing UIDs and node structure
4. Set `texture_filter = 1` on all sprite nodes

## Adding New Entities

1. Add a new function to `generate-sprites.py` (follow `make_slime()` pattern)
2. Add the call in `main()` and include in contact sheet
3. Run generator
4. Create matching `.tscn` + `.gd` files
5. Wire sprites with a Python script or manually add ext_resources
