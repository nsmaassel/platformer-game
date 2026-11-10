# Walkthrough: Sun & Steel tactics round (2026-11-08)

Follows the art-pipeline work that added `tools/art/` and the first sprites.

## 1. Summary

Changes in this round:

1. **Fantasy party in code**. The tactics prototype's units carry the Sun & Steel names (Sun Knight,
   Pyromancer, Frost Blade, Sun Ranger, Sun Cleric vs Basalt/Cinder/Ash Golems); the cleric's ability is HEALING_LIGHT.
   `HangarManager` became `PartyManager` (`get_available_classes`, `validate_party`, `apply_relic` with EMBER_SIGIL and
   WARDING_CHARM), `MechaChassisData` became `HeroClassData`, the campaign finale is "Golem Forge Siege", and the main
   menu entry reads "Sun & Steel Tactics". The 52 mech and franchise-derived images were removed.
2. **Square 24 px cells**. `GRID_SIZE` (previously unused) now drives every cell calculation; the 12×10
   board sits at x 6–294, y 15–255 and the HUD moved to a right-hand panel.
3. **Sun & Steel sprites in the game**. Units animate their 4 idle frames at 6 fps with feet on the cell's
   bottom edge; floor, lava and cover-rock tiles replace the coloured cells. A unit without art falls back to its
   August placeholder. Fixed on the way: HP-bar frames used to stay behind at the spawn cell when a unit moved.
4. **August lab retired**. `tools/pixel_art_lab/`, the mech concept-sheet slicers and the mech sections of
   `generate-sprites.py` are gone; the `-Preview` tactics mock mirrors the real layout; the provenance log points to
   `games/tactics/art/PROMPTS.md` and forbids franchise or existing-game names in prompts.

5. **Self-review fixes**. HUD clicks no longer also act on the board (`TacticalBoard.is_on_board`, with
   `test_tactical_board.gd`); units are y-sorted; scrolled lava frames now loop; unit frames are cached and counted
   from the files present; converter fallbacks and logging hardened.
6. **Full hero roster.** The Frost Blade, Ranger and Cleric were generated after the image quota reset, with the Sun
   Knight as the reference image, so all five heroes and the golems now play with Sun & Steel art and no placeholder
   remains on the tactics board.
7. **Chibi animal party (2026-11-09).** The owner's kids found the adult heroes hard to connect with, so the heroes
   and golems were redrawn as cute chibi animals and approved: lion cub Sun Knight, red panda Pyromancer, snow
   leopard Frost Blade, bunny Ranger, lamb Cleric and pebble golems. Each sprite is built by the `chain` in its spec
   entry (`tools/art/rebuild.py`); new tools `crisp_convert`, `touchup`, `eye_pass`, `mane_pass`, `idle_bob` and
   `draw_chibi`; `validate.py` gained the `max_flicker` gate. In the game, each unit starts its idle on a different
   frame and its HP bar sits just above its own art. Lessons: `tools/art/LESSONS.md`.

No franchise names remain in tracked files (checked with a case-insensitive `git grep` for the removed names).
`render-level-previews.py` copies previews to an extra folder only when `PREVIEW_COPY_DIR` is set (it used to write
into a hard-coded local Antigravity folder).

## 2. Visual evidence

```carousel
![Tactics prototype, real windowed bot run](logs/tactics_live.png)
<!-- slide -->
![Tactics preview mock from -Preview](logs/tactics_preview.png)
<!-- slide -->
![Art pipeline board preview](logs/art/board3x_0.png)
```

Headless runs cannot capture the viewport, so `logs/tactics_live.png` comes from one windowed run of
`games/tactics/scripts/bot_playtest_tactics.gd`.

## 3. Automated verification

| Check | Command | Result |
| :--- | :--- | :--- |
| GDScript unit tests | `.\test-game.ps1 -Test` | `TEST SUMMARY: 16 passed, 0 failed out of 16 total` (party and board suites included) |
| Playtest bots | `.\test-game.ps1 -Replay` | `BOT SUMMARY: 100% PLAYTEST PASSED CLEANLY`; the tactics bot selects the Sun Knight |
| Level & node validation | `.\test-game.ps1 -Validate` | `VALIDATE SUMMARY: 67 passed, 0 failed, 0 warnings` |
| Pixel audit | `.\test-game.ps1 -Pixel` | audit passed (lossless imports, crisp edges) |
| Previews | `python tools/python_scripts/generate-sprites.py` then `.\test-game.ps1 -Preview` | generator runs without its mech sections; all previews rendered |
| Art contract | `python tools/art/validate.py` | `PASS: 30 files, 0 problems` (full roster, nothing pending) |
| Party chains | `python tools/art/rebuild.py --check` | `PASS: 6 sprites match their chains` |

Known and unchanged from before this round: the Godot stderr logs of `-Validate` (30) and `-Replay` (14) contain
`Identifier not found: GameState` compile errors, because `--script` runs do not load autoloads, and the headless
tactics bot logs one null-texture error from its screenshot attempt. `generate-sprites.py` also rewrites
`shrine/cover_rock.png` and `shrine/guardian.png` with versions that differ from the committed ones; those were
restored, not committed.

## 4. How to play

- `play-game.bat`, then "Play Game 1: Sun & Steel Tactics" in the main menu; or open
  `games/tactics/scenes/tactical_grid_prototype.tscn` in Godot.
- Click a hero to move or attack; the ability button uses the class ability (Shield Bash, Fireball, Ice Dash,
  Piercing Shot, Healing Light).
