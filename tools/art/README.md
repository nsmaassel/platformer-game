# Sun & Steel art pipeline

How sprites for *Sun & Steel: Tactics* are made, converted and checked (TICKET-05, `docs/specs/game_spec.md` §3).
The heroes and golems are a chibi animal party, approved on 2026-11-09: each is built by a recorded chain of small
deterministic tools. The tiles and the rock prop still come from the 2026-11-08 averaging converter. What we
learned making the party, and why each tool exists, is in [LESSONS.md](LESSONS.md); read it before making a new
sprite.

```
generate_image (Antigravity) ─> games/tactics/art/raw/<name>_chibi.png
   │                                   │
   prompt in games/tactics/art/PROMPTS.md
                                       ├─ converted: crisp_convert ─> touchup (hold one pose) ─> eye_pass ─> [mane_pass] ─> idle_bob
                                       └─ pale or glowing designs: draw_chibi (drawn in code from the concept)
                                                          │
            rebuild.py runs each sprite's "chain" from spec/sprites.json
                                                          │
                     games/tactics/assets/sprites/sun_steel/<name>.<frame>.png
                                                          │
            validate.py (gate)   rebuild.py --check (the chain still makes it)   preview.py (look)
```

## The contract
- `spec/sprites.json`: every sprite's name, size, frame count, anchor rules, art direction and, for the party, its
  `chain`. Binding.
  - Units are 32×32 with 4 idle frames; feet on rows 28–30. Each hero has its own `target_height` (the party is
    about 21–23 px; the bunny's ears make it 28 and the lion's mane 23, on purpose, with the reason in the brief).
  - `max_flicker` (16 for the party) caps how many pixels any frame may change against frame 0 beyond a 1 px bob.
  - Tiles are 24×24 and must repeat without seams; board cells are 24 px (`GRID_SIZE`).
- `spec/palette.json`: the 62 colours every opaque pixel must use, in hue-shifted ramps.

## Making a party sprite
1. **Concept.** Write a prompt from the sprite's `brief`: ONE horizontal row of four idle poses of the same character
   on flat pure magenta (#FF00FF), turned slightly 3/4 right, chibi proportions (head about half the height), the
   animal's defining features oversized and simple, flat fills with at most two tones per material, no thin internal
   lines. Pass an existing party concept as the reference image for layout and outline only. Never use franchise or
   existing-game names, "in the style of", or look-alike creatures. Generate with Antigravity's built-in
   `generate_image`, save the kept image as `games/tactics/art/raw/<name>_chibi.png` and log the exact prompt in
   `PROMPTS.md`.
2. **Decide: convert or draw.** Run `crisp_convert.py` on it and look at 8x. If a pale or detailed design (white fur,
   many spots, wool, glowing eyes on a dark body) turns to speckle, draw it in code instead: add a function to
   `draw_chibi.py` from the concept, using the converted heroes as the style target.
3. **Build the chain**, each step reading and writing frames by name in a work folder (default `logs/art/work`):
   - `crisp_convert.py <raw> <name>_crisp --height H --colours 24 [--dark-share 0.5] [--align head] [--rows Y0,Y1 | --grid]`:
     palette clusters and majority-colour downscale, so details stay crisp instead of averaging to mud.
   - `touchup.py <name>_crisp <name>_key --lock 0,0,31,31 --from K [--recolour old=new,...] [--patch x,y=colour;...]`:
     holds every frame on the cleanest pose K, so small differences between the AI's poses don't flicker; recolours
     palette strays; patches single pixels.
   - `eye_pass.py <name>_key <name>_eyes [--eyes LX,RX,ROW] --blink N`: 2x3 eyes with a highlight, cheeks, a nose and
     the blink. Give each hero a different blink frame.
   - `mane_pass.py ... --style spiky --crown 2` (the lion only): grows the silhouette feature the AI drew too timidly.
   - `idle_bob.py <name>_eyes <name>`: last, so eyes, mane and body move together; everything above the feet drops
     1 px on frames 1–2.
4. **Record** the steps as the sprite's `chain` in `spec/sprites.json` (without `--work`; the last step writes the
   sprite's own name), then `python tools/art/rebuild.py --name <name>` writes the frames.
5. **Check:** `python tools/art/validate.py` and `python tools/art/rebuild.py --check` must both exit 0.
6. **Look:** animated at 4–8x and at 1x next to the rest of the party on the floor colour (`python tools/art/preview.py`
   writes `logs/art/sheet.png` and `logs/art/board3x_0.png`), and in the game with one windowed run of
   `games/tactics/scripts/bot_playtest_tactics.gd` (headless runs can't capture the screen). Show the owner before
   it goes in.

## Tiles and props (averaging converter)
`python tools/art/convert.py [--name <name>]` converts `games/tactics/art/raw/<name>.png` for every sprite without a
`chain`: background flood fill, frame split by gaps, one scale per sprite, palette snap (nearest colour), 1 px
`ink.0` outline, anchoring. Tiles get an edge cross-fade so they wrap. Fallbacks are logged in
`games/tactics/art/convert_log.json`. It is too soft for small characters (see LESSONS.md); keep it for tiles and
props.

## Known limits
- Nearest-colour snapping can move a colour to a neighbouring ramp.
- `tile_lava` has one source image; frames 1–3 are made by scrolling it.
- The floor tile repeats visibly at 24 px; variants would help.
- The party heroes all bob on frames 1–2; the game starts each unit on a different frame so the board doesn't pulse
  in unison.
- The August experiments (`tools/pixel_art_lab/` and the concept-sheet slicers in `tools/python_scripts/`) were
  retired on 2026-11-08; they are in git history.
