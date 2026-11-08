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
import sys
from pathlib import Path
from PIL import Image, ImageDraw

if hasattr(sys.stdout, "reconfigure"):
    sys.stdout.reconfigure(encoding="utf-8")


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
    # Goal & Checkpoint
    "flag_red": (220, 50, 50),
    "flag_red_shadow": (170, 30, 30),
    "flag_blue": (60, 140, 200),
    "flag_blue_shadow": (40, 100, 160),
    "flag_gold": (255, 200, 40),
    "flag_gold_shadow": (210, 150, 20),
    "flag_gold_light": (255, 240, 120),
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

OUT_DIR = Path("games/platformer/assets/sprites")
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
    ellipse(img, 4, 14, 8, 2, PAL["slime_dark"])

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


# ─── Checkpoint Flag (16×32) ───────────────────────────────────────
def draw_checkpoint(img: Image.Image, frame: int, anim: str):
    """Draw a checkpoint flag on a pole (idle = blue/grey unactivated, active = gold waving activated)."""
    wave = frame % 4 if anim == "active" else frame % 2

    # Pole
    rect(img, 7, 4, 2, 24, PAL["pole"])
    rect(img, 7, 4, 1, 24, PAL["pole_shadow"])

    # Pole top ball
    top_color = PAL["flag_gold_light"] if anim == "active" else PAL["stone"]
    rect(img, 6, 2, 4, 2, top_color)
    px(img, 7, 1, PAL["white"] if anim == "active" else PAL["stone"])

    # Flag
    flag_y = 5
    for row in range(7):
        wave_offset = (1 if (row + wave) % 3 == 0 else 0)
        flag_w = max(7 - row // 3, 4)
        if anim == "active":
            color = PAL["flag_gold"] if (row + wave) % 3 < 2 else PAL["flag_gold_shadow"]
        else:
            color = PAL["flag_blue"] if (row + wave) % 2 == 0 else PAL["flag_blue_shadow"]
        rect(img, 9 + wave_offset, flag_y + row, flag_w, 1, color)

    # Pole base
    rect(img, 5, 28, 6, 2, PAL["stone"])
    rect(img, 6, 30, 4, 2, PAL["stone_shadow"])


def generate_checkpoint():
    """Generate checkpoint flag frames."""
    anims = {"idle": 2, "active": 4}
    frames = {}
    for anim_name, frame_count in anims.items():
        frames[anim_name] = []
        for f in range(frame_count):
            img = Image.new("RGBA", (16, 32), PAL["transparent"])
            draw_checkpoint(img, f, anim_name)
            frames[anim_name].append(img)
            save_frame("checkpoint", anim_name, f, img)
    return frames



# ─── Spike Hazard (16×16) ──────────────────────────────────────────
def draw_spike(img: Image.Image):
    """Draw 4 metal spikes on a base."""
    # Base
    rect(img, 0, 14, 16, 2, PAL["stone_shadow"])
    # 4 triangular spikes
    for x0 in [1, 5, 9, 13]:
        px(img, x0 + 1, 4, PAL["white"])
        rect(img, x0, 5, 3, 5, PAL["pole"])
        rect(img, x0, 5, 1, 5, PAL["pole_shadow"])
        rect(img, x0 - 1, 10, 5, 4, PAL["stone"])
        rect(img, x0 - 1, 10, 2, 4, PAL["stone_shadow"])


def generate_spike():
    frames = {"idle": []}
    img = Image.new("RGBA", (16, 16), PAL["transparent"])
    draw_spike(img)
    frames["idle"].append(img)
    save_frame("spike", "idle", 0, img)
    return frames


# ─── Moving Platform (32×16) ───────────────────────────────────────
def draw_moving_platform(img: Image.Image):
    """Draw a 32×16 plank platform with metallic end brackets."""
    rect(img, 0, 4, 32, 8, PAL["wood"])
    rect(img, 0, 4, 32, 2, PAL["wood_light"])
    rect(img, 0, 10, 32, 2, PAL["wood_shadow"])
    rect(img, 0, 3, 3, 10, PAL["pole"])
    rect(img, 0, 3, 1, 10, PAL["pole_shadow"])
    rect(img, 29, 3, 3, 10, PAL["pole"])
    rect(img, 29, 3, 1, 10, PAL["pole_shadow"])


def generate_moving_platform():
    frames = {"idle": []}
    img = Image.new("RGBA", (32, 16), PAL["transparent"])
    draw_moving_platform(img)
    frames["idle"].append(img)
    save_frame("platform", "idle", 0, img)
    return frames


# ─── Powerup Star (16×16) ──────────────────────────────────────────


def draw_powerup(img, frame: int = 0):
    # Floating Y offset
    hover_y = math.sin(frame * math.pi / 2.0) * 1.5
    cy = int(8 + hover_y)

    # Glowing golden star body
    # Center core
    rect(img, 6, cy - 2, 4, 6, PAL["gold"])
    rect(img, 4, cy - 1, 8, 4, PAL["gold"])
    # Star points
    px(img, 7, cy - 4, PAL["gold_light"])
    px(img, 8, cy - 4, PAL["gold_light"])
    px(img, 7, cy + 5, PAL["gold_shadow"])
    px(img, 8, cy + 5, PAL["gold_shadow"])
    px(img, 2, cy, PAL["gold_light"])
    px(img, 13, cy, PAL["gold_light"])

    # Sparkle particles (rotating)
    sparkle_offsets = [
        (3, cy - 3), (12, cy - 3), (3, cy + 3), (12, cy + 3),
        (8, cy - 5), (8, cy + 5), (1, cy), (14, cy)
    ]
    sp = sparkle_offsets[frame % len(sparkle_offsets)]
    px(img, sp[0], sp[1], PAL["white"])


def generate_powerup():
    frames = {"idle": []}
    for i in range(4):
        img = Image.new("RGBA", (16, 16), PAL["transparent"])
        draw_powerup(img, i)
        frames["idle"].append(img)
        save_frame("powerup", "idle", i, img)
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
def hard_threshold_alpha(img: Image.Image) -> Image.Image:
    """Ensure crisp 1-pixel hard edges by thresholding alpha channel (>= 128 -> 255, < 128 -> 0)."""
    if img.mode != "RGBA":
        return img
    r, g, b, a = img.split()
    a_crisp = a.point(lambda p: 255 if p >= 128 else 0)
    return Image.merge("RGBA", (r, g, b, a_crisp))

def save_frame(entity: str, anim: str, frame: int, img: Image.Image):
    """Save a single animation frame PNG."""
    path = OUT_DIR / entity / f"{anim}_{frame}.png"
    path.parent.mkdir(parents=True, exist_ok=True)
    hard_threshold_alpha(img).save(path)

def save_tile(entity: str, name: str, img: Image.Image):
    """Save a single tile PNG."""
    path = OUT_DIR / entity / f"{name}.png"
    path.parent.mkdir(parents=True, exist_ok=True)
    hard_threshold_alpha(img).save(path)



# ─── Contact Sheet ─────────────────────────────────────────────────
def generate_shrine_sprites():
    """Generate pixel art sprites for Sun & Steel Shrine and Boss Arena."""
    out = {}
    shrine_dir = Path("games/tactics/assets/sprites/shrine")
    shrine_dir.mkdir(parents=True, exist_ok=True)

    # 1. Hero Apprentice (32x32 HD Pixel Art)
    img_app = Image.new("RGBA", (32, 32), (0, 0, 0, 0))
    for y in range(4, 12):
        for x in range(12, 20): px(img_app, x, y, (200, 205, 220)) # Steel helmet
    for y in range(8, 10):
        for x in range(14, 18): px(img_app, x, y, (30, 35, 50)) # Visor slot
    for y in range(12, 24):
        for x in range(10, 22): px(img_app, x, y, (45, 125, 75)) # Green tunic
    for y in range(14, 20):
        for x in range(13, 19): px(img_app, x, y, (180, 185, 200)) # Chestplate
    for x in range(10, 22): px(img_app, x, 20, (120, 80, 40)) # Leather belt
    for y in range(24, 30):
        for x in range(11, 15): px(img_app, x, y, (50, 55, 70)) # Boot L
        for x in range(17, 21): px(img_app, x, y, (50, 55, 70)) # Boot R
    for y in range(10, 26): px(img_app, 23, y, (220, 225, 240)) # Steel blade
    px(img_app, 23, 8, (255, 215, 0)) # Gold pommel
    for y in range(14, 22):
        for x in range(6, 10): px(img_app, x, y, (160, 165, 180)) # Shield
    img_app.save(shrine_dir / "hero_apprentice.png")
    out["hero_apprentice"] = img_app

    # 2. Hero Pyromancer (32x32 HD Flame Sorcerer)
    img_pyro = Image.new("RGBA", (32, 32), (0, 0, 0, 0))
    for y in range(4, 26):
        for x in range(9, 23): px(img_pyro, x, y, (180, 30, 40)) # Crimson Robes
    for y in range(6, 12):
        for x in range(12, 20): px(img_pyro, x, y, (255, 140, 20)) # Fiery Hair
    for y in range(14, 22):
        for x in range(13, 19): px(img_pyro, x, y, (255, 200, 40)) # Gold Flame Rune Emblem
    # 4. Hero Multi-Frame Attack Animation Frames (32x32)
    # Frame 0: Windup (Sword pulled back)
    img_atk0 = Image.new("RGBA", (32, 32), (0, 0, 0, 0))
    for y in range(4, 12):
        for x in range(10, 18): px(img_atk0, x, y, (200, 205, 220))
    for y in range(12, 24):
        for x in range(8, 20): px(img_atk0, x, y, (45, 125, 75))
    for y in range(2, 18): px(img_atk0, 4, y, (220, 225, 240)) # Sword pulled left
    img_atk0.save(shrine_dir / "hero_attack_0.png")
    out["hero_attack_0"] = img_atk0

    # Frame 1: Slash Impact (Sword swung across forward)
    img_atk1 = Image.new("RGBA", (32, 32), (0, 0, 0, 0))
    for y in range(4, 12):
        for x in range(12, 20): px(img_atk1, x, y, (200, 205, 220))
    for y in range(12, 24):
        for x in range(10, 22): px(img_atk1, x, y, (45, 125, 75))
    for x in range(16, 31): px(img_atk1, x, 14, (255, 230, 100)) # Glowing slash arc
    img_atk1.save(shrine_dir / "hero_attack_1.png")
    out["hero_attack_1"] = img_atk1

    # Frame 2: Recovery (Follow-through)
    img_atk2 = Image.new("RGBA", (32, 32), (0, 0, 0, 0))
    for y in range(4, 12):
        for x in range(12, 20): px(img_atk2, x, y, (200, 205, 220))
    for y in range(12, 24):
        for x in range(10, 22): px(img_atk2, x, y, (45, 125, 75))
    for y in range(16, 30): px(img_atk2, 26, y, (220, 225, 240)) # Sword low right
    img_atk2.save(shrine_dir / "hero_attack_2.png")
    out["hero_attack_2"] = img_atk2

    # 5. Sunken Golem Boss (48x48 Giant Boss Monster)
    img_golem = Image.new("RGBA", (48, 48), (0, 0, 0, 0))
    for y in range(8, 42):
        for x in range(10, 38): px(img_golem, x, y, (70, 75, 90)) # Stone Body
    for y in range(12, 24):
        for x in range(14, 34): px(img_golem, x, y, (90, 95, 115)) # Shoulder Carapace
    for y in range(20, 30):
        for x in range(20, 28): px(img_golem, x, y, (255, 100, 20)) # Fire core
    px(img_golem, 18, 14, (255, 50, 50)) # Eyes
    px(img_golem, 19, 14, (255, 50, 50))
    px(img_golem, 29, 14, (255, 50, 50))
    px(img_golem, 30, 14, (255, 50, 50))
    for y in range(4, 44): px(img_golem, 40, y, (60, 40, 30)) # Massive Hammer
    for y in range(4, 16):
        for x in range(36, 46): px(img_golem, x, y, (110, 115, 130))
    img_golem.save(shrine_dir / "guardian.png")
    out["guardian"] = img_golem
    # Fiery Staff
    for y in range(2, 30): px(img_pyro, 24, y, (100, 60, 30))
    for y in range(2, 6):
        for x in range(22, 27): px(img_pyro, x, y, (255, 160, 30)) # Flaming orb
    img_pyro.save(shrine_dir / "hero_pyromancer.png")
    # 3. Hero Spellblade (32x32 HD Frost Knight)
    img_blade = Image.new("RGBA", (32, 32), (0, 0, 0, 0))
    for y in range(4, 26):
        for x in range(9, 23): px(img_blade, x, y, (40, 90, 160)) # Blue Frost Plate
    for y in range(6, 12):
        for x in range(12, 20): px(img_blade, x, y, (220, 235, 255)) # Silver Hair
    for y in range(8, 28): px(img_blade, 24, y, (100, 200, 255)) # Glowing Frost Blade
    img_blade.save(shrine_dir / "hero_spellblade.png")
    out["hero_spellblade"] = img_blade

    # 4. Guardian Monster (16x16)
    img_garg = Image.new("RGBA", (16, 16), (0, 0, 0, 0))
    for y in range(4, 14):
        for x in range(4, 12):
            px(img_garg, x, y, (120, 60, 80)) # Stone gargoyle body
    # Wings
    for y in range(3, 10):
        px(img_garg, 2, y, (90, 40, 60))
        px(img_garg, 13, y, (90, 40, 60))
    # Eyes
    px(img_garg, 6, 7, (255, 60, 60))
    px(img_garg, 9, 7, (255, 60, 60))
    img_garg.save(shrine_dir / "guardian.png")
    out["guardian"] = img_garg

    # 5. Attack Visual FX (32x32)
    img_slash = Image.new("RGBA", (32, 32), (0, 0, 0, 0))
    for y in range(4, 28):
        for x in range(4, 28):
            if abs((x - 16)**2 + (y - 16)**2 - 120) < 35:
                px(img_slash, x, y, (255, 230, 100, 255)) # Gold slash arc
    img_slash.save(shrine_dir / "slash_arc.png")
    out["slash_arc"] = img_slash

    img_fire = Image.new("RGBA", (32, 32), (0, 0, 0, 0))
    for y in range(2, 30):
        for x in range(2, 30):
            if (x - 16)**2 + (y - 16)**2 < 120:
                px(img_fire, x, y, (255, 100 + (x*4)%120, 20, 255)) # Fire Burst
    img_fire.save(shrine_dir / "fire_cleave.png")
    out["fire_cleave"] = img_fire

    img_frost = Image.new("RGBA", (32, 32), (0, 0, 0, 0))
    for y in range(2, 30):
        for x in range(2, 30):
            if (x - 16)**2 + (y - 16)**2 < 120:
                px(img_frost, x, y, (80, 200, 255, 255)) # Frost Wave
    img_frost.save(shrine_dir / "frost_wave.png")
    out["frost_wave"] = img_frost

    img_mortar = Image.new("RGBA", (16, 16), (0, 0, 0, 0))
    for y in range(2, 14):
        for x in range(2, 14):
            if (x - 8)**2 + (y - 8)**2 < 30:
                px(img_mortar, x, y, (255, 60, 20, 255)) # Magma Mortar Fireball
    img_mortar.save(shrine_dir / "magma_mortar.png")
    out["magma_mortar"] = img_mortar

    img_fracture = Image.new("RGBA", (48, 48), (0, 0, 0, 0))
    for y in range(4, 44):
        for x in range(4, 44):
            if (x - 24)**2 + (y - 24)**2 < 400:
                if (x + y) % 2 == 0:
                    px(img_fracture, x, y, (255, 120, 20, 255)) # Fire shatter
                else:
                    px(img_fracture, x, y, (80, 220, 255, 255)) # Ice shatter
    img_fracture.save(shrine_dir / "thermal_fracture.png")
    out["thermal_fracture"] = img_fracture
    img_chest_c = Image.new("RGBA", (16, 16), (0, 0, 0, 0))
    for y in range(6, 15):
        for x in range(2, 14):
            px(img_chest_c, x, y, (200, 150, 40)) # Gold trim
    for y in range(8, 13):
        for x in range(4, 12):
            px(img_chest_c, x, y, (140, 90, 30)) # Wood inlay
    px(img_chest_c, 7, 9, (255, 255, 255)) # Lock latch
    px(img_chest_c, 8, 9, (255, 255, 255))
    img_chest_c.save(shrine_dir / "chest_closed.png")
    out["chest_closed"] = img_chest_c

    img_chest_o = Image.new("RGBA", (16, 16), (0, 0, 0, 0))
    for y in range(9, 15):
        for x in range(2, 14):
            px(img_chest_o, x, y, (200, 150, 40))
    for y in range(2, 8):
        for x in range(2, 14):
            px(img_chest_o, x, y, (140, 90, 30)) # Lid propped open
    for y in range(8, 11):
        for x in range(4, 12):
            px(img_chest_o, x, y, (255, 220, 80)) # Glowing gold loot
    img_chest_o.save(shrine_dir / "chest_open.png")
    out["chest_open"] = img_chest_o

    # 6. Sun Torch Unlit & Lit (16x16)
    img_torch_u = Image.new("RGBA", (16, 16), (0, 0, 0, 0))
    for y in range(6, 16):
        for x in range(6, 10):
            px(img_torch_u, x, y, (100, 100, 110)) # Stone pedestal
    img_torch_u.save(shrine_dir / "torch_unlit.png")
    out["torch_unlit"] = img_torch_u

    img_torch_l = Image.new("RGBA", (16, 16), (0, 0, 0, 0))
    for y in range(8, 16):
        for x in range(6, 10):
            px(img_torch_l, x, y, (100, 100, 110))
    # Animated Flame
    for y in range(1, 8):
        for x in range(5, 11):
            px(img_torch_l, x, y, (255, 160, 40))
    for y in range(3, 7):
        for x in range(6, 10):
            px(img_torch_l, x, y, (255, 240, 100)) # Inner white hot flame
    img_torch_l.save(shrine_dir / "torch_lit.png")
    out["torch_lit"] = img_torch_l

    # 7. Shrine Tiles & Architecture (16x16 / 16x32)
    img_floor = Image.new("RGBA", (16, 16), (0, 0, 0, 0))
    for y in range(16):
        for x in range(16):
            c = (50, 54, 68) if (x % 8 == 0 or y % 8 == 0) else (70, 75, 92)
            px(img_floor, x, y, c)
    img_floor.save(shrine_dir / "stone_floor.png")
    out["stone_floor"] = img_floor

    img_wall = Image.new("RGBA", (16, 16), (0, 0, 0, 0))
    for y in range(16):
        for x in range(16):
            c = (90, 95, 115) if y < 3 else ((30, 34, 46) if (x % 4 == 0 or y % 4 == 0) else (40, 44, 58))
            px(img_wall, x, y, c)
    img_wall.save(shrine_dir / "stone_wall.png")
    out["stone_wall"] = img_wall

    img_pillar = Image.new("RGBA", (16, 32), (0, 0, 0, 0))
    for y in range(4, 28):
        for x in range(4, 12):
            px(img_pillar, x, y, (100, 105, 125))
    for y in range(2, 6):
        for x in range(2, 14): px(img_pillar, x, y, (130, 135, 155))
    for y in range(26, 30):
        for x in range(2, 14): px(img_pillar, x, y, (130, 135, 155))
    px(img_pillar, 8, 14, (255, 200, 40)) # Sun Rune
    px(img_pillar, 8, 15, (255, 200, 40))
    img_pillar.save(shrine_dir / "stone_pillar.png")
    out["stone_pillar"] = img_pillar

    img_tab = Image.new("RGBA", (16, 16), (0, 0, 0, 0))
    for y in range(2, 14):
        for x in range(3, 13):
            px(img_tab, x, y, (120, 125, 140))
    for y in range(4, 12):
        px(img_tab, 5, y, (255, 200, 40)) # Golden runes
        px(img_tab, 8, y, (255, 200, 40))
    img_tab.save(shrine_dir / "lore_tablet.png")
    out["lore_tablet"] = img_tab

    # 8. Interaction Key Prompts (16x16)
    for key_char in ["F", "K", "E"]:
        img_key = Image.new("RGBA", (16, 16), (0, 0, 0, 0))
        for y in range(2, 14):
            for x in range(2, 14):
                px(img_key, x, y, (40, 40, 50, 255)) # Dark border box
        for y in range(3, 13):
            for x in range(3, 13):
                px(img_key, x, y, (240, 240, 250)) # White keycap
        img_key.save(shrine_dir / f"prompt_{key_char.lower()}.png")
        out[f"prompt_{key_char.lower()}"] = img_key

    # 9. Tactical Class & Terrain Sprites (16x32 & 16x16)
    img_ranger = Image.new("RGBA", (16, 32), (0, 0, 0, 0))
    for y in range(4, 28):
        for x in range(4, 12): px(img_ranger, x, y, (40, 140, 60)) # Green hood & cloak
    for y in range(8, 20): px(img_ranger, 12, y, (160, 100, 40)) # Wooden bow
    px(img_ranger, 7, 10, (255, 200, 150)) # Face
    img_ranger.save(shrine_dir / "hero_ranger.png")
    out["hero_ranger"] = img_ranger

    img_cleric = Image.new("RGBA", (16, 32), (0, 0, 0, 0))
    for y in range(4, 28):
        for x in range(4, 12): px(img_cleric, x, y, (240, 240, 250)) # White priest robe
    for y in range(4, 8):
        for x in range(4, 12): px(img_cleric, x, y, (255, 200, 40)) # Gold trim
    for y in range(6, 22): px(img_cleric, 3, y, (200, 170, 80)) # Healing staff
    px(img_cleric, 3, 5, (80, 220, 255)) # Glowing orb
    img_cleric.save(shrine_dir / "hero_cleric.png")
    out["hero_cleric"] = img_cleric

    img_rock = Image.new("RGBA", (16, 16), (0, 0, 0, 0))
    for y in range(3, 14):
        for x in range(2, 14): px(img_rock, x, y, (80, 85, 100))
    for y in range(4, 12):
        for x in range(4, 12): px(img_rock, x, y, (110, 115, 130))
    img_rock.save(shrine_dir / "cover_rock.png")
    out["cover_rock"] = img_rock

    img_lava = Image.new("RGBA", (16, 16), (0, 0, 0, 0))
    for y in range(0, 16):
        for x in range(0, 16): px(img_lava, x, y, (220, 60, 20))
    for y in range(4, 12):
        for x in range(4, 12): px(img_lava, x, y, (255, 160, 30))
    img_lava.save(shrine_dir / "lava_tile.png")
    out["lava_tile"] = img_lava

    generate_art_prototypes()
    return out


def generate_art_prototypes():
    """
    Generates a 3-way visual prototype comparison sheet (logs/art_prototype_comparison.png)
    comparing Option A (AI-Accelerated Detailed Pixel Art), Option B (Classic 16-Bit Asset Pack),
    and Option C (3D-to-2D Cel-Shaded Render).
    """
    W, H = 32, 32
    SCALE = 4

    # Option A: AI-Accelerated High-Detail 32x32 Pixel Art (Retro Diffusion / PixelLab Style)
    img_a = Image.new("RGBA", (W, H), (0, 0, 0, 0))
    # Rich Golden Plate Armor & Shading
    for y in range(6, 28):
        for x in range(8, 24):
            c = (255, 200, 40) if (x + y) % 2 == 0 else (210, 150, 20)
            px(img_a, x, y, c)
    # Steel Visor & Red Plume
    for y in range(2, 6):
        for x in range(12, 20): px(img_a, x, y, (220, 40, 40)) # Plume
    for y in range(8, 12):
        for x in range(10, 22): px(img_a, x, y, (180, 190, 210)) # Helmet
    for x in range(12, 20): px(img_a, x, 10, (20, 20, 30)) # Visor Slit
    # Shield & Broadsword
    for y in range(12, 26):
        for x in range(4, 9): px(img_a, x, y, (40, 90, 180)) # Blue Shield
    for y in range(6, 26):
        px(img_a, 25, y, (240, 240, 250)) # Glowing Blade

    # Option B: Classic 16-Bit Handcrafted Asset Pack (Fire Emblem / SNES Style)
    img_b = Image.new("RGBA", (W, H), (0, 0, 0, 0))
    # Crisp Clean Outlines
    for y in range(8, 28):
        for x in range(10, 22):
            px(img_b, x, y, (60, 120, 220)) # Blue Cloak & Armor
    for y in range(6, 12):
        for x in range(11, 21): px(img_b, x, y, (255, 210, 160)) # Skin & Hair
    for y in range(10, 26):
        px(img_b, 24, y, (200, 200, 210)) # Steel Sword

    # Option C: 3D-to-2D Cel-Shaded Pre-Rendered Frame (Dead Cells / Blender 64px Style)
    img_c = Image.new("RGBA", (W, H), (0, 0, 0, 0))
    for y in range(4, 29):
        for x in range(6, 26):
            dist = math.sqrt((x - 16)**2 + (y - 16)**2)
            if dist < 12:
                # Smooth Toon Shading Gradient
                val = int(255 - dist * 10)
                px(img_c, x, y, (val, int(val * 0.7), 40, 255))
    # Black Edge Detection Outline
    for y in range(4, 29):
        px(img_c, 6, y, (10, 10, 15))
        px(img_c, 25, y, (10, 10, 15))

    # Composite Comparison Image (3 Columns)
    comp_w = (W * SCALE + 10) * 3 + 10
    comp_h = H * SCALE + 40
    comp = Image.new("RGBA", (comp_w, comp_h), (20, 24, 32, 255))

    imgs = [("Option A: AI Pixel Art (32x32)", img_a), ("Option B: 16-Bit Pack (32x32)", img_b), ("Option C: 3D-to-2D Render (32x32)", img_c)]
    for i, (label, img) in enumerate(imgs):
        scaled = img.resize((W * SCALE, H * SCALE), Image.NEAREST)
        x_off = 10 + i * (W * SCALE + 10)
        comp.paste(scaled, (x_off, 25), scaled)

    logs_dir = Path("logs")
    logs_dir.mkdir(exist_ok=True)
    comp_path = logs_dir / "art_prototype_comparison.png"
    comp.save(comp_path)
    print(f"  🎨 Art Prototype Comparison generated: {comp_path}")
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

    print("  🏁 Checkpoint flag (16×32)...")
    all_sprites["checkpoint"] = generate_checkpoint()
    count = sum(len(f) for f in all_sprites["checkpoint"].values())
    total += count
    print(f"     → {count} frames")

    print("  ⚠️  Spikes (16×16)...")
    all_sprites["spike"] = generate_spike()
    count = sum(len(f) for f in all_sprites["spike"].values())
    total += count
    print(f"     → {count} frames")

    print("  🪵 Moving Platform (32×16)...")
    all_sprites["platform"] = generate_moving_platform()
    count = sum(len(f) for f in all_sprites["platform"].values())
    total += count
    print(f"     → {count} frames")

    print("  ⭐ Powerup Star (16×16)...")
    all_sprites["powerup"] = generate_powerup()
    count = sum(len(f) for f in all_sprites["powerup"].values())
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

    print("  🏛️ Shrine Entities & UI Prompts (16×16 / 16×32)...")
    shrine_imgs = generate_shrine_sprites()
    all_sprites["shrine"] = {name: [img] for name, img in shrine_imgs.items()}
    total += len(shrine_imgs)
    print(f"     → {len(shrine_imgs)} shrine assets")

    print()
    print(f"  ✅ Total: {total} PNG files in {OUT_DIR}/")
    print()

    generate_contact_sheet(all_sprites)
    print()
    print("  Done! Open sprites-review.png to preview all sprites at 4× zoom.")


if __name__ == "__main__":
    main()
