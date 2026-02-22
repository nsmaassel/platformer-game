"""
Procedural Sprite Generator for Nick's Platformer
===================================================
100% procedural Python + Pillow — no external art assets, no AI.
Every pixel is placed by code.

Generates all game sprites at native resolution:
  - Player (16×32): idle(4f), run(6f), jump(2f), fall(2f), hurt(3f)
  - Slime enemy (16×16): walk(4f), squish(2f)
  - Coin (16×16): idle(6f), collect(4f)
  - Goal flag (16×32): idle(2f)
  - Ground tiles (16×16): grass_top, dirt, grass_left, grass_right
  - Platform tiles (16×16): wood_left, wood_mid, wood_right
  - Background elements (16×16): cloud_left, cloud_right, bush

Output: assets/sprites/{entity}/{animation}_{frame}.png
Also: sprites-review.png contact sheet in repo root

Usage:
  pip install Pillow
  python generate-sprites.py
"""

import math
import os
from pathlib import Path
from PIL import Image, ImageDraw

# ─── Palette ────────────────────────────────────────────────────────
# Consistent 16-color palette, retro-inspired
PAL = {
    # Player
    "skin": (255, 206, 158),
    "skin_shadow": (214, 160, 112),
    "hair": (92, 56, 40),
    "shirt": (66, 133, 244),
    "shirt_shadow": (45, 98, 186),
    "pants": (50, 60, 80),
    "pants_shadow": (35, 42, 56),
    "shoes": (140, 60, 40),
    "eye": (40, 40, 40),
    "eye_hurt": (200, 60, 60),
    "white": (255, 255, 255),
    # Slime
    "slime": (100, 200, 80),
    "slime_shadow": (60, 150, 50),
    "slime_dark": (40, 110, 30),
    "slime_highlight": (160, 230, 140),
    "slime_eye": (255, 255, 255),
    "slime_pupil": (40, 40, 40),
    # Coin
    "gold": (255, 210, 60),
    "gold_light": (255, 240, 140),
    "gold_shadow": (200, 150, 30),
    "gold_dark": (160, 110, 20),
    # Environment
    "grass": (80, 180, 60),
    "grass_light": (120, 210, 80),
    "grass_dark": (50, 130, 40),
    "dirt": (160, 110, 60),
    "dirt_shadow": (120, 80, 40),
    "dirt_dark": (90, 60, 30),
    "wood": (180, 130, 70),
    "wood_light": (210, 160, 100),
    "wood_shadow": (130, 90, 50),
    "stone": (140, 140, 150),
    "stone_shadow": (100, 100, 110),
    # Goal
    "flag_red": (220, 50, 50),
    "flag_red_shadow": (170, 30, 30),
    "pole": (180, 180, 190),
    "pole_shadow": (130, 130, 140),
    # Sky / BG
    "cloud": (240, 240, 255),
    "cloud_shadow": (210, 215, 235),
    "bush_green": (60, 140, 50),
    "bush_light": (90, 170, 70),
    "bush_dark": (40, 100, 35),
    # UI
    "transparent": (0, 0, 0, 0),
}

OUT_DIR = Path("assets/sprites")
REVIEW_PATH = Path("sprites-review.png")


def px(img: Image.Image, x: int, y: int, color: tuple):
    """Draw a single pixel, bounds-checked."""
    if 0 <= x < img.width and 0 <= y < img.height:
        img.putpixel((x, y), color)


def rect(img: Image.Image, x: int, y: int, w: int, h: int, color: tuple):
    """Draw a filled rectangle."""
    if w <= 0 or h <= 0:
        return
    draw = ImageDraw.Draw(img)
    draw.rectangle([x, y, x + w - 1, y + h - 1], fill=color)


def ellipse(img: Image.Image, x: int, y: int, w: int, h: int, color: tuple):
    """Draw a filled ellipse."""
    draw = ImageDraw.Draw(img)
    draw.ellipse([x, y, x + w - 1, y + h - 1], fill=color)


# ─── Player (16×32) ────────────────────────────────────────────────
def draw_player_body(img: Image.Image, frame: int, anim: str):
    """Draw the player character body (no face yet)."""
    # Animation offsets
    bounce = 0
    lean = 0
    leg_phase = 0
    arm_swing = 0
    squash_y = 0

    if anim == "idle":
        bounce = [0, -1, 0, 0][frame % 4]
    elif anim == "run":
        bounce = [0, -1, -1, 0, 1, 0][frame % 6]
        leg_phase = frame % 6
        arm_swing = [0, 1, 2, 1, 0, -1][frame % 6]
        lean = 1
    elif anim == "jump":
        bounce = [-2, -1][frame % 2]
        squash_y = -1
    elif anim == "fall":
        bounce = [1, 2][frame % 2]
        squash_y = 1
    elif anim == "hurt":
        bounce = [0, -1, 0][frame % 3]
        lean = [-1, 1, 0][frame % 3]

    by = 8 + bounce  # base y for head top

    # Hair (top of head)
    rect(img, 4 + lean, by, 8, 3, PAL["hair"])
    rect(img, 3 + lean, by + 1, 1, 3, PAL["hair"])  # left sideburn
    rect(img, 12 + lean, by + 1, 1, 3, PAL["hair"])  # right sideburn

    # Head (skin)
    rect(img, 4 + lean, by + 3, 8, 6, PAL["skin"])
    rect(img, 3 + lean, by + 4, 1, 3, PAL["skin_shadow"])  # left cheek shadow
    rect(img, 12 + lean, by + 4, 1, 3, PAL["skin_shadow"])  # right cheek shadow

    # Eyes
    eye_color = PAL["eye_hurt"] if anim == "hurt" else PAL["eye"]
    if anim == "hurt":
        # X eyes
        px(img, 6 + lean, by + 5, eye_color)
        px(img, 8 + lean, by + 5, eye_color)
        px(img, 7 + lean, by + 4, eye_color)
        px(img, 7 + lean, by + 6, eye_color)
        px(img, 9 + lean, by + 5, eye_color)
        px(img, 11 + lean, by + 5, eye_color)
        px(img, 10 + lean, by + 4, eye_color)
        px(img, 10 + lean, by + 6, eye_color)
    else:
        # Normal eyes — 2px apart
        px(img, 6 + lean, by + 5, eye_color)
        px(img, 6 + lean, by + 4, eye_color)
        px(img, 10 + lean, by + 5, eye_color)
        px(img, 10 + lean, by + 4, eye_color)
        # Highlights
        px(img, 6 + lean, by + 4, PAL["white"])
        px(img, 10 + lean, by + 4, PAL["white"])

    # Torso (shirt)
    torso_y = by + 9
    rect(img, 4 + lean, torso_y, 8, 7 + squash_y, PAL["shirt"])
    rect(img, 4 + lean, torso_y, 2, 7 + squash_y, PAL["shirt_shadow"])  # left shadow

    # Arms
    arm_y = torso_y + 1
    if anim == "run":
        # Swinging arms
        rect(img, 2 + lean, arm_y + arm_swing, 2, 5, PAL["shirt"])
        rect(img, 12 + lean, arm_y - arm_swing, 2, 5, PAL["shirt"])
        # Hands
        px(img, 2 + lean, arm_y + arm_swing + 5, PAL["skin"])
        px(img, 3 + lean, arm_y + arm_swing + 5, PAL["skin"])
        px(img, 12 + lean, arm_y - arm_swing + 5, PAL["skin"])
        px(img, 13 + lean, arm_y - arm_swing + 5, PAL["skin"])
    elif anim == "jump":
        # Arms up
        rect(img, 2, arm_y - 2, 2, 4, PAL["shirt"])
        rect(img, 12, arm_y - 2, 2, 4, PAL["shirt"])
        px(img, 2, arm_y - 3, PAL["skin"])
        px(img, 3, arm_y - 3, PAL["skin"])
        px(img, 12, arm_y - 3, PAL["skin"])
        px(img, 13, arm_y - 3, PAL["skin"])
    elif anim == "hurt":
        # Arms flail
        rect(img, 1 + lean, arm_y - 1, 2, 4, PAL["shirt"])
        rect(img, 13 + lean, arm_y + 1, 2, 4, PAL["shirt"])
    else:
        # Resting arms
        rect(img, 2 + lean, arm_y, 2, 5, PAL["shirt"])
        rect(img, 12 + lean, arm_y, 2, 5, PAL["shirt"])
        px(img, 2 + lean, arm_y + 5, PAL["skin"])
        px(img, 3 + lean, arm_y + 5, PAL["skin"])
        px(img, 12 + lean, arm_y + 5, PAL["skin"])
        px(img, 13 + lean, arm_y + 5, PAL["skin"])

    # Pants
    pants_y = torso_y + 7 + squash_y
    rect(img, 4 + lean, pants_y, 8, 4, PAL["pants"])
    rect(img, 4 + lean, pants_y, 2, 4, PAL["pants_shadow"])

    # Legs
    leg_y = pants_y + 4
    if anim == "run":
        # Alternating leg positions
        offsets = [
            (0, 0, 3, -1),   # left_x, right_x, left_extend, right_extend
            (1, -1, 2, 0),
            (2, -2, 1, 1),
            (1, -1, 0, 2),
            (0, 0, -1, 3),
            (-1, 1, 0, 2),
        ]
        lo = offsets[leg_phase]
        # Left leg
        rect(img, 4 + lean + lo[0], leg_y, 3, 4 + lo[2], PAL["pants"])
        rect(img, 4 + lean + lo[0], leg_y + 3 + lo[2], 4, 2, PAL["shoes"])
        # Right leg
        rect(img, 9 + lean + lo[1], leg_y, 3, 4 + lo[3], PAL["pants"])
        rect(img, 9 + lean + lo[1], leg_y + 3 + lo[3], 4, 2, PAL["shoes"])
    elif anim == "jump":
        # Legs tucked
        rect(img, 4, leg_y - 1, 3, 3, PAL["pants"])
        rect(img, 9, leg_y - 1, 3, 3, PAL["pants"])
        rect(img, 4, leg_y + 2, 4, 2, PAL["shoes"])
        rect(img, 9, leg_y + 2, 4, 2, PAL["shoes"])
    elif anim == "fall":
        # Legs dangling apart
        rect(img, 3, leg_y, 3, 5, PAL["pants"])
        rect(img, 10, leg_y, 3, 5, PAL["pants"])
        rect(img, 3, leg_y + 5, 4, 2, PAL["shoes"])
        rect(img, 10, leg_y + 5, 4, 2, PAL["shoes"])
    else:
        # Standing
        rect(img, 4 + lean, leg_y, 3, 4, PAL["pants"])
        rect(img, 9 + lean, leg_y, 3, 4, PAL["pants"])
        rect(img, 4 + lean, leg_y + 4, 4, 2, PAL["shoes"])
        rect(img, 9 + lean, leg_y + 4, 4, 2, PAL["shoes"])


def generate_player():
    """Generate all player animation frames."""
    anims = {
        "idle": 4,
        "run": 6,
        "jump": 2,
        "fall": 2,
        "hurt": 3,
    }
    frames = {}
    for anim_name, frame_count in anims.items():
        frames[anim_name] = []
        for f in range(frame_count):
            img = Image.new("RGBA", (16, 32), PAL["transparent"])
            draw_player_body(img, f, anim_name)
            frames[anim_name].append(img)
            save_frame("player", anim_name, f, img)
    return frames


# ─── Slime (16×16) ─────────────────────────────────────────────────
def draw_slime(img: Image.Image, frame: int, anim: str):
    """Draw the slime enemy."""
    if anim == "walk":
        # Hop cycle: squish down, normal, stretch up, normal
        squash = [0, -1, -2, -1][frame % 4]
        stretch = [0, 1, 2, 1][frame % 4]
        bounce = [0, 0, -2, -1][frame % 4]
    else:  # squish (death)
        squash = [3, 5][frame % 2]
        stretch = [-2, -4][frame % 2]
        bounce = [0, 2][frame % 2]

    base_y = 10 + bounce
    body_h = 6 - squash + stretch

    # Shadow on ground
    ellipse(img, 3, 13, 10, 3, (0, 0, 0, 40))

    # Body (blobby shape)
    # Main mass
    body_top = base_y - body_h
    rect(img, 3, body_top + 1, 10, body_h - 1, PAL["slime"])
    rect(img, 4, body_top, 8, body_h, PAL["slime"])
    # Rounded top
    rect(img, 5, body_top - 1, 6, 1, PAL["slime"])

    # Highlight
    rect(img, 5, body_top, 3, 2, PAL["slime_highlight"])

    # Shadow at base
    rect(img, 3, base_y - 2, 10, 2, PAL["slime_shadow"])
    rect(img, 4, base_y, 8, 1, PAL["slime_dark"])

    # Eyes (only if not squished dead)
    if anim != "squish" or frame == 0:
        eye_y = body_top + max(body_h // 3, 1)
        # Left eye
        rect(img, 5, eye_y, 2, 2, PAL["slime_eye"])
        px(img, 5, eye_y + 1, PAL["slime_pupil"])
        # Right eye
        rect(img, 9, eye_y, 2, 2, PAL["slime_eye"])
        px(img, 9, eye_y + 1, PAL["slime_pupil"])


def generate_slime():
    """Generate all slime animation frames."""
    anims = {"walk": 4, "squish": 2}
    frames = {}
    for anim_name, frame_count in anims.items():
        frames[anim_name] = []
        for f in range(frame_count):
            img = Image.new("RGBA", (16, 16), PAL["transparent"])
            draw_slime(img, f, anim_name)
            frames[anim_name].append(img)
            save_frame("slime", anim_name, f, img)
    return frames


# ─── Coin (16×16) ──────────────────────────────────────────────────
def draw_coin(img: Image.Image, frame: int, anim: str):
    """Draw a spinning coin."""
    if anim == "idle":
        # Pseudo-3D rotation — width changes over 6 frames
        widths = [8, 7, 4, 2, 4, 7]
        w = widths[frame % 6]
        cx = 8
        x0 = cx - w // 2
        # Coin body
        ellipse(img, x0, 3, w, 10, PAL["gold"])
        if w > 3:
            ellipse(img, x0 + 1, 4, w - 2, 8, PAL["gold_light"])
            # Dollar sign or dot in center
            if w > 5:
                rect(img, cx - 1, 6, 2, 4, PAL["gold_shadow"])
        # Shine
        if w > 4:
            px(img, x0 + 1, 5, PAL["white"])
    elif anim == "collect":
        # Shrink + rise + sparkle
        rise = frame * 2
        size = max(8 - frame * 2, 2)
        cx, cy = 8, 8 - rise
        x0 = cx - size // 2
        y0 = cy - size // 2
        ellipse(img, x0, y0, size, size, PAL["gold_light"])
        # Sparkle particles
        for angle_offset in range(4):
            a = (frame * 0.8 + angle_offset * 1.57)
            sx = int(cx + math.cos(a) * (4 + frame))
            sy = int(cy + math.sin(a) * (4 + frame))
            px(img, sx, sy, PAL["gold"])


def generate_coin():
    """Generate all coin animation frames."""
    anims = {"idle": 6, "collect": 4}
    frames = {}
    for anim_name, frame_count in anims.items():
        frames[anim_name] = []
        for f in range(frame_count):
            img = Image.new("RGBA", (16, 16), PAL["transparent"])
            draw_coin(img, f, anim_name)
            frames[anim_name].append(img)
            save_frame("coin", anim_name, f, img)
    return frames


# ─── Goal Flag (16×32) ─────────────────────────────────────────────
def draw_goal(img: Image.Image, frame: int, anim: str):
    """Draw a flag on a pole."""
    wave = frame % 2

    # Pole
    rect(img, 7, 2, 2, 28, PAL["pole"])
    rect(img, 7, 2, 1, 28, PAL["pole_shadow"])

    # Pole top ball
    rect(img, 6, 1, 4, 2, PAL["gold"])
    px(img, 7, 0, PAL["gold_light"])

    # Flag (waves)
    flag_y = 4
    for row in range(8):
        wave_offset = (1 if (row + wave) % 3 == 0 else 0)
        flag_w = max(7 - row // 3, 4)
        color = PAL["flag_red"] if (row + wave) % 4 < 2 else PAL["flag_red_shadow"]
        rect(img, 9 + wave_offset, flag_y + row, flag_w, 1, color)

    # Pole base
    rect(img, 5, 28, 6, 2, PAL["stone"])
    rect(img, 6, 30, 4, 2, PAL["stone_shadow"])


def generate_goal():
    """Generate goal flag frames."""
    frames = {"idle": []}
    for f in range(2):
        img = Image.new("RGBA", (16, 32), PAL["transparent"])
        draw_goal(img, f, "idle")
        frames["idle"].append(img)
        save_frame("goal", "idle", f, img)
    return frames


# ─── Tiles (16×16) ─────────────────────────────────────────────────
def generate_tiles():
    """Generate tileset pieces."""
    tiles = {}

    # Grass top
    img = Image.new("RGBA", (16, 16), PAL["dirt"])
    rect(img, 0, 0, 16, 4, PAL["grass"])
    rect(img, 0, 0, 16, 2, PAL["grass_light"])
    # Grass tufts on top edge
    for x in [1, 4, 7, 11, 14]:
        px(img, x, 0, PAL["grass_light"])
    # Dirt texture
    for pos in [(3, 7), (8, 9), (12, 6), (5, 12), (10, 14), (2, 10)]:
        px(img, pos[0], pos[1], PAL["dirt_shadow"])
    tiles["grass_top"] = img
    save_tile("tiles", "grass_top", img)

    # Dirt (solid fill)
    img = Image.new("RGBA", (16, 16), PAL["dirt"])
    rect(img, 0, 0, 16, 16, PAL["dirt"])
    for pos in [(3, 3), (8, 5), (12, 2), (5, 8), (1, 12), (10, 10), (14, 7), (7, 14), (4, 1), (11, 13)]:
        px(img, pos[0], pos[1], PAL["dirt_shadow"])
    for pos in [(6, 4), (13, 9), (2, 7)]:
        px(img, pos[0], pos[1], PAL["dirt_dark"])
    tiles["dirt"] = img
    save_tile("tiles", "dirt", img)

    # Grass left edge
    img = Image.new("RGBA", (16, 16), PAL["dirt"])
    rect(img, 0, 0, 4, 16, PAL["grass_dark"])
    rect(img, 0, 0, 2, 16, PAL["grass"])
    for pos in [(6, 4), (10, 8), (8, 12), (12, 3)]:
        px(img, pos[0], pos[1], PAL["dirt_shadow"])
    tiles["grass_left"] = img
    save_tile("tiles", "grass_left", img)

    # Grass right edge
    img = Image.new("RGBA", (16, 16), PAL["dirt"])
    rect(img, 12, 0, 4, 16, PAL["grass_dark"])
    rect(img, 14, 0, 2, 16, PAL["grass"])
    for pos in [(3, 5), (6, 9), (8, 2), (4, 13)]:
        px(img, pos[0], pos[1], PAL["dirt_shadow"])
    tiles["grass_right"] = img
    save_tile("tiles", "grass_right", img)

    # Wood platform (left end)
    img = Image.new("RGBA", (16, 16), PAL["wood"])
    rect(img, 0, 0, 16, 2, PAL["wood_light"])  # top highlight
    rect(img, 0, 14, 16, 2, PAL["wood_shadow"])  # bottom shadow
    rect(img, 0, 0, 2, 16, PAL["wood_shadow"])  # left edge
    # Wood grain lines
    for y in [5, 10]:
        rect(img, 2, y, 14, 1, PAL["wood_shadow"])
    tiles["wood_left"] = img
    save_tile("tiles", "wood_left", img)

    # Wood platform (middle)
    img = Image.new("RGBA", (16, 16), PAL["wood"])
    rect(img, 0, 0, 16, 2, PAL["wood_light"])
    rect(img, 0, 14, 16, 2, PAL["wood_shadow"])
    for y in [5, 10]:
        rect(img, 0, y, 16, 1, PAL["wood_shadow"])
    # Knot
    px(img, 8, 7, PAL["wood_shadow"])
    px(img, 9, 7, PAL["wood_shadow"])
    px(img, 8, 8, PAL["wood_shadow"])
    tiles["wood_mid"] = img
    save_tile("tiles", "wood_mid", img)

    # Wood platform (right end)
    img = Image.new("RGBA", (16, 16), PAL["wood"])
    rect(img, 0, 0, 16, 2, PAL["wood_light"])
    rect(img, 0, 14, 16, 2, PAL["wood_shadow"])
    rect(img, 14, 0, 2, 16, PAL["wood_shadow"])  # right edge
    for y in [5, 10]:
        rect(img, 0, y, 14, 1, PAL["wood_shadow"])
    tiles["wood_right"] = img
    save_tile("tiles", "wood_right", img)

    return tiles


# ─── Background elements (16×16) ───────────────────────────────────
def generate_bg():
    """Generate background decoration sprites."""
    bgs = {}

    # Cloud left half
    img = Image.new("RGBA", (16, 16), PAL["transparent"])
    ellipse(img, 2, 6, 12, 8, PAL["cloud"])
    ellipse(img, 4, 3, 8, 6, PAL["cloud"])
    rect(img, 12, 6, 4, 6, PAL["cloud"])  # extend right for seamless join
    # Shadow
    ellipse(img, 3, 9, 10, 5, PAL["cloud_shadow"])
    bgs["cloud_left"] = img
    save_tile("bg", "cloud_left", img)

    # Cloud right half
    img = Image.new("RGBA", (16, 16), PAL["transparent"])
    rect(img, 0, 6, 4, 6, PAL["cloud"])  # extend left for seamless join
    ellipse(img, 2, 6, 12, 8, PAL["cloud"])
    ellipse(img, 5, 4, 8, 6, PAL["cloud"])
    ellipse(img, 3, 9, 10, 5, PAL["cloud_shadow"])
    bgs["cloud_right"] = img
    save_tile("bg", "cloud_right", img)

    # Bush
    img = Image.new("RGBA", (16, 16), PAL["transparent"])
    ellipse(img, 1, 6, 14, 10, PAL["bush_green"])
    ellipse(img, 3, 4, 10, 8, PAL["bush_green"])
    ellipse(img, 2, 3, 6, 6, PAL["bush_light"])
    ellipse(img, 2, 10, 12, 6, PAL["bush_dark"])
    bgs["bush"] = img
    save_tile("bg", "bush", img)

    return bgs


# ─── I/O helpers ───────────────────────────────────────────────────
def save_frame(entity: str, anim: str, frame: int, img: Image.Image):
    """Save a single animation frame PNG."""
    path = OUT_DIR / entity / f"{anim}_{frame}.png"
    path.parent.mkdir(parents=True, exist_ok=True)
    img.save(path)


def save_tile(entity: str, name: str, img: Image.Image):
    """Save a single tile PNG."""
    path = OUT_DIR / entity / f"{name}.png"
    path.parent.mkdir(parents=True, exist_ok=True)
    img.save(path)


# ─── Contact Sheet ─────────────────────────────────────────────────
def generate_contact_sheet(all_sprites: dict):
    """
    Generate a review contact sheet: rows = entities, columns = frames.
    Each sprite is scaled 4x for visibility.
    """
    SCALE = 4
    PADDING = 2
    LABEL_SPACE = 0  # No text labels (Pillow default font is tiny)

    # Flatten: list of (entity, anim, frames_list)
    rows = []
    for entity, anims in all_sprites.items():
        for anim_name, frame_list in anims.items():
            rows.append((entity, anim_name, frame_list))

    if not rows:
        return

    max_frames = max(len(r[2]) for r in rows)
    # All sprites could be different sizes; use max dims
    max_w = max(f.width for _, _, fl in rows for f in fl)
    max_h = max(f.height for _, _, fl in rows for f in fl)

    cell_w = max_w * SCALE + PADDING
    cell_h = max_h * SCALE + PADDING

    sheet_w = max_frames * cell_w + PADDING
    sheet_h = len(rows) * cell_h + PADDING

    sheet = Image.new("RGBA", (sheet_w, sheet_h), (30, 30, 40, 255))

    for row_i, (entity, anim_name, frame_list) in enumerate(rows):
        for col_i, frame_img in enumerate(frame_list):
            scaled = frame_img.resize(
                (frame_img.width * SCALE, frame_img.height * SCALE),
                Image.NEAREST,
            )
            x = PADDING + col_i * cell_w
            y = PADDING + row_i * cell_h
            sheet.paste(scaled, (x, y), scaled)

    sheet.save(REVIEW_PATH)
    print(f"  📋 Contact sheet: {REVIEW_PATH} ({sheet_w}×{sheet_h})")


# ─── Main ──────────────────────────────────────────────────────────
def main():
    print("🎨 Generating sprites for Nick's Platformer...")
    print(f"   Output: {OUT_DIR}/")
    print()

    all_sprites = {}
    total = 0

    print("  👤 Player (16×32)...")
    all_sprites["player"] = generate_player()
    count = sum(len(f) for f in all_sprites["player"].values())
    total += count
    print(f"     → {count} frames")

    print("  🟢 Slime (16×16)...")
    all_sprites["slime"] = generate_slime()
    count = sum(len(f) for f in all_sprites["slime"].values())
    total += count
    print(f"     → {count} frames")

    print("  🪙 Coin (16×16)...")
    all_sprites["coin"] = generate_coin()
    count = sum(len(f) for f in all_sprites["coin"].values())
    total += count
    print(f"     → {count} frames")

    print("  🚩 Goal flag (16×32)...")
    all_sprites["goal"] = generate_goal()
    count = sum(len(f) for f in all_sprites["goal"].values())
    total += count
    print(f"     → {count} frames")

    print("  🧱 Tiles (16×16)...")
    tile_imgs = generate_tiles()
    all_sprites["tiles"] = {name: [img] for name, img in tile_imgs.items()}
    total += len(tile_imgs)
    print(f"     → {len(tile_imgs)} tiles")

    print("  ☁️  Background (16×16)...")
    bg_imgs = generate_bg()
    all_sprites["bg"] = {name: [img] for name, img in bg_imgs.items()}
    total += len(bg_imgs)
    print(f"     → {len(bg_imgs)} elements")

    print()
    print(f"  ✅ Total: {total} PNG files in {OUT_DIR}/")
    print()

    generate_contact_sheet(all_sprites)
    print()
    print("  Done! Open sprites-review.png to preview all sprites at 4× zoom.")


if __name__ == "__main__":
    main()
