"""Preview renders: an enlarged contact sheet and a mock tactics board with the whole roster.

usage: python tools/art/preview.py [--scale 6] [--out DIR]
Writes <out>/sheet.png (all frames, enlarged) and <out>/board_<f>.png / board3x_<f>.png (4 frames of a
12x10 board). Default <out> is logs/art/ (gitignored). Missing sprites are drawn as a magenta X so gaps are obvious.
"""

from __future__ import annotations

import argparse
import sys
from pathlib import Path

from PIL import Image, ImageDraw

HERE = Path(__file__).resolve().parent
ROOT = HERE.parents[1]
OUT = ROOT / "games" / "tactics" / "assets" / "sprites" / "sun_steel"
sys.path.insert(0, str(HERE))
from pixlib import load_spec  # noqa: E402

BG = (32, 34, 42, 255)
CELL = 24
BOARD_W, BOARD_H = 12, 10

# Board layout: L = lava, R = cover rock, everything else floor.
LAYOUT = [
    "............",
    "....LL......",
    "...LLLL..R..",
    "....LL......",
    "..R.........",
    "........R...",
    ".......LL...",
    "..R...LLLL..",
    ".......LL...",
    "............",
]
# (sprite, col, row)
UNITS = [
    ("unit_sun_knight", 3, 6), ("unit_frost_blade", 4, 7), ("unit_pyromancer", 1, 8),
    ("unit_ranger", 3, 9), ("unit_cleric", 4, 8),
    ("unit_golem", 8, 3), ("unit_golem", 10, 5), ("unit_golem", 10, 8),
]


def sprite(arm: Path, name: str, frame: int, size) -> Image.Image:
    path = arm / f"{name}.{frame}.png"
    if not path.exists():
        path = arm / f"{name}.0.png"
    if path.exists():
        return Image.open(path).convert("RGBA")
    img = Image.new("RGBA", tuple(size), (0, 0, 0, 0))
    d = ImageDraw.Draw(img)
    d.line((0, 0, size[0] - 1, size[1] - 1), fill=(255, 0, 255, 255))
    d.line((0, size[1] - 1, size[0] - 1, 0), fill=(255, 0, 255, 255))
    return img


def contact_sheet(arm: Path, spec: list[dict], scale: int) -> Image.Image:
    rows = []
    for s in spec:
        frames = [sprite(arm, s["name"], f, s["size"]) for f in range(s["frames"])]
        rows.append(frames)
    pad = 6
    w = max(sum(f.width * scale + pad for f in r) for r in rows) + pad
    h = sum(max(f.height for f in r) * scale + pad for r in rows) + pad
    sheet = Image.new("RGBA", (w, h), BG)
    y = pad
    for r in rows:
        x = pad
        for f in r:
            sheet.alpha_composite(f.resize((f.width * scale, f.height * scale), Image.NEAREST), (x, y))
            x += f.width * scale + pad
        y += max(f.height for f in r) * scale + pad
    return sheet


def board(arm: Path, frame: int) -> Image.Image:
    spec = {s["name"]: s for s in load_spec()["sprites"]}
    img = Image.new("RGBA", (BOARD_W * CELL, BOARD_H * CELL), BG)
    floor = sprite(arm, "tile_floor", 0, (CELL, CELL))
    lava = sprite(arm, "tile_lava", frame % spec["tile_lava"]["frames"], (CELL, CELL))
    rock = sprite(arm, "prop_cover_rock", 0, (CELL, CELL))
    for r, line in enumerate(LAYOUT):
        for c, ch in enumerate(line):
            img.alpha_composite(lava if ch == "L" else floor, (c * CELL, r * CELL))
            if ch == "R":
                img.alpha_composite(rock, (c * CELL, r * CELL))
    for name, c, r in sorted(UNITS, key=lambda u: u[2]):
        s = spec[name]
        u = sprite(arm, name, frame % s["frames"], s["size"])
        # 32x32 unit centred on the cell, feet (row ~30) on the cell's bottom edge
        img.alpha_composite(u, (c * CELL + (CELL - u.width) // 2, r * CELL + CELL - u.height + 1))
    return img


def main() -> int:
    ap = argparse.ArgumentParser()
    ap.add_argument("--scale", type=int, default=6)
    ap.add_argument("--out", default=str(ROOT / "logs" / "art"))
    a = ap.parse_args()
    arm = OUT
    out = Path(a.out)
    out.mkdir(parents=True, exist_ok=True)
    spec = load_spec()["sprites"]
    contact_sheet(arm, spec, a.scale).save(out / "sheet.png")
    for f in range(4):
        b = board(arm, f)
        b.save(out / f"board_{f}.png")
        b.resize((b.width * 3, b.height * 3), Image.NEAREST).save(out / f"board3x_{f}.png")
    print(f"wrote previews into {out}")
    return 0


if __name__ == "__main__":
    sys.exit(main())
