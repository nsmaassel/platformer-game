"""Mane pass: grows a lion's mane outward with a zig-zag (spiky) or scalloped (fluffy) edge so it reads as a lion.

Reads the frames of an already processed sprite (it does not re-run earlier passes). The new mane outline is worked
out once from the union of all frames' head silhouettes and applied identically to every frame, so it never
flickers. Around the head centre, the mane radius grows by a wave: a triangle wave gives wide-based points, a
rounded wave gives fluffy scallops. Only transparent pixels are painted; old outline pixels that end up inside the
mane are recoloured, and only the new pixels get an outline. --crown sets how many rows the mane may rise above the
old head top (0 clips the top flat and keeps the old height; each row adds 1 px to the sprite's height). Deterministic: same input, same bytes.

usage: python tools/art/mane_pass.py <source name> <out name> [--work DIR] --style spiky|fluffy
"""

from __future__ import annotations

import argparse
import math
import sys
from pathlib import Path

from PIL import Image

HERE = Path(__file__).resolve().parent
REPO = HERE.parents[1]
WORK = REPO / "logs" / "art" / "work"  # intermediate frames (gitignored); rebuild.py passes a fresh folder
sys.path.insert(0, str(HERE))
from pixlib import col  # noqa: E402

INK = col("ink.0")
MANE, SHADE = col("ember.3"), col("ember.2")
HEAD_ROWS = (8, 21)  # rows of the head (mane and face); the body below is never touched
SKIP_DOWN = (50, 130)  # degrees (0 = right, 90 = down): no tufts over the neck and body
STYLES = {
    # tufts around the full circle, wave height in px, phase (fraction of a tuft) so a point sits on top
    "spiky": {"tufts": 12, "height": 2.6, "phase": 0.0, "wave": "triangle"},
    "fluffy": {"tufts": 10, "height": 2.0, "phase": 0.5, "wave": "round"},
}


def wave(kind: str, f: float) -> float:
    """0 at the notch, 1 at the tip, for f in [0, 1)."""
    if kind == "triangle":
        return 1 - abs(2 * f - 1)
    return math.sin(math.pi * f) ** 0.5


def head_shape(union: set[tuple[int, int]]):
    head = [(x, y) for x, y in union if HEAD_ROWS[0] <= y <= HEAD_ROWS[1]]
    cx = sum(x for x, _ in head) / len(head)
    cy = sum(y for _, y in head) / len(head)
    radius = []
    for a in range(360):
        dx, dy = math.cos(math.radians(a)), math.sin(math.radians(a))
        r, last = 0.0, 0.0
        while r < 20:
            if (round(cx + dx * r), round(cy + dy * r)) in union:
                last = r
            r += 0.25
        radius.append(last)
    return cx, cy, radius


def plan(union: set[tuple[int, int]], style: str, w: int, h: int, crown: int) -> set[tuple[int, int, str]]:
    """The pixels to paint: (x, y, 'mane' | 'shade' | 'light')."""
    s = STYLES[style]
    cx, cy, radius = head_shape(union)
    top = min(y for _, y in union)
    period = 360 / s["tufts"]
    out = set()
    for y in range(max(1, top - crown), HEAD_ROWS[1] + 1):
        for x in range(w):
            if (x, y) in union:
                continue
            ang = math.degrees(math.atan2(y - cy, x - cx)) % 360
            if SKIP_DOWN[0] <= ang <= SKIP_DOWN[1]:
                continue
            # angle measured from straight up, so the phase puts a tip (or a scallop) at the top
            f = (((ang + 90) % 360) / period + s["phase"]) % 1.0
            t = wave(s["wave"], f)
            reach = radius[int(ang) % 360] + s["height"] * t
            d = math.hypot(x - cx, y - cy)
            if d <= reach:
                out.add((x, y, "shade" if 20 <= ang <= 160 else "mane"))
    return out


def rim(union: set[tuple[int, int]], pixels: set[tuple[int, int, str]]) -> set[tuple[int, int, str]]:
    """Old rim pixels (outline and the mane's dark edge) next to the new tufts: they get mane colours so the tufts
    join the mane instead of sitting outside a dark ring. Only pixels near the old edge qualify, never the face."""
    cx, cy, radius = head_shape(union)
    new = {(x, y) for x, y, _ in pixels}
    out = set()
    for y in range(HEAD_ROWS[0], HEAD_ROWS[1] + 1):
        for x in range(32):
            if (x, y) not in union or (x, y) in new:
                continue
            ang = math.degrees(math.atan2(y - cy, x - cx)) % 360
            if SKIP_DOWN[0] <= ang <= SKIP_DOWN[1]:
                continue
            if math.hypot(x - cx, y - cy) < radius[int(ang) % 360] - 2.5:
                continue
            near = any((x + dx, y + dy) in new for dx in (-2, -1, 0, 1, 2) for dy in (-2, -1, 0, 1, 2)
                       if abs(dx) + abs(dy) <= 2)
            if near:
                out.add((x, y, "shade" if 20 <= ang <= 160 else "mane"))
    return out


def rim_zone(union: set[tuple[int, int]]) -> set[tuple[int, int]]:
    """Pixels in the outer band of the head (old edge and beyond), where stray dark specks get folded away."""
    cx, cy, radius = head_shape(union)
    out = set()
    for y in range(HEAD_ROWS[0] - 1, HEAD_ROWS[1] + 1):
        for x in range(32):
            ang = math.degrees(math.atan2(y - cy, x - cx)) % 360
            if not SKIP_DOWN[0] <= ang <= SKIP_DOWN[1] and math.hypot(x - cx, y - cy) >= radius[int(ang) % 360] - 3.5:
                out.add((x, y))
    return out


def lum(c) -> float:
    return 0.299 * c[0] + 0.587 * c[1] + 0.114 * c[2]


def paint(img: Image.Image, pixels: set[tuple[int, int, str]], rim_pixels: set[tuple[int, int, str]],
          zone: set[tuple[int, int]]) -> Image.Image:
    img = img.copy()
    px = img.load()
    w, h = img.size
    colours = {"mane": MANE, "shade": SHADE}
    changed = set()
    for x, y, kind in sorted(pixels):
        if px[x, y][3] == 0:
            px[x, y] = colours[kind]
            changed.add((x, y))
    for x, y, kind in sorted(rim_pixels):
        if px[x, y][3] and lum(px[x, y]) < 60:  # dark rim only; lighter mane detail stays
            px[x, y] = colours[kind]
            changed.add((x, y))
    for x, y in sorted(changed):
        for dx, dy in ((1, 0), (-1, 0), (0, 1), (0, -1)):
            nx, ny = x + dx, y + dy
            if 0 <= nx < w and 0 <= ny < h and px[nx, ny][3] == 0:
                px[nx, ny] = INK
    # a dark speck left inside the mane (all 4 neighbours opaque and light) takes its neighbours' colour
    snap = img.copy().load()
    for x, y in sorted(zone):
        c = snap[x, y]
        if not c[3] or lum(c) >= 60 or not (0 < x < w - 1 and 0 < y < h - 1):
            continue
        nb = [snap[x + dx, y + dy] for dx, dy in ((1, 0), (-1, 0), (0, 1), (0, -1))]
        if all(n[3] and lum(n) >= 60 for n in nb):
            px[x, y] = max(sorted(set(nb)), key=nb.count)
    return img


def main() -> int:
    ap = argparse.ArgumentParser()
    ap.add_argument("src")
    ap.add_argument("dst")
    ap.add_argument("--work", default=str(WORK), help="folder with the source frames; the output frames are written there too")
    ap.add_argument("--style", choices=sorted(STYLES), required=True)
    ap.add_argument("--crown", type=int, default=0, help="rows the mane may rise above the old head top")
    a = ap.parse_args()
    out = Path(a.work)
    frames = []
    while (p := out / f"{a.src}.{len(frames)}.png").exists():
        frames.append(Image.open(p).convert("RGBA"))
    if not frames:
        raise SystemExit(f"no frames for {a.src} in {out}")
    w, h = frames[0].size
    union = {(x, y) for f in frames for y in range(h) for x in range(w) if f.getpixel((x, y))[3]}
    pixels = plan(union, a.style, w, h, a.crown)
    rim_pixels = rim(union, pixels)
    zone = rim_zone(union)
    for i, f in enumerate(frames):
        paint(f, pixels, rim_pixels, zone).save(out / f"{a.dst}.{i}.png", format="PNG", optimize=False, compress_level=9)
    print(f"wrote {a.dst}.0-{len(frames) - 1}.png to {out} ({a.style}, crown {a.crown}, {len(pixels)} mane pixels)")
    return 0


if __name__ == "__main__":
    sys.exit(main())
