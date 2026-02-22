You are an expert in Godot 4, GDScript, 2D pixel-art game development, and Python tooling.

## Project Overview

**Nick's Platformer** — A pixel-art 2D platformer built with Godot 4.3+ (GDScript). Deploys as HTML5 to [game.maassel.dev](https://game.maassel.dev) via Azure Static Web Apps.

**Solo developer project** — Optimize for speed and simplicity.

## Technical Stack

- **Engine:** Godot 4.3+ with `gl_compatibility` renderer
- **Language:** GDScript (no C#, no plugins)
- **Viewport:** 480×270 pixels, `canvas_items` stretch mode, `keep` aspect
- **Texture filter:** Nearest (pixel-art — never use linear filtering)
- **Art pipeline:** Python 3 + Pillow for procedural sprite generation (see `generate-sprites.py`)
- **Deployment:** HTML5 export → `dist/` → GitHub Actions → Azure SWA

## Project Structure

```
project.godot          Godot project config (autoloads, input maps, display)
scenes/                Scene files (.tscn) — one per entity/level/UI
scripts/               GDScript files (.gd) — one per scene that needs logic
assets/
  sprites/player/      Player animation frames (16×32px PNGs)
  sprites/slime/       Slime animation frames (16×16px)
  sprites/coin/        Coin animation frames (16×16px)
  sprites/goal/        Goal animation frames (16×32px)
  sprites/tiles/       Tile textures + atlas.png (16×16px each)
  sprites/bg/          Background decorations (clouds, bushes)
  tileset.tres         TileSet resource (physics + atlas)
azure/                 Bicep templates for Azure SWA
dist/                  HTML5 export output (gitignored, built locally)
generate-sprites.py    Procedural sprite generator (Python + Pillow)
```

## Architecture & Patterns

### Scene/Script Pairing
Each `.tscn` has a matching `.gd` in `scripts/`. Scenes are composed:
- `player.tscn` → instanced in level scenes
- `slime.tscn`, `coin.tscn`, `goal.tscn`, `checkpoint.tscn` → instanced in levels
- `level_1.tscn`, `level_2.tscn` → standalone level scenes with TileMapLayer terrain

### Global Autoload
`GameState` (scripts/game_state.gd) — singleton tracking lives, score, current_level, checkpoint.
Access from anywhere: `GameState.lives`, `GameState.add_score(10)`, `GameState.reset()`

### Groups
- `"player"` — Player CharacterBody2D (used for collision detection by enemies/coins)
- `"enemy"` — All enemies (used by player's hurt detection)
- `"coin"` — All coins (currently unused but available)

### Player Mechanics
- Coyote time (0.12s) + Jump buffer (0.12s) for responsive feel
- Stomp area (feet) kills enemies, Hurt area (body) takes damage
- `_has_sprites` flag: auto-detects if SpriteFrames have real frames loaded. Shows `AnimatedSprite2D` if yes, `Placeholder` Polygon2D if no.
- Fall death at y > 320

### Enemy Pattern (Slime)
- Patrol: walks at constant speed, reverses on wall or ledge edge
- `stomp()` method: called by player's stomp area → `queue_free()`
- `LedgeCheck` RayCast2D points down-forward, detects ledge edges

### Level Structure
- TileMapLayer with TileSet from `assets/tileset.tres` (7 tile types, physics collision on all)
- Background: Sky ColorRect + Sprite2D clouds/bushes
- Player, Goal, enemies, coins instanced as child nodes
- HUD CanvasLayer with LivesLabel, LevelLabel, ScoreLabel

### Level Progression
Goal.gd loads `level_{N+1}.tscn` if it exists, otherwise returns to main menu.
Add new levels by creating `level_N.tscn` — no code changes needed.

## Sprite Specifications

| Entity | Size | Animations |
|--------|------|-----------|
| Player | 16×32px | idle(4f@5fps), run(6f@10fps), jump(2f), fall(2f), hurt(3f) |
| Slime | 16×16px | walk(4f@6fps), squish(2f@8fps, no loop) |
| Coin | 16×16px | idle(6f@8fps), collect(4f@12fps, no loop) |
| Goal | 16×32px | idle(2f@3fps) |
| Tiles | 16×16px | grass_top, dirt, grass_left/right, wood_left/mid/right |
| BG | 16×16px | cloud_left, cloud_right, bush |

## Key Rules

1. **Always use `texture_filter = 1` (Nearest)** on Sprite2D/AnimatedSprite2D nodes for pixel art
2. **Never use linear/bilinear filtering** — it blurs pixel art
3. **16px grid alignment** — all tiles, entities snap to 16px grid in levels
4. **Physics layer 1** for terrain collision (player + enemies collide with it)
5. **PackedScene instances** — entities are instanced, not defined inline in level scenes
6. **GDScript style:** snake_case for variables/functions, PascalCase for classes/nodes, UPPER_SNAKE for constants
7. **No `@tool` scripts** unless explicitly needed for editor visualization
8. **Scene UIDs** — preserve existing `uid://` values when editing .tscn files; Godot uses them for cross-references

## Godot CLI Reference

```bash
# Run game
godot --path . --main-scene scenes/main_menu.tscn

# Export to HTML5
godot --headless --export-release "Web" dist/index.html

# Import resources (force re-import)
godot --headless --import
```

## Git Workflow

Solo dev — commit directly to main. No PRs needed.
- Commit sprites + scene changes together (they're coupled)
- `dist/` committed only for deployment
- `.godot/` always gitignored (engine cache, regenerated on open)

## Reference Documentation

- [DESIGN_BACKLOG.md](../DESIGN_BACKLOG.md) — Feature tracking and prioritization
- [README.md](../README.md) — Setup and controls
- `.github/instructions/art-pipeline.instructions.md` — Procedural sprite generation details
- `.github/instructions/godot.instructions.md` — Godot-specific patterns and gotchas
