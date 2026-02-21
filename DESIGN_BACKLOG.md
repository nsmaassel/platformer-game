# Nick's Platformer — Design Backlog

This is the agentic design tracking doc. When working with Claude/Copilot, share this file to get
prioritized next-steps. Update it after each work session.

## Current State

- [x] Project scaffolded (Godot 4.3+)
- [x] Core game systems: player, game state, goal trigger
- [x] Level 1 (staircase layout, placeholder geometry)
- [x] Main menu
- [ ] Aseprite sprites imported (player idle/run/jump/fall)
- [ ] Enemy type 1
- [ ] Level 2
- [ ] HUD (health/lives display)
- [ ] Sound effects
- [ ] Background music
- [ ] Save/load progress
- [ ] iOS export configured

## Scenes Inventory

| Scene | Path | Status |
|---|---|---|
| Main Menu | scenes/main_menu.tscn | ✅ Done |
| Level 1 | scenes/level_1.tscn | ✅ Done (placeholder art) |
| Player | scenes/player.tscn | ✅ Done (no sprites yet) |
| Goal | scenes/goal.tscn | ✅ Done |

## Art Queue (PixelLab.ai → Aseprite)

Priority order for art generation:
1. **Player character** — 16×32px, animations: idle (4f), run (6f), jump (2f), fall (2f), hurt (3f)
2. **Ground tiles** — 16×16px, grass top + dirt fill
3. **Platform tiles** — 16×16px, wood or stone
4. **Goal marker** — 16×32px (flag or star), idle animation
5. **Enemy 1 (Slime)** — 16×16px, hop animation
6. **Background** — parallax sky + clouds (96×54px chunks)

## Mechanics Backlog

- [ ] Coyote time (implemented, tweak feel)
- [ ] Jump buffer (implemented, tweak feel)
- [ ] Variable jump height (hold jump = higher)
- [ ] Enemy stomping
- [ ] Collectible coins
- [ ] Checkpoint system
- [ ] Moving platforms
- [ ] Spring/bounce pad
- [ ] Water/hazard tiles

## Level Design Notes

Level template: 480×270 viewport (480px wide sections, stack vertically for longer levels)
Target level length: 2–4 screen widths per level
Difficulty curve: 1 (learn mechanics) → 2 (add enemies) → 3 (speed/precision section) → boss or challenge room
