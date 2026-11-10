"""Turns raw AI-generated images into contract sprites for Sun & Steel, deterministically.

Raw inputs live in games/tactics/art/raw/ (PNG, JPG or WEBP); sprites land in
games/tactics/assets/sprites/sun_steel/:
  units/prop : <name>.<ext>        a horizontal strip of N frames on a flat background (magenta preferred),
               or <name>.<f>.<ext> one file per frame
  tiles      : <name>.<ext> or <name>.<f>.<ext>  a square texture (any size)
Steps: background flood-fill removal -> frame split -> crop -> area downscale with one scale per sprite ->
binary alpha -> nearest palette colour -> 1 px ink outline (units/props) -> place by the anchor rules.
Tiles get an overlap cross-fade at each edge so they wrap, then downscaled and quantized.
Fallbacks (logged in games/tactics/art/convert_log.json): a unit/prop with one frame gets a 1 px idle bob;
a tile with one frame gets drifting frames by scrolling.

usage: python tools/art/convert.py [--name SPRITE]
"""

from __future__ import annotations

import argparse
import json
import sys
from collections import deque
from pathlib import Path

from PIL import Image, ImageChops

HERE = Path(__file__).resolve().parent
REPO = HERE.parents[1]
sys.path.insert(0, str(HERE))
from pixlib import PALETTE, load_spec  # noqa: E402

RAW = REPO / "games" / "tactics" / "art" / "raw"
OUT = REPO / "games" / "tactics" / "assets" / "sprites" / "sun_steel"
LOG = REPO / "games" / "tactics" / "art" / "convert_log.json"
EXTS = (".png", ".jpg", ".jpeg", ".webp")
INK = PALETTE["ink.0"]
PAL = sorted({v[:3] for v in PALETTE.values()})


def nearest(rgb):
    r, g, b = rgb
    best, bd = None, 1e18
    for pr, pg, pb in PAL:
        rm = (r + pr) / 2
        d = (2 + rm / 256) * (r - pr) ** 2 + 4 * (g - pg) ** 2 + (2 + (255 - rm) / 256) * (b - pb) ** 2
        if d < bd:
            best, bd = (pr, pg, pb), d
    return best


def find_raw(name: str, frames: int):
    per = []
    for f in range(frames):
        hit = next((RAW / f"{name}.{f}{e}" for e in EXTS if (RAW / f"{name}.{f}{e}").exists()), None)
        per.append(hit)
    if all(per):
        return "per-frame", per
    single = next((RAW / f"{name}{e}" for e in EXTS if (RAW / f"{name}{e}").exists()), None)
    if single:
        return "single", [single]
    return None, []


def remove_background(img: Image.Image) -> Image.Image:
    """Flood-fills the background from the border (tolerance around the median border colour)."""
    img = img.convert("RGBA")
    w, h = img.size
    px = img.load()
    border = [px[x, 0] for x in range(w)] + [px[x, h - 1] for x in range(w)]
    border += [px[0, y] for y in range(h)] + [px[w - 1, y] for y in range(h)]
    bg = tuple(sorted(c[i] for c in border)[len(border) // 2] for i in range(3))

    def close(c, tol):
        return c[3] < 128 or sum(abs(c[i] - bg[i]) for i in range(3)) <= tol

    seen = bytearray(w * h)
    q = deque()
    for x in range(w):
        q.extend([(x, 0), (x, h - 1)])
    for y in range(h):
        q.extend([(0, y), (w - 1, y)])
    while q:
        x, y = q.popleft()
        i = y * w + x
        if seen[i]:
            continue
        seen[i] = 1
        if not close(px[x, y], 120):
            continue
        px[x, y] = (0, 0, 0, 0)
        for nx, ny in ((x + 1, y), (x - 1, y), (x, y + 1), (x, y - 1)):
            if 0 <= nx < w and 0 <= ny < h and not seen[ny * w + nx]:
                q.append((nx, ny))
    # enclosed gaps (between legs, under arms) that are clearly background colour
    for y in range(h):
        for x in range(w):
            if px[x, y][3] and close(px[x, y], 60):
                px[x, y] = (0, 0, 0, 0)
    return img


def split_frames(img: Image.Image, n: int) -> list[Image.Image]:
    if n == 1:
        return [img]
    w, h = img.size
    alpha = img.getchannel("A").load()
    occ = [any(alpha[x, y] for y in range(0, h, 2)) for x in range(w)]
    runs, start = [], None
    for x, o in enumerate(occ + [False]):
        if o and start is None:
            start = x
        elif not o and start is not None:
            runs.append((start, x))
            start = None
    # merge runs separated by tiny gaps, drop specks
    merged = []
    for r in runs:
        if merged and r[0] - merged[-1][1] < w * 0.02:
            merged[-1] = (merged[-1][0], r[1])
        else:
            merged.append(r)
    merged = [r for r in merged if r[1] - r[0] > w * 0.03]
    if len(merged) == n:
        return [img.crop((a, 0, b, h)) for a, b in merged]
    if len(merged) == 1 and merged[0][1] - merged[0][0] < w * 0.6:
        return [img.crop((merged[0][0], 0, merged[0][1], h))]  # one subject: caller derives idle frames
    step = w / n
    return [img.crop((round(i * step), 0, round((i + 1) * step), h)) for i in range(n)]


def to_palette(img: Image.Image) -> Image.Image:
    out = Image.new("RGBA", img.size, (0, 0, 0, 0))
    src, dst = img.load(), out.load()
    cache = {}
    for y in range(img.height):
        for x in range(img.width):
            c = src[x, y]
            if c[3] >= 128:
                k = c[:3]
                if k not in cache:
                    cache[k] = nearest(k)
                dst[x, y] = cache[k] + (255,)
    return out


def add_outline(img: Image.Image) -> Image.Image:
    out = img.copy()
    a = img.getchannel("A").load()
    d = out.load()
    w, h = img.size
    for y in range(h):
        for x in range(w):
            if a[x, y] == 0 and any(
                0 <= x + dx < w and 0 <= y + dy < h and a[x + dx, y + dy] for dx, dy in ((1, 0), (-1, 0), (0, 1), (0, -1))
            ):
                d[x, y] = INK
    return out


def sprite_frames(spr: dict, files: list[Path], mode: str, log: dict) -> list[Image.Image]:
    W, H = spr["size"]
    n = spr["frames"]
    if mode == "per-frame":
        raws = [remove_background(Image.open(f)) for f in files]
    else:
        raws = split_frames(remove_background(Image.open(files[0])), n)
        if len(raws) != n:
            raws = raws[:1]
    crops = []
    for r in raws:
        box = r.getbbox()
        crops.append(r.crop(box) if box else r)
    # fit box leaves room for the outline; units stand on row 29 (+outline row 30)
    if spr["kind"] == "unit":
        fit_w, fit_h, bottom = W - 4, H - 4, H - 3
    else:  # prop
        fit_w, fit_h, bottom = W - 3, int(H * 0.72), H - 2
    mw = max(c.width for c in crops)
    mh = max(c.height for c in crops)
    if spr.get("target_height"):
        # shared roster scale: the tallest frame's subject (held items included) becomes target_height px
        s = spr["target_height"] / mh
        if mw * s > fit_w:
            s = fit_w / mw
            log["fallbacks"].append(
                f"{spr['name']}: too wide for the shared height; scaled to {round(mh * s)} px instead of {spr['target_height']}")
    else:
        s = min(fit_w / mw, fit_h / mh)
    frames = []
    for c in crops:
        small = c.resize((max(1, round(c.width * s)), max(1, round(c.height * s))), Image.BOX)
        canvas = Image.new("RGBA", (W, H), (0, 0, 0, 0))
        canvas.alpha_composite(small, ((W - small.width) // 2, bottom - small.height + 1))
        frames.append(add_outline(to_palette(canvas)))
    if len(frames) < n:
        log["fallbacks"].append(f"{spr['name']}: {len(frames)} raw frame(s) for {n}; derived the rest with a 1 px idle bob")
        base = frames[0]
        while len(frames) < n:
            k = len(frames)
            f = base.copy()
            # frames 1, 2, 3 (then repeating) lift the top 60%, 75% and 35% (head) by 1 px, so the bob gives three
            # distinct frames; the row at each cut is repeated, so there is no gap
            cut = int(H * (0.6, 0.75, 0.35)[(k - 1) % 3])
            f.paste(base.crop((0, 1, W, cut)), (0, 0))
            frames.append(f)
    return frames


def make_seamless(src: Image.Image, n: int, band: int) -> Image.Image:
    """Overlap cross-fade: src is (n+band) square; the band past each far edge is faded onto the near edge.

    Column 0 of the result is source column n, which sits right after column n-1 in the source, so the wrap
    is continuous; only a band-wide strip at each start edge is blended (no whole-tile ghosting).
    """
    def ramp(w: int, h: int, horizontal: bool) -> Image.Image:
        m = Image.new("L", (w, h))
        px = m.load()
        for y in range(h):
            for x in range(w):
                px[x, y] = round(255 * ((x if horizontal else y) / band))
        return m

    cols = src.crop((0, 0, n, n + band))
    blended = Image.composite(cols.crop((0, 0, band, n + band)), src.crop((n, 0, n + band, n + band)), ramp(band, n + band, True))
    cols.paste(blended, (0, 0))
    tile = cols.crop((0, 0, n, n))
    blended = Image.composite(tile.crop((0, 0, n, band)), cols.crop((0, n, n, n + band)), ramp(n, band, False))
    tile.paste(blended, (0, 0))
    return tile


def tile_frames(spr: dict, files: list[Path], mode: str, log: dict) -> list[Image.Image]:
    W, _ = spr["size"]
    n = spr["frames"]
    srcs = files if mode == "per-frame" else files[:1]
    frames = []
    for f in srcs:
        img = Image.open(f).convert("RGB")
        side = int(min(img.size) * 0.8)
        l, t = (img.width - side) // 2, (img.height - side) // 2
        work, band = W * 4, W  # blend a quarter-tile band at 4x working size
        img = img.crop((l, t, l + side, t + side)).resize((work + band, work + band), Image.BOX)
        img = make_seamless(img, work, band).resize((W, W), Image.BOX)
        frames.append(to_palette(img.convert("RGBA")))
    if len(frames) < n:
        log["fallbacks"].append(f"{spr['name']}: {len(frames)} raw frame(s) for {n}; derived the rest by scrolling")
        base = frames[0]
        while len(frames) < n:
            k = len(frames)
            frames.append(ImageChops.offset(base, k * W // n, k * W // n))  # loops back to frame 0 after n steps
    return frames


def main() -> int:
    ap = argparse.ArgumentParser()
    ap.add_argument("--name")
    a = ap.parse_args()
    chained = next((s for s in load_spec()["sprites"] if s["name"] == a.name and s.get("chain")), None)
    if chained:
        print(f"{a.name} is built from its chain: python tools/art/rebuild.py --name {a.name}")
        return 0
    OUT.mkdir(parents=True, exist_ok=True)
    log = {"processed": [], "missing": [], "fallbacks": []}
    for spr in load_spec()["sprites"]:
        if a.name and spr["name"] != a.name:
            continue
        if spr.get("chain"):  # built by rebuild.py from its chain (the chibi heroes), not converted here
            continue
        mode, files = find_raw(spr["name"], spr["frames"])
        if not mode:
            log["missing"].append(spr["name"])
            continue
        if spr["kind"] == "tile":
            frames = tile_frames(spr, files, mode, log)
        else:
            frames = sprite_frames(spr, files, mode, log)
        for i, f in enumerate(frames[: spr["frames"]]):
            f.save(OUT / f"{spr['name']}.{i}.png", format="PNG", optimize=False, compress_level=9)
        log["processed"].append({"name": spr["name"], "mode": mode, "raw": [p.name for p in files]})
    if a.name and LOG.exists():
        old = json.loads(LOG.read_text(encoding="utf-8"))
        log = {
            "processed": [p for p in old.get("processed", []) if p["name"] != a.name] + log["processed"],
            "missing": [m for m in old.get("missing", []) if m != a.name] + log["missing"],
            "fallbacks": [f for f in old.get("fallbacks", []) if not f.startswith(a.name + ":")] + log["fallbacks"],
        }
    LOG.write_text(json.dumps(log, indent=2), encoding="utf-8")
    print(json.dumps(log, indent=2))
    return 0


if __name__ == "__main__":
    sys.exit(main())
