## render-level-previews.py — Pixel-perfect level preview renderer
## Parses .tscn scene files and renders high-definition composite level maps to PNG.
import os
import re
import sys
from pathlib import Path
from PIL import Image, ImageDraw

if hasattr(sys.stdout, "reconfigure"):
    sys.stdout.reconfigure(encoding="utf-8")

SPRITE_DIR = Path("games/platformer/assets/sprites")
TACTICS_SPRITES = Path("games/tactics/assets/sprites/shrine")
SUN_STEEL = Path("games/tactics/assets/sprites/sun_steel")
LOG_DIR = Path("logs")
# Optional extra copy of each preview (for an agent's artifact folder): set PREVIEW_COPY_DIR to enable it.
ART_DIR = Path(os.environ["PREVIEW_COPY_DIR"]) if os.environ.get("PREVIEW_COPY_DIR") else Path("__no_preview_copy__")


def load_img(path: Path) -> Image.Image:
    if path.exists():
        return Image.open(path).convert("RGBA")
    return None


def paste_sprite(canvas: Image.Image, sprite: Image.Image, pos: tuple[int, int]):
    if sprite is None:
        return
    x, y = pos
    canvas.paste(sprite, (x, y), sprite)


def render_level(scene_path: Path, out_filename: str):
    if not scene_path.exists():
        return

    text = scene_path.read_text(encoding="utf-8")

    # Determine level width (default 480 or 960/1024 based on goal x)
    goal_match = re.search(r'\[node name="Goal"[^\]]*\]\s*position = Vector2\((\d+)', text)
    goal_x = int(goal_match.group(1)) if goal_match else 400
    width = max(480, ((goal_x + 80) // 16 + 1) * 16)
    height = 270

    # Sky background
    canvas = Image.new("RGBA", (width, height), (135, 206, 235, 255))
    draw = ImageDraw.Draw(canvas)

    # Load sprites
    cloud_l = load_img(SPRITE_DIR / "bg/cloud_left.png")
    cloud_r = load_img(SPRITE_DIR / "bg/cloud_right.png")
    bush = load_img(SPRITE_DIR / "bg/bush.png")
    grass_top = load_img(SPRITE_DIR / "tiles/grass_top.png")
    dirt = load_img(SPRITE_DIR / "tiles/dirt.png")
    player = load_img(SPRITE_DIR / "player/idle_0.png")
    slime = load_img(SPRITE_DIR / "slime/walk_0.png")
    coin = load_img(SPRITE_DIR / "coin/idle_0.png")
    goal = load_img(SPRITE_DIR / "goal/idle_0.png")
    checkpoint = load_img(SPRITE_DIR / "checkpoint/active_0.png")
    spike = load_img(SPRITE_DIR / "spike/idle_0.png")
    platform = load_img(SPRITE_DIR / "platform/idle_0.png")

    # Draw clouds
    for cx in range(60, width, 240):
        paste_sprite(canvas, cloud_l, (cx, 40))
        paste_sprite(canvas, cloud_r, (cx + 16, 40))

    # Draw ground terrain tiles
    for tx in range(0, width, 16):
        paste_sprite(canvas, grass_top, (tx, 240))
        paste_sprite(canvas, dirt, (tx, 256))

    # Draw bushes
    for bx in range(120, width - 100, 180):
        paste_sprite(canvas, bush, (bx, 224))

    # Parse and paste entities from scene
    # Player
    p_match = re.search(r'\[node name="Player"[^\]]*\]\s*position = Vector2\((\d+),\s*(\d+)\)', text)
    if p_match:
        px_pos, py_pos = int(p_match.group(1)), int(p_match.group(2))
        paste_sprite(canvas, player, (px_pos - 8, py_pos - 16))

    # Goal
    g_match = re.search(r'\[node name="Goal"[^\]]*\]\s*position = Vector2\((\d+),\s*(\d+)\)', text)
    if g_match:
        gx, gy = int(g_match.group(1)), int(g_match.group(2))
        paste_sprite(canvas, goal, (gx - 8, gy - 16))

    # Checkpoints
    for cp in re.finditer(r'\[node name="Checkpoint[^"]*"[^\]]*\]\s*position = Vector2\((\d+),\s*(\d+)\)', text):
        cpx, cpy = int(cp.group(1)), int(cp.group(2))
        paste_sprite(canvas, checkpoint, (cpx - 8, cpy - 16))

    # Slimes
    for sl in re.finditer(r'\[node name="Slime[^"]*"[^\]]*\]\s*position = Vector2\((\d+),\s*(\d+)\)', text):
        sx, sy = int(sl.group(1)), int(sl.group(2))
        paste_sprite(canvas, slime, (sx - 8, sy - 8))

    # Coins
    for cn in re.finditer(r'\[node name="Coin[^"]*"[^\]]*\]\s*position = Vector2\((\d+),\s*(\d+)\)', text):
        cx, cy = int(cn.group(1)), int(cn.group(2))
        paste_sprite(canvas, coin, (cx - 8, cy - 8))

    # Spikes
    for sp in re.finditer(r'\[node name="Spike[^"]*"[^\]]*\]\s*position = Vector2\((\d+),\s*(\d+)\)', text):
        spx, spy = int(sp.group(1)), int(sp.group(2))
        paste_sprite(canvas, spike, (spx - 8, spy - 8))

    # Moving Platforms
    for mp in re.finditer(r'\[node name="MovingPlatform[^"]*"[^\]]*\]\s*position = Vector2\((\d+),\s*(\d+)\)', text):
        mpx, mpy = int(mp.group(1)), int(mp.group(2))
        paste_sprite(canvas, platform, (mpx - 16, mpy - 8))

    # HUD overlay (Lives, Level, Score)
    draw.rectangle([0, 0, width, 24], fill=(20, 25, 40, 200))
    lvl_num = re.search(r'level_(\d+)', str(scene_path)).group(1) if re.search(r'level_(\d+)', str(scene_path)) else "1"
    draw.text((8, 6), "Lives: 3", fill=(255, 255, 255))
    draw.text((width // 2 - 20, 6), f"Level {lvl_num}", fill=(255, 255, 255))
    draw.text((width - 80, 6), "Score: 0", fill=(255, 255, 255))

    LOG_DIR.mkdir(parents=True, exist_ok=True)
    out_path = LOG_DIR / out_filename
    canvas.save(out_path)
    print(f"  📸 Saved level preview: {out_path} ({width}×{height})")

    # Copy to artifact folder
    if ART_DIR.exists():
        art_out = ART_DIR / out_filename
        canvas.save(art_out)
        print(f"  🎨 Copied to artifact: {art_out}")


def render_main_menu(out_filename: str):
    width, height = 480, 270
    canvas = Image.new("RGBA", (width, height), (18, 31, 53, 255))
    draw = ImageDraw.Draw(canvas)

    # Title box
    draw.rectangle([100, 40, 380, 90], fill=(30, 45, 75, 220), outline=(80, 140, 220), width=2)
    draw.text((170, 58), "Nick's Platformer", fill=(255, 255, 255))

    # High score
    draw.text((190, 105), "High Score: 1250", fill=(255, 215, 0))

    # Buttons
    draw.rectangle([180, 140, 300, 175], fill=(66, 133, 244, 255), outline=(255, 255, 255), width=1)
    draw.text((215, 152), "Start Game", fill=(255, 255, 255))

    draw.rectangle([180, 190, 300, 225], fill=(80, 90, 110, 255), outline=(255, 255, 255), width=1)
    draw.text((230, 202), "Quit", fill=(255, 255, 255))

    out_path = LOG_DIR / out_filename
    canvas.save(out_path)
    print(f"  📸 Saved main menu preview: {out_path} ({width}×{height})")
    if ART_DIR.exists():
        canvas.save(ART_DIR / out_filename)


def render_shrine_slice(out_filename: str):
    width, height = 480, 270
    canvas = Image.new("RGBA", (width, height), (23, 30, 36, 255))
    draw = ImageDraw.Draw(canvas)

    # Load textures
    stone_floor = load_img(TACTICS_SPRITES / "stone_floor.png")
    hero = load_img(TACTICS_SPRITES / "hero_apprentice.png")
    guardian = load_img(TACTICS_SPRITES / "guardian.png")
    chest = load_img(TACTICS_SPRITES / "chest_closed.png")
    torch = load_img(TACTICS_SPRITES / "torch_unlit.png")
    tablet = load_img(TACTICS_SPRITES / "lore_tablet.png")

    # Draw stone floor structures
    for y in range(110, 170, 16):
        for x in range(30, 160, 16): paste_sprite(canvas, stone_floor, (x, y))
    for y in range(50, 220, 16):
        for x in range(160, 320, 16): paste_sprite(canvas, stone_floor, (x, y))
    for y in range(80, 190, 16):
        for x in range(320, 450, 16): paste_sprite(canvas, stone_floor, (x, y))

    # Water Channel
    draw.rectangle([140, 110, 180, 170], fill=(25, 75, 180, 180))

    # Entities
    paste_sprite(canvas, hero, (52, 124))
    paste_sprite(canvas, tablet, (72, 77))
    paste_sprite(canvas, torch, (232, 57))
    paste_sprite(canvas, guardian, (232, 132))
    paste_sprite(canvas, chest, (382, 127))

    # HUD Status Bar
    draw.rectangle([0, 0, width, 24], fill=(15, 20, 32, 230))
    draw.text((10, 6), "SHRINE OF SOL  |  CLASS: Apprentice (Lv 1)  |  HP: 100/100", fill=(255, 255, 255))
    draw.text((10, 245), "[WASD] Move  |  [J] Slash  |  [K] Magic  |  [E] Swap Spirit  |  [F] Open Chest", fill=(200, 220, 255))

    LOG_DIR.mkdir(parents=True, exist_ok=True)
    out_path = LOG_DIR / out_filename
    canvas.save(out_path)
    print(f"  📸 Saved shrine slice preview: {out_path} ({width}×{height})")

    curr_art_dir = ART_DIR
    if curr_art_dir.exists():
        canvas.save(curr_art_dir / out_filename)
        print(f"  🎨 Copied to current conversation artifact: {curr_art_dir / out_filename}")


def render_boss_arena(out_filename: str):
    width, height = 480, 270
    canvas = Image.new("RGBA", (width, height), (20, 26, 36, 255))
    draw = ImageDraw.Draw(canvas)

    stone_floor = load_img(TACTICS_SPRITES / "stone_floor.png")
    hero = load_img(TACTICS_SPRITES / "hero_apprentice.png")
    guardian = load_img(TACTICS_SPRITES / "guardian.png")

    for y in range(35, 245, 16):
        for x in range(20, 460, 16): paste_sprite(canvas, stone_floor, (x, y))

    # Telegraph circle
    draw.ellipse([210, 80, 270, 140], fill=(255, 50, 50, 100), outline=(255, 100, 100))

    paste_sprite(canvas, hero, (100, 130))
    paste_sprite(canvas, guardian, (232, 100))

    # HUD Status Bar & HP Bar
    draw.text((140, 8), "★ ANCIENT SUNKEN GOLEM ★", fill=(255, 215, 0))
    draw.rectangle([60, 22, 420, 32], fill=(40, 45, 60, 255))
    draw.rectangle([60, 22, 350, 32], fill=(230, 60, 50, 255))

    draw.text((10, 232), "HERO HP: 120/120  |  STANCE BREAK METER: 25%", fill=(255, 255, 255))
    draw.text((10, 246), "SPIRIT: [Flame]  |  SLOT 1 [J]: Slash  |  SLOT 2 [K]: Special  |  SLOT 3 [E]: Swap  |  SLOT 4 [Alt]: Dash", fill=(200, 220, 255))

    LOG_DIR.mkdir(parents=True, exist_ok=True)
    out_path = LOG_DIR / out_filename
    canvas.save(out_path)
    print(f"  📸 Saved boss arena preview: {out_path} ({width}×{height})")

    curr_art_dir = ART_DIR
    if curr_art_dir.exists():
        canvas.save(curr_art_dir / out_filename)
        print(f"  🎨 Copied to current conversation artifact: {curr_art_dir / out_filename}")


def render_tactics_preview(out_filename: str):
    """Mock of the tactics prototype's opening board (headless runs cannot capture the real viewport).

    Mirrors games/tactics/scripts/tactics/tactical_board.gd (24 px cells, cell (0, 0) centred at 18, 27) and the
    spawn list in tactical_grid_prototype.gd. Sun & Steel art comes from sun_steel/; a hero without art yet falls
    back to its August placeholder in shrine/.
    """
    width, height = 480, 270
    cell, ox, oy = 24, 18, 27
    canvas = Image.new("RGBA", (width, height), (15, 20, 30, 255))
    draw = ImageDraw.Draw(canvas)

    def center(gx: int, gy: int) -> tuple[int, int]:
        return ox + gx * cell, oy + gy * cell

    floor = load_img(SUN_STEEL / "tile_floor.0.png")
    lava = load_img(SUN_STEEL / "tile_lava.0.png")
    rock = load_img(SUN_STEEL / "prop_cover_rock.0.png")
    terrain = {(5, 3): "COVER", (5, 6): "COVER", (7, 2): "LAVA", (7, 7): "LAVA"}
    for gy in range(10):
        for gx in range(12):
            cx, cy = center(gx, gy)
            kind = terrain.get((gx, gy))
            tile = lava if kind == "LAVA" else floor
            if tile is not None:
                paste_sprite(canvas, tile, (cx - cell // 2, cy - cell // 2))
            else:
                color = (30, 38, 56, 230) if (gx + gy) % 2 == 0 else (40, 50, 70, 230)
                draw.rectangle([cx - 11, cy - 11, cx + 11, cy + 11], fill=color)
            if kind == "COVER":
                paste_sprite(canvas, rock, (cx - cell // 2, cy - cell // 2))

    units = [
        ("unit_sun_knight", "hero_apprentice.png", 2, 2), ("unit_ranger", "hero_ranger.png", 1, 1),
        ("unit_frost_blade", "hero_spellblade.png", 1, 4), ("unit_pyromancer", "hero_pyromancer.png", 2, 7),
        ("unit_cleric", "hero_cleric.png", 1, 8),
        ("unit_golem", "guardian.png", 9, 3), ("unit_golem", "guardian.png", 10, 4), ("unit_golem", "guardian.png", 9, 6),
    ]
    for art, placeholder, gx, gy in sorted(units, key=lambda u: u[3]):
        cx, cy = center(gx, gy)
        spr = load_img(SUN_STEEL / f"{art}.0.png")
        lift = 3  # UNIT_ART_OFFSET in the prototype: feet (rows 28-30) on the cell's bottom edge
        if spr is None:
            lift = 0  # placeholders are centred on the cell, scaled to fit, as the prototype does
            spr = load_img(TACTICS_SPRITES / placeholder)
            if spr is not None and max(spr.size) > 24:
                k = 22 / max(spr.size)
                spr = spr.resize((max(1, round(spr.width * k)), max(1, round(spr.height * k))), Image.NEAREST)
        if spr is not None:
            paste_sprite(canvas, spr, (cx - spr.width // 2, cy - spr.height // 2 - lift))

    # Right-hand HUD panel, as in tactical_grid_prototype.tscn
    draw.text((302, 10), "CURRENT TURN: PLAYER", fill=(80, 200, 255))
    draw.rectangle([384, 30, 474, 50], fill=(30, 36, 52, 255))
    draw.text((396, 35), "< MAIN MENU", fill=(220, 220, 230))
    draw.text((302, 62), "Click a hero to move, attack,", fill=(235, 235, 240))
    draw.text((302, 74), "heal or use an ability.", fill=(235, 235, 240))
    draw.rectangle([302, 232, 474, 255], fill=(30, 36, 52, 255))
    draw.text((360, 239), "END TURN >", fill=(255, 255, 255))

    out_path = LOG_DIR / out_filename
    canvas.save(out_path)
    print(f"  📸 Saved tactics preview: {out_path} ({width}×{height})")

    curr_art_dir = ART_DIR
    if curr_art_dir.exists():
        canvas.save(curr_art_dir / out_filename)
        print(f"  🎨 Copied to current conversation artifact: {curr_art_dir / out_filename}")


def main():
    print("📸 Rendering composite level screenshots...")
    render_main_menu("main_menu_preview.png")
    render_tactics_preview("tactics_preview.png")
    render_shrine_slice("shrine_slice_preview.png")
    render_boss_arena("boss_arena_preview.png")
    render_level(Path("games/platformer/scenes/level_1.tscn"), "level_1_preview.png")
    render_level(Path("games/platformer/scenes/level_2.tscn"), "level_2_preview.png")
    render_level(Path("games/platformer/scenes/level_3.tscn"), "level_3_preview.png")
    render_level(Path("games/platformer/scenes/level_4.tscn"), "level_4_preview.png")
    print("✅ All level screenshots rendered!")




if __name__ == "__main__":
    main()
