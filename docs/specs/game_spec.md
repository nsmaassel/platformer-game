# 📜 Game Specification: Multi-Game Studio Roadmap & Architecture (Living Spec)

## 1. Executive Summary & North Star Vision
- **Game 1 Status**: **"Sun & Steel: Tactics"** — Standalone Tactical Skirmish (*Fire Emblem* × *Warhammer* × *BG3* style).
- **Studio Strategy**: A progressive multi-game indie studio roadmap. Instead of building a massive monolithic game on day one, we build and ship compact, high-polish vertical slices (Game 1 ➔ Game 2 ➔ Game 3), accumulating a powerful library of reusable engine modules, shaders, UI components, and test tools.
- **Wayfinder Map Status**: **CLEAR ✅** All decision tickets closed in [docs/wayfinder_map.md](file:///c:/Workspace/platformer-game/docs/wayfinder_map.md).
- **Research Guides**:
  - Benchmark Study Guide: [docs/research/game_inspiration_guide.md](file:///c:/Workspace/platformer-game/docs/research/game_inspiration_guide.md)
  - Studio Architecture Research: [docs/research/studio_architecture_research.md](file:///c:/Workspace/platformer-game/docs/research/studio_architecture_research.md)
  - Sprite Art & AI Pipeline Research: [docs/research/sprite_art_generation_pipeline.md](file:///c:/Workspace/platformer-game/docs/research/sprite_art_generation_pipeline.md)

---

## ♟️ 2. Game 1 Blueprint: "Sun & Steel: Tactics"

```
┌─────────────────────────────────────────────────────────────────────────────┐
│                   SUN & STEEL: TACTICS GAMEPLAY ARCHITECTURE                │
├──────────────────────┬──────────────────────────┬───────────────────────────┤
│ Turn System          │ Hero Class Roster        │ Tactical Mechanics        │
├──────────────────────┼──────────────────────────┼───────────────────────────┤
│ • Player ⟷ Enemy     │ • Sun Knight (Tank/Melee)│ • Movement range tiles    │
│   Turn State Machine │ • Pyromancer (Ranged/AoE)│ • Attack range overlays   │
│ • Mouse-Click        │ • Frost Blade (Mobile)   │ • Squash/flash FX juice   │
│   Grid Selection     │ • Sun Ranger (Sniper)    │ • Telemetry logging       │
│                      │ • Sun Cleric (Healer)    │ • Cover & Lava hazards    │
└──────────────────────┴──────────────────────────┴───────────────────────────┘
```

### Core Features in `scenes/tactical_grid_prototype.tscn`:
1. **Interactive Grid System**: 12×10 board grid with automatic tile coordinate translation, `MOUSE_FILTER_IGNORE` click pass-through, and highlight overlays (Blue = Move, Red = Attack, Orange = AoE Fireball, Purple = Shield Bash, Cyan = Ice Dash, Green = Heal).
2. **5 Hero Classes**:
   - **Sun Knight**: High HP (45), heavy melee strike (`Atk 14`, `Move 3`, `Range 1`), Shield Bash.
   - **Pyromancer**: High damage (`Atk 18`, `Move 2`, `Range 3`), ranged flame staff, Fireball AoE.
   - **Frost Spellblade**: High mobility (`Atk 15`, `Move 4`, `Range 1`), fast ice blade, Ice Dash.
   - **Sun Ranger**: Longbow sniper (`Atk 16`, `Move 3`, `Range 4`).
   - **Sun Cleric**: Support healer (`Atk 8`, `Move 3`, `Range 2`, Heals +15 HP).
3. **Tactical Terrain**: Cover Rocks (30% Damage Mitigation) and Lava Hazards (10 Fire Damage).
4. **Enemy AI**: Automated turn processing where enemy Golems evaluate player proximity, move along optimal grid paths, and attack.
5. **Juice & SFX**: Integrated `JuiceEffects.gd` for hit-flashes, squash-and-stretch unit animations, sound triggers, and victory/defeat screens.

---

## 🎨 3. Art Pipeline (TICKET-05, revised 2026-11-08 and 2026-11-09)
- **Route**: AI concept images from Antigravity's built-in `generate_image` (one image per sprite: a row of idle poses on flat magenta). The heroes and golems are a chibi animal party (approved 2026-11-09, for the owner's kids): each is built by a recorded `chain` of deterministic tools (`crisp_convert`, `touchup`, `eye_pass`, `mane_pass`, `idle_bob`, or `draw_chibi` for designs drawn in code) run by `tools/art/rebuild.py`. Tiles and the rock prop use `tools/art/convert.py`. Details: `tools/art/README.md`; lessons: `tools/art/LESSONS.md`.
- **Contract & gate**: `tools/art/spec/sprites.json` (names, sizes, frames, anchors, art direction) and `tools/art/spec/palette.json` (62 colours); `tools/art/validate.py` checks sizes, binary alpha, palette-only pixels, feet row, stable idle frames, each hero's `target_height`, idle flicker (`max_flicker`) and seamless tiles; `tools/art/rebuild.py --check` proves the committed party sprites still come from their chains.
- **Converters**: `tools/art/crisp_convert.py` for characters (palette clusters, majority-colour downscale); `tools/art/convert.py` for tiles and props (background removal, frame split, one scale per sprite, palette snap, 1 px outline, anchoring; tiles get an edge cross-fade).
- **Provenance**: every prompt in `games/tactics/art/PROMPTS.md`; kept sources in `games/tactics/art/raw/`.
- **Output**: `games/tactics/assets/sprites/sun_steel/<name>.<frame>.png` (32×32 units with 4 idle frames, 24×24 tiles and props).
- **Why**: a blind A/B against agent-drawn code sprites under the same contract; the owner picked the AI-image set ([review page](https://claude.ai/artifact/GtaUbQiKZym7X3L5sc3RC1), private). Retro Diffusion / PixelLab were not adopted.
- **Roster theme**: fantasy (Sun Knight, Pyromancer, Frost Blade, Ranger, Cleric vs Golems), drawn as chibi animals since 2026-11-09: lion cub knight, red panda mage, snow leopard swordfighter, bunny archer, lamb healer vs pebble golems. The 28 px adult heroes of 2026-11-08 were replaced; their raw images are in git history. The August mech prototype art and its code names were removed on 2026-11-08; relics (`PartyManager.apply_relic`) replace the mech modules.
- **In game**: the tactics prototype (`tactical_grid_prototype`) uses 24 px square cells (`GRID_SIZE`) and draws the Sun & Steel sprites as animated units and tiles: all five heroes and the golems (a unit without art would fall back to its August placeholder).
- **Open**: the floor tile repeats visibly; lava animation is a scroll of one image; the shrine slice and boss arena still use August art.
- **Decoupled Engine Slot-In**: Node logic stays decoupled from PNG files so regenerated sprites drop in by name.

---

## 🚀 4. Multi-Game Workspace Progression Roadmap

- **Game 1 (Current Focus)**: *Sun & Steel: Tactics* — Standalone Tactical Skirmish.
- **Game 2 (Next Milestone)**: 3-5 room experience combining puzzles, inventory, and tactical battles.
- **Game 3 (Flagship Destination)**: Full flagship title incorporating all modules built in Games 1 & 2.

---

## 🤖 5. Agentic Verification & Feedback Loops

| Verification Layer | Tool / Command | What It Validates |
|---|---|---|
| **Tier 1: Level Assertion** | `.\test-game.ps1 -Validate` | Verifies node structure across all 22 scenes. |
| **Tier 2: Headless Playtest Bot** | `& "path/to/Godot.exe" --headless --script scripts/bot_playtest_tactics.gd` | Programmatically executes unit selection, grid movement math, attack damage, abilities, and enemy AI turns. |
| **Tier 3: Telemetry Logging** | `user://combat_telemetry.log` | Records timestamped JSON event logs. |
