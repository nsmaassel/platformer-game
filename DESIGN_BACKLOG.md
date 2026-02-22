# Nick's Platformer — Design Backlog

This is the agentic design tracking doc. When working with Claude/Copilot, share this file to get
prioritized next-steps. Update it after each work session.

## Current State

- [x] Project scaffolded (Godot 4.3+)
- [x] Core game systems: player, game state, goal trigger
- [x] Level 1 (TileMap terrain, background decorations)
- [x] Level 2 (TileMap terrain, enemies, coins, checkpoint)
- [x] Main menu
- [x] Procedural sprite generator (`generate-sprites.py` — Python + Pillow, 45 PNGs)
- [x] Player sprites wired (idle/run/jump/fall/hurt)
- [x] Slime sprites wired (walk/squish)
- [x] Coin sprites wired (idle/collect)
- [x] Goal sprites wired (idle)
- [x] Tile atlas + TileSet with physics collision
- [x] Both levels converted to TileMapLayer terrain
- [x] Background decorations (sky, clouds, bushes)
- [x] Enemy type 1 (Slime — patrol + stomp)
- [x] HUD (lives, level, score display)
- [x] Checkpoint system
- [x] Copilot instructions + VSCode workspace config
- [ ] Checkpoint sprites (still using polygon placeholders)
- [ ] Sound effects
- [ ] Background music
- [ ] Save/load progress
- [ ] Web export + deployment pipeline test
- [ ] iOS export configured

## Scenes Inventory

| Scene | Path | Status |
|---|---|---|
| Main Menu | scenes/main_menu.tscn | ✅ Done |
| Level 1 | scenes/level_1.tscn | ✅ Done (TileMap + sprites) |
| Level 2 | scenes/level_2.tscn | ✅ Done (TileMap + sprites + enemies) |
| Player | scenes/player.tscn | ✅ Done (17 sprite frames wired) |
| Slime | scenes/slime.tscn | ✅ Done (6 sprite frames wired) |
| Coin | scenes/coin.tscn | ✅ Done (10 sprite frames wired) |
| Goal | scenes/goal.tscn | ✅ Done (2 sprite frames wired) |
| Checkpoint | scenes/checkpoint.tscn | ⚠️ Logic done, sprites placeholder |

## Art Pipeline

All sprites generated procedurally via `generate-sprites.py` (Python + Pillow).
Run `python generate-sprites.py` to regenerate. See `.github/instructions/art-pipeline.instructions.md`.

### Sprite Inventory (45 PNGs)

| Entity | Dir | Files | Size |
|--------|-----|-------|------|
| Player | assets/sprites/player/ | 17 PNGs (idle×4, run×6, jump×2, fall×2, hurt×3) | 16×32px |
| Slime | assets/sprites/slime/ | 6 PNGs (walk×4, squish×2) | 16×16px |
| Coin | assets/sprites/coin/ | 10 PNGs (idle×6, collect×4) | 16×16px |
| Goal | assets/sprites/goal/ | 2 PNGs (idle×2) | 16×32px |
| Tiles | assets/sprites/tiles/ | 7 PNGs + atlas.png | 16×16px |
| BG | assets/sprites/bg/ | 3 PNGs (cloud_left, cloud_right, bush) | 16×16px |

## Next Priorities

1. **Playtest & tune** — Run game, fix tile/entity positioning, test all mechanics
2. **Checkpoint sprites** — Add to generator, wire into checkpoint.tscn
3. **Audio** — Jump SFX, coin collect, enemy stomp, background music
4. **Level 3** — Introduce moving platforms or new enemy type
5. **Web export test** — Verify HTML5 export works, deploy to game.maassel.dev
