# 🧭 Wayfinder Map: Multi-Game Studio Roadmap & Architecture

## Destination
A fully specified, highly engaging retro-modern Tactical Turn-Based Grid Strategy game (*Sun & Steel: Tactics*) shipped as **Game 1** of a progressive multi-game indie studio roadmap documented in [game_spec.md](file:///c:/Workspace/platformer-game/docs/specs/game_spec.md).

## Notes & Standing Preferences
- **Game 1 Official Direction**: **Sun & Steel: Tactics** — Standalone Tactical Skirmish (*Fire Emblem* × *Warhammer* × *BG3* style).
- **Living Spec**: Maintained in [docs/specs/game_spec.md](file:///c:/Workspace/platformer-game/docs/specs/game_spec.md).
- **Research Guides**:
  - Benchmark Study Guide: [docs/research/game_inspiration_guide.md](file:///c:/Workspace/platformer-game/docs/research/game_inspiration_guide.md)
  - Studio Architecture Research: [docs/research/studio_architecture_research.md](file:///c:/Workspace/platformer-game/docs/research/studio_architecture_research.md)
  - Sprite Art & AI Pipeline Research: [docs/research/sprite_art_generation_pipeline.md](file:///c:/Workspace/platformer-game/docs/research/sprite_art_generation_pipeline.md)
- **Engine**: Godot 4.3+ (GDScript, Native 2D, cross-platform Web/Mobile/Deck/PC).

---

## 🗺️ Decision Ticket Index

### 🔴 Frontier (Active Decision Tickets)

*🎉 **The Frontier is CLEAR! All Wayfinder Decision Tickets are CLOSED! The route to Game 1 completion is 100% clear.** 🎉*

---

### ✅ Decisions Locked So Far (All Closed Tickets)

- [TICKET-14: Game 1 Campaign Scope](file:///c:/Workspace/platformer-game/docs/specs/game_spec.md) — **Option A: Standalone Tactical Skirmish**: A tight, highly polished 10-minute tactical battle arena against a squad of Golems with Victory/Defeat score tracking.
- [TICKET-05: Art Style & Asset Import Pipeline](specs/game_spec.md) — **Revised 2026-11-08: AI images from Antigravity's `generate_image`, converted by `tools/art/convert.py` and gated by `tools/art/validate.py`** (see `tools/art/README.md`). Chosen in a blind A/B against code-drawn sprites under one contract ([review page](https://claude.ai/artifact/GtaUbQiKZym7X3L5sc3RC1), private). Retro Diffusion / PixelLab were not adopted. Caveats: decided on a six-sprite sample; lava animation comes from scrolling one image; the floor tile repeats visibly; nearest-colour snapping shifts some colours. Board cells are 24 px squares (`GRID_SIZE`) and the tactics prototype draws the new sprites. Roster theme: fantasy (Sun Knight, Pyromancer, Frost Blade, Ranger, Cleric vs Golems); the August mech prototype art and code names were removed on 2026-11-08. **Revised 2026-11-09: the heroes and golems are now a chibi animal party for the owner's kids** (approved by the owner), each built by a recorded tool chain (`tools/art/rebuild.py`) and gated by an idle-flicker check; lessons in `tools/art/LESSONS.md`.
- [TICKET-13: Tactical Features & Class Ability Expansion](file:///c:/Workspace/platformer-game/docs/specs/game_spec.md) — **Phase 2 Complete**: Implemented Pyromancer Fireball AoE, Knight Shield Bash, Frost Blade Ice Dash, Cleric Heal, and Dynamic Ability HUD Button.
- [TICKET-12: Genre Selection for Game 1](file:///c:/Workspace/platformer-game/docs/specs/game_spec.md) — **Option B: Tactical Turn-Based Grid Strategy (*Sun & Steel: Tactics*)**: Selected Fire Emblem / Warhammer / BG3 inspired turn-based grid strategy as our official Game 1!
- [TICKET-10: Multi-Game Roadmap & Modular Architecture Charter](file:///c:/Workspace/platformer-game/docs/specs/game_spec.md) — **Progressive Game Series (Game 1 ➔ Game 2 ➔ Game 3)**: Build and ship compact games to accumulate reusable engine, UI, audio, and test modules.
- [TICKET-09: Dungeon Exploration & Puzzle Integration](file:///c:/Workspace/platformer-game/docs/specs/game_spec.md) — **Zelda / Golden Sun Dungeon Puzzle Keys**: Elemental Spirit Gems serve dual-purpose as combat magic AND overworld puzzle-solving tools.
- [TICKET-04: Game Identity & Loot Philosophy](file:///c:/Workspace/platformer-game/docs/wayfinder_map.md) — **Hand-Crafted Relics & Skill Mastery**: Rejected random Diablo RNG loot grinding in favor of unique key relics.
- [TICKET-02: Progression Model — Weapon Loadouts vs Talent Trees](file:///c:/Workspace/platformer-game/docs/specs/game_spec.md) — **Hades Weapon & Ability Loadout Model**: Replaced 50-node talent tree clutter with 4 active ability slots.
- [TICKET-06: Living Spec & Guiding Light](file:///c:/Workspace/platformer-game/docs/specs/game_spec.md) — **Created `docs/specs/game_spec.md`**: Maintained as the living design bible.
- [TICKET-07: Scoping & Co-Op Strategy](file:///c:/Workspace/platformer-game/docs/specs/game_spec.md) — **Solo First, Co-Op Ready Architecture**: Master single-player loop first.

---

## 🌫️ Not Yet Specified (Fog of War)

- **Game 2 Level Map & Roster**: Defining scope for Game 2 after Game 1 ships.
- **Visual Presentation & Sprite Sheet Import Pipeline**: Automated sprite sheet slicing and animation state import.

---

## ❌ Out of Scope
- Single massive 50-hour monolithic game as a first solo project.
- Complex 50-node talent tree clutter.
- Random Diablo RNG loot grinding.
