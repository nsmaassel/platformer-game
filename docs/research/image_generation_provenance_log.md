# Image Generation Provenance & Prompt Log

Every AI-generated image used by the project is logged with the tool, the exact prompt and whether it was kept.

## Where the log lives now

- **Sun & Steel sprites:** `games/tactics/art/PROMPTS.md` (one row per generated image, kept or discarded,
  including reference images passed to the generator). The pipeline is described in `tools/art/README.md`.

## Retired entries

The August 2026 mech concept images (prototype unit sprites, portraits and battle scenes made with
`generate_image`) were removed from the project on 2026-11-08 together with the mech prototype art, when the game
settled on its fantasy roster. Their rows are in git history.

## Prompt rules

1. Log every generated image (kept or discarded) with the exact prompt, the tool, and any reference image.
2. Describe designs in your own words. Never put franchise, character or existing-game names in a prompt, and do not
   ask for another game's look ("in the style of ..."); name the qualities you want instead (view, palette, outline,
   proportions).
3. Follow the sprite prompt conventions in `tools/art/README.md` (single row of idle poses, flat magenta background,
   3/4 view facing right, held items at or below head height).
