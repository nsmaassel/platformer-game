# Lessons from making the Sun & Steel chibi party

What we learned turning AI concept art into 32x32 animated sprites for a kids' tactics game (November 2026). They
apply to any small-sprite work that goes AI concept, converter, then code passes. Each lesson names the tool or check
it turned into; the tools are in this folder and the how-to is in [README.md](README.md).

## Small sprites are decided by the downscale, not the prompt
- A painted AI image averaged down to about 21 px turns soft and muddy (`convert.py`, fine for tiles). For characters,
  snap to flat colour clusters and take each block's majority colour instead (`crisp_convert.py --colours 24`).
- Thin dark lines inside the body become single-pixel specks. Raise `--dark-share` (0.5 for the red panda and the
  bunny) so only real outlines stay dark.
- Frames drift because the AI puts the face in a slightly different place in each pose. `--align head` lines frames
  up on the head, not on the bounding box.
- Pale, detailed designs (white fur, many spots, wool curls) turn to speckle even after a simpler prompt. A
  true-colour downscale tells you whether the design or the converter is at fault. If it's the design, draw it in
  code from the concept, with the converted heroes as the style target (`draw_chibi.py`: the snow leopard, the lamb).
- Glowing eyes on a dark body get lost in the palette snap (the AI golem). Draw that sprite in code too.
- AI layouts vary: sometimes two rows, a 2x2 grid or stray pieces. Handle them with converter flags (`--rows`,
  `--grid`) rather than spending another generation.
- Prompts that helped: one row of four poses on flat magenta; head about half the height; "make the animal's defining
  features oversized and simple so they stay readable at about 21 pixels"; flat fills with at most two tones per
  material and no thin internal lines; a party concept as the reference image for layout and outline only.

## Faces need code
- The downscale shrinks AI eyes to 1 px dots, and no prompt fixes that. A code eye pass stamps 2x3 eyes with a
  highlight, cheeks, a nose and a blink (`eye_pass.py`). Give each hero a different blink frame so the party doesn't
  blink in unison.

## The silhouette is the animal
- What reads at 1x is the outline: the lion's spiky mane, the bunny's ears, the snow leopard's thick ringed tail.
  Markings inside the body mostly vanish. When the AI's version of the key feature is too timid, grow it in code
  (`mane_pass.py`).
- Don't let the height rule clip the feature that makes the character (the flat top on the first mane). Raise that
  sprite's `target_height` on purpose and say why in its brief; don't loosen the check.

## Idle animation: hold one pose, add motion in code
- AI idle poses differ in small details (ear linings, mane flecks, face markings, robe folds). Played as an
  animation, those differences flicker. Converted heroes changed 50-132 pixels per frame beyond the bob (the adult
  heroes 75-323); the code-drawn snow leopard and lamb changed 2-11, which is just the blink and a glint. The
  validator passed them all; the owner's eye caught it.
- Fix: hold every frame on one cleaned key pose (`touchup.py --lock 0,0,31,31 --from K`), then add the motion in code
  like the code-drawn heroes: everything above the feet drops 1 px on frames 1-2 (`idle_bob.py`), plus the eye pass
  blink. The converted heroes now change 0-8 pixels per frame.
- Order matters: hold, then eyes and blink, then mane, then the bob last, so the eyes, mane and body move together.
- Pick the key frame for its clean details (the bunny's tidiest ears). Fix leftovers with recorded `--patch` pixels,
  never hand edits.
- Gate: `max_flicker: 16` in the spec makes `validate.py` fail any frame that changes more than 16 pixels against
  frame 0 once each row is allowed to move down 1 px (the bob). Compare whole rows: a first per-pixel version forgave
  a recoloured fleck whenever it matched the pixel above or below, which flat two-tone fills often do. The golem's
  budget is 24, because its squash and flickering ember eyes are deliberate motion (13-20 pixels).
- The game plays every numbered frame it finds, so `validate.py` also fails a leftover frame past the spec's count.
- In the game, start each unit's idle on a different frame. Seeding it from the grid position put three heroes on
  the same frame; the spawn order (`active_units.size() % frames`) spreads them.
- Heroes of different heights need their own HP bar height: the game places each bar just above the top opaque row
  of the unit's first frame.

## Gear: bake in the signature weapon
- Each hero is one sprite with its signature weapon baked in. Relics (stat bonuses) and loadouts (ability slots)
  don't change the sprite; if a relic should show, the game draws an icon or a glow over it. Gear variants would
  multiply every chain by four frames per item per hero and fight the held-pose approach.

## Process
- Show sprites animated at 4-8x and at 1x, next to the rest of the party, on the floor colour, then in the game. Let
  the owner and the kids react to pictures (a pick page with votes) before asking structured questions.
- Every sprite's exact build steps are its `chain` in the spec, and `rebuild.py --check` proves the committed pixels
  still come from them. Compare pixels, not PNG bytes: zlib builds compress differently. When the tools moved from the
  scratch folder into this repo, rebuilding gave the same bytes as the approved art, which proved the port.
- Each piece of feedback becomes a tool flag or a check, not a one-off edit. Panda face flicker became `touchup.py`.
  The flat mane became `--crown`. Frame flicker became `idle_bob.py` and `max_flicker`.
- When a person catches something the validator missed, add the check that would have caught it, and prove it fails
  on the old art.
- Image quota: about 14 Antigravity `generate_image` calls per window. Spend them on concepts, not on details the
  code passes can fix.

## Where this knowledge lives
- Rules that can be checked are tools and gates in this folder, because those run every time.
- Reasons and judgment calls are in this file, versioned with the tools they explain.
- The `pixel-sprites` skill in agent-core points any agent, in any repo, at this pipeline instead of copying it.
