# Sun & Steel art pipeline

How sprites for *Sun & Steel: Tactics* are made, converted and checked. Decided on 2026-11-08 by a blind A/B
between code-drawn sprites and AI images under one contract; the AI-image set was picked (TICKET-05,
`docs/specs/game_spec.md` §3).

```
generate_image (Antigravity) ──> games/tactics/art/raw/<name>.png ──> tools/art/convert.py
        │                                                                    │
  prompt logged in games/tactics/art/PROMPTS.md          games/tactics/assets/sprites/sun_steel/<name>.<frame>.png
                                                                             │
                                                     tools/art/validate.py (gate)   tools/art/preview.py (look)
```

## The contract
- `spec/sprites.json`: every sprite's name, size, frame count, anchor rules and art direction. Binding.
  - Units are 32×32 with 4 idle frames; feet on rows 28–30; heroes share a 28 px body height (`target_height`).
  - Tiles are 24×24 and must repeat without seams; board cells are 24 px (a proposal: `GRID_SIZE` in
    `games/tactics/scripts/tactics/tactical_board.gd` is still 16).
- `spec/palette.json`: the 62 colours every opaque pixel must use, in hue-shifted ramps.

## Making a sprite
1. Write a prompt from the sprite's `brief`. For units, ask for ONE horizontal row of four idle poses of the same
   character on a flat pure magenta (#FF00FF) background, facing forward turned slightly 3/4 right. Start hero prompts
   with the shared opening from the kept Sun Knight prompt in `games/tactics/art/PROMPTS.md`. Keep held items at or
   below head height so the shared body height isn't shrunk. Never use franchise or existing-game names.
2. Generate with Antigravity's built-in `generate_image` (subscription quota). Save the kept image as
   `games/tactics/art/raw/<name>.png` and log the exact prompt, round and kept/discarded status in `PROMPTS.md`.
3. Convert: `python tools/art/convert.py [--name <name>]`. Deterministic: background flood fill, frame split by gaps,
   one scale per sprite, palette snap (nearest colour), 1 px `ink.0` outline, anchoring. Tiles get an edge
   cross-fade so they wrap. Fallbacks (single-frame sources) are logged in `games/tactics/art/convert_log.json`.
4. Check: `python tools/art/validate.py` must exit 0.
5. Look: `python tools/art/preview.py` writes `logs/art/sheet.png` and `logs/art/board3x_0.png` (the whole roster on a
   12×10 board). Judge at 1× first; that is the in-game size.

## Known limits
- Nearest-colour snapping can move a colour to a neighbouring ramp (sand plating partly snapped to skin tones in the A/B).
- `tile_lava` has one source image; frames 1–3 are made by scrolling it.
- The floor tile repeats visibly at 24 px; variants would help.
- `pixlib.py` also holds a small canvas toolkit for code-drawn pieces (effects, UI) if a hybrid is wanted later.
- The August experiments (`tools/pixel_art_lab/` and the concept-sheet slicers in `tools/python_scripts/`) were
  retired on 2026-11-08; they are in git history if an idea from them is wanted (for example orphan-pixel cleanup).
