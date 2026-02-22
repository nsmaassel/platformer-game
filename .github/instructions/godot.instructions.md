---
applyTo: 'scenes/**,scripts/**,assets/**'
---

# Godot Development Instructions

## Scene File (.tscn) Editing

When editing `.tscn` files programmatically or suggesting changes:

1. **Preserve UIDs** — Every scene has a `uid://` in its header. Never change or regenerate these.
2. **`load_steps` count** — Must equal `1 + number_of_ext_resources + number_of_sub_resources`. Godot may auto-correct but get it right.
3. **ext_resource IDs** — Use descriptive IDs like `"1_player"`, `"2_goal"` not just numbers.
4. **SpriteFrames format** — Complex sub_resource with animation arrays. When wiring sprites, use a Python script to generate the .tscn rather than manual string editing.

## TileMap / TileSet

- TileSet: `assets/tileset.tres` — TileSetAtlasSource with 7 tile types from `assets/sprites/tiles/atlas.png`
- Atlas layout: 7 tiles in a row (112×16), each 16×16
- Tile indices: 0=grass_top, 1=dirt, 2=grass_left, 3=grass_right, 4=wood_left, 5=wood_mid, 6=wood_right
- All tiles have `physics_layer_0` collision (full 16×16 polygon)
- TileMapLayer uses PackedInt32Array encoding: triplets of (packed_position, packed_source_atlas, packed_alt)
  - Position: `(y << 16) | (x & 0xFFFF)` where x and y are tile coordinates
  - Source atlas: `(atlas_y << 16) | atlas_x` — the tile's position in the atlas
  - Alt: always 0

## Animation Conventions

| Animation | Loop | Speed |
|-----------|------|-------|
| idle | yes | 3-8 fps |
| run/walk | yes | 6-10 fps |
| jump, fall | yes | 5 fps |
| hurt, squish, collect | NO | 8-12 fps |

## Physics Layers

- Layer 1: Terrain (TileMapLayer collision)
- Player: collision_layer=1, collision_mask=1
- Enemies: collision_layer=2, collision_mask=1
- Coins/Pickups: Area2D (no physics body)

## Common Gotchas

1. **New files added externally need Godot re-import.** Close and reopen the project in Godot editor, or run `godot --headless --import`. The `.godot/imported/` cache must be regenerated.
2. **Texture filter** must be `1` (Nearest) on all Sprite2D nodes, or set globally in project settings. Linear filtering destroys pixel art.
3. **AnimatedSprite2D `autoplay`** — Set to `&"idle"` for entities that should animate immediately (coins, goal).
4. **Polygon2D placeholders** — Some scenes have both AnimatedSprite2D (real sprites) and Polygon2D (colored shape placeholders). When sprites are loaded, set `AnimatedSprite2D.visible = true` and `Polygon2D.visible = false`.
5. **`is_on_floor()` in `_physics_process`** — Must call `move_and_slide()` first for consistent results, OR check at start of frame and accept one-frame delay.
6. **Scene changes** — Use `get_tree().change_scene_to_file()` for level transitions. `reload_current_scene()` for respawn.
