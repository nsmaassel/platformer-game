"""Crisp conversion of an AI sprite strip, for the small chibi heroes (convert.py is the averaging converter).

Differences from convert.py: colours are reduced to a small per-sprite subset of the master palette at full
size first; the downscale takes the majority colour of each source block (keeping dark details such as eyes when
they cover enough of the block) instead of averaging; isolated single pixels are folded into their neighbours.

usage: python tools/art/crisp_convert.py <raw image> <out name> [--work DIR] [--height 21] [--colours 14]
                                     [--rows Y0,Y1]  (keep only these raw pixel rows: one row of four poses)
                                     [--grid]  (the raw is a 2x2 grid of poses)
"""

from __future__ import annotations

import argparse
import sys
from collections import Counter
from pathlib import Path

from PIL import Image

HERE = Path(__file__).resolve().parent
REPO = HERE.parents[1]
WORK = REPO / "logs" / "art" / "work"  # intermediate frames (gitignored); rebuild.py passes a fresh folder
sys.path.insert(0, str(HERE))
import convert as pp  # noqa: E402  (remove_background, split_frames, add_outline, nearest)

W = H = 32
BOTTOM = H - 3  # feet on row 29, outline on row 30
DARK_SHARE = 0.34  # a dark colour wins a block when it covers at least this share of it (eyes, nose)


def lum(c):
    return 0.299 * c[0] + 0.587 * c[1] + 0.114 * c[2]


def reduce_colours(frames: list[Image.Image], k: int) -> dict:
    """Maps every opaque source colour to one of the k most used master-palette colours across all frames."""
    first = {}
    use = Counter()
    for f in frames:
        for p in f.getdata():
            if p[3] >= 128:
                c = p[:3]
                if c not in first:
                    first[c] = pp.nearest(c)
                use[first[c]] += 1
    keep = [c for c, _ in use.most_common(k)]
    # keep the darkest used colour too, so outlines and pupils survive
    darkest = min(use, key=lum)
    if darkest not in keep:
        keep[-1] = darkest

    def near(c):
        r, g, b = c
        return min(keep, key=lambda q: (r - q[0]) ** 2 * 2 + (g - q[1]) ** 2 * 4 + (b - q[2]) ** 2 * 3)

    return {c: near(m) for c, m in first.items()}


def majority_downscale(src: Image.Image, cmap: dict, w: int, h: int, dark_share: float = DARK_SHARE) -> Image.Image:
    """Each target pixel takes the majority colour of its source block; a dark colour wins at >= dark_share of the block."""
    sw, sh = src.size
    px = src.load()
    out = Image.new("RGBA", (w, h), (0, 0, 0, 0))
    dst = out.load()
    for ty in range(h):
        y0, y1 = int(ty * sh / h), max(int(ty * sh / h) + 1, int((ty + 1) * sh / h))
        for tx in range(w):
            x0, x1 = int(tx * sw / w), max(int(tx * sw / w) + 1, int((tx + 1) * sw / w))
            votes, total, opaque = Counter(), 0, 0
            for y in range(y0, y1):
                for x in range(x0, x1):
                    total += 1
                    p = px[x, y]
                    if p[3] >= 128:
                        opaque += 1
                        votes[cmap[p[:3]]] += 1
            if not votes or opaque * 2 < total:
                continue
            dark = {c: n for c, n in votes.items() if lum(c) < 70}
            if dark and sum(dark.values()) >= dark_share * opaque:
                colour = max(dark, key=dark.get)
            else:
                colour = votes.most_common(1)[0][0]
            dst[tx, ty] = colour + (255,)
    return out


def fold_orphans(img: Image.Image) -> Image.Image:
    """A pixel whose 4 neighbours share none of its colour but agree (3+) on another takes that colour."""
    out = img.copy()
    s, d = img.load(), out.load()
    w, h = img.size
    for y in range(h):
        for x in range(w):
            c = s[x, y]
            if c[3] == 0:
                continue
            nb = [s[x + dx, y + dy] for dx, dy in ((1, 0), (-1, 0), (0, 1), (0, -1)) if 0 <= x + dx < w and 0 <= y + dy < h]
            nb = [n for n in nb if n[3] == 255]
            if len(nb) == 4 and c not in nb:
                top, n = Counter(nb).most_common(1)[0]
                if n >= 3 and lum(c) >= 70:  # never erase dark details (eyes, nose)
                    d[x, y] = top
    return out


def head_centre(img: Image.Image, band: tuple[float, float] = (0.0, 0.4)) -> float:
    """Mean x of the opaque pixels in a band of rows (fractions of the subject's height, default the top 40%): the
    head, which should stay put across frames. Tall ears can lean, so a sprite with ears uses a lower band."""
    a = img.getchannel("A").load()
    y0, y1 = int(img.height * band[0]), max(int(img.height * band[0]) + 1, int(img.height * band[1]))
    pts = [x for y in range(y0, y1) for x in range(img.width) if a[x, y] >= 128]
    return sum(pts) / len(pts) if pts else img.width / 2


def main() -> int:
    ap = argparse.ArgumentParser()
    ap.add_argument("raw")
    ap.add_argument("name")
    ap.add_argument("--work", default=str(WORK), help="folder the output frames are written to")
    ap.add_argument("--height", type=int, default=21)
    ap.add_argument("--colours", type=int, default=14)
    ap.add_argument("--dark-share", type=float, default=DARK_SHARE,
                    help="share of a block a dark colour needs to win it (higher = fewer dark specks and lines)")
    ap.add_argument("--align", choices=["bbox", "head"], default="bbox",
                    help="bbox: centre each frame on its own outline; head: line frames up on frame 0's head so the "
                         "face doesn't drift when a staff or tail changes width")
    ap.add_argument("--head-band", default="0,0.4",
                    help="F0,F1: rows used for --align head, as fractions of the subject height (default 0,0.4)")
    ap.add_argument("--grid", action="store_true",
                    help="the raw image is a 2x2 grid of poses: lay the cells out in one row (reading order) first")
    ap.add_argument("--rows", help="Y0,Y1: crop the raw image to these pixel rows first (drops a second row or strays)")
    a = ap.parse_args()
    raw = Image.open(REPO / a.raw)  # relative to the repo root
    if a.rows:
        y0, y1 = (int(v) for v in a.rows.split(","))
        raw = raw.crop((0, y0, raw.width, y1 + 1))
    if a.grid:
        raw = raw.convert("RGB")
        cw, ch = raw.width // 2, raw.height // 2
        row = Image.new("RGB", (cw * 4, ch))
        for k, (gx, gy) in enumerate(((0, 0), (1, 0), (0, 1), (1, 1))):
            row.paste(raw.crop((gx * cw, gy * ch, gx * cw + cw, gy * ch + ch)), (k * cw, 0))
        raw = row
    strip = pp.remove_background(raw)
    frames = pp.split_frames(strip, 4)
    crops = [f.crop(f.getbbox()) for f in frames]
    mw, mh = max(c.width for c in crops), max(c.height for c in crops)
    s = a.height / mh
    cmap = reduce_colours(crops, a.colours)
    out_dir = Path(a.work)
    out_dir.mkdir(parents=True, exist_ok=True)
    smalls = []
    for c in crops:
        tw, th = max(1, round(c.width * s)), max(1, round(c.height * s))
        smalls.append(fold_orphans(majority_downscale(c, cmap, tw, th, a.dark_share)))
    xs = [(W - sm.width) // 2 for sm in smalls]
    if a.align == "head":
        band = tuple(float(v) for v in a.head_band.split(","))
        centres = [head_centre(sm, band) + x for sm, x in zip(smalls, xs)]
        xs = [x + round(centres[0] - c) for x, c in zip(xs, centres)]
    for i, sm in enumerate(smalls):
        canvas = Image.new("RGBA", (W, H), (0, 0, 0, 0))
        canvas.alpha_composite(sm, (xs[i], BOTTOM - sm.height + 1))
        pp.add_outline(canvas).save(out_dir / f"{a.name}.{i}.png", format="PNG", optimize=False, compress_level=9)
    print(f"wrote {a.name}.0-3.png to {out_dir} (scale {s:.4f}, {a.colours} colours)")
    return 0


if __name__ == "__main__":
    sys.exit(main())
