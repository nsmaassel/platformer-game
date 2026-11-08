"""Contract checks for the Sun & Steel sprites in games/tactics/assets/sprites/sun_steel/.

usage: python tools/art/validate.py [--name SPRITE] [--hashes]
Exit 0 = every sprite in tools/art/spec/sprites.json passes. Prints one line per problem.
"""

from __future__ import annotations

import argparse
import hashlib
import sys
from pathlib import Path

from PIL import Image

sys.path.insert(0, str(Path(__file__).resolve().parent))
from pixlib import PALETTE_RGB, load_spec  # noqa: E402

ROOT = Path(__file__).resolve().parents[2]
OUT = ROOT / "games" / "tactics" / "assets" / "sprites" / "sun_steel"


def load(path: Path):
    img = Image.open(path)
    img.load()
    return img


def stats(img: Image.Image):
    w, h = img.size
    px = list(img.getdata())
    opaque = [(i % w, i // w) for i, p in enumerate(px) if p[3] == 255]
    return w, h, px, opaque


def seam_ok(img: Image.Image) -> tuple[bool, str]:
    """Each wrap seam must be no rougher than the tile's own rougher interior lines.

    For the x seam, every interior column boundary k gets a score (mean colour step between columns k
    and k+1); the seam (last column -> first) must not exceed the 90th-percentile interior score by
    more than 25% + 4. Same for rows. A tile with real edges inside passes; a visible wrap line fails.
    """
    w, h = img.size
    p = img.load()

    def d(a, b):
        return sum(abs(a[i] - b[i]) for i in range(3)) / 3

    def p90(vals):
        vals = sorted(vals)
        return vals[min(len(vals) - 1, int(len(vals) * 0.9))]

    cols = [sum(d(p[x, y], p[x + 1, y]) for y in range(h)) / h for x in range(w - 1)]
    rows = [sum(d(p[x, y], p[x, y + 1]) for x in range(w)) / w for y in range(h - 1)]
    sx = sum(d(p[w - 1, y], p[0, y]) for y in range(h)) / h
    sy = sum(d(p[x, h - 1], p[x, 0]) for x in range(w)) / w
    lx, ly = 1.25 * p90(cols) + 4, 1.25 * p90(rows) + 4
    ok = sx <= lx and sy <= ly
    return ok, f"seam x={sx:.1f} (limit {lx:.1f}) y={sy:.1f} (limit {ly:.1f})"


def check_sprite(out: Path, spr: dict, problems: list[str], hashes: bool) -> None:
    name, (W, H), n = spr["name"], spr["size"], spr["frames"]
    kind = spr["kind"]
    frames = []
    for f in range(n):
        path = out / f"{name}.{f}.png"
        if not path.exists():
            problems.append(f"{name}.{f}: missing {path.relative_to(ROOT)}")
            continue
        img = load(path)
        if hashes:
            print(f"{hashlib.sha256(path.read_bytes()).hexdigest()[:16]}  {path.relative_to(ROOT)}")
        if img.mode != "RGBA":
            problems.append(f"{name}.{f}: mode {img.mode}, expected RGBA")
            img = img.convert("RGBA")
        if img.size != (W, H):
            problems.append(f"{name}.{f}: size {img.size}, expected {(W, H)}")
            continue
        w, h, px, opaque = stats(img)
        bad_alpha = sum(1 for p in px if p[3] not in (0, 255))
        if bad_alpha:
            problems.append(f"{name}.{f}: {bad_alpha} pixels with partial alpha (must be 0 or 255)")
        off = {p[:3] for p in px if p[3] == 255 and p[:3] not in PALETTE_RGB}
        if off:
            problems.append(f"{name}.{f}: {len(off)} off-palette colours, e.g. {sorted(off)[:3]}")
        cover = len(opaque) / (w * h)
        if kind == "tile" and len(opaque) != w * h:
            problems.append(f"{name}.{f}: tile must be fully opaque ({w * h - len(opaque)} transparent px)")
        if kind == "tile" and len(opaque) == w * h:
            ok, msg = seam_ok(img)
            if not ok:
                problems.append(f"{name}.{f}: not seamless ({msg})")
        if kind == "unit":
            if not 0.15 <= cover <= 0.80:
                problems.append(f"{name}.{f}: coverage {cover:.0%} outside 15-80%")
            if opaque:
                low = max(y for _, y in opaque)
                if not 28 <= low <= 31:
                    problems.append(f"{name}.{f}: lowest opaque row {low}, feet must sit on rows 28-30 (31 for shadow)")
                target = spr.get("target_height")
                if target:
                    tall = low - min(y for _, y in opaque) + 1  # includes the 1 px outline top and bottom
                    if not target + 1 <= tall <= target + 3:
                        problems.append(f"{name}.{f}: body height {tall - 2} px, roster height is {target}")
        if kind == "prop":
            if cover >= 0.999:
                problems.append(f"{name}.{f}: prop needs a transparent background")
            elif not 0.20 <= cover <= 0.85:
                problems.append(f"{name}.{f}: coverage {cover:.0%} outside 20-85%")
        if not opaque:
            problems.append(f"{name}.{f}: empty sprite")
        frames.append((img.tobytes(), opaque))

    if n > 1 and len(frames) == n:
        unique = len({b for b, _ in frames})
        if unique < max(2, n - 1):
            problems.append(f"{name}: only {unique} distinct frames of {n}")
        if kind == "unit":
            def centre(op):
                return (sum(x for x, _ in op) / len(op), sum(y for _, y in op) / len(op))

            c0 = centre(frames[0][1])
            low0 = max(y for _, y in frames[0][1])
            for i, (_, op) in enumerate(frames[1:], 1):
                c = centre(op)
                if abs(c[0] - c0[0]) > 1.5 or abs(c[1] - c0[1]) > 1.5:
                    problems.append(f"{name}.{i}: silhouette centre drifts ({c[0]:.1f},{c[1]:.1f}) vs ({c0[0]:.1f},{c0[1]:.1f})")
                low = max(y for _, y in op)
                if abs(low - low0) > 1:
                    problems.append(f"{name}.{i}: feet row {low} vs {low0} on frame 0")


def main() -> int:
    ap = argparse.ArgumentParser()
    ap.add_argument("--name")
    ap.add_argument("--hashes", action="store_true")
    a = ap.parse_args()
    spec = load_spec()["sprites"]
    if a.name:
        spec = [s for s in spec if s["name"] == a.name]
        if not spec:
            print(f"unknown sprite {a.name}")
            return 2
    # a sprite marked "pending" in the spec is skipped until its first frame exists, then checked like any other
    pending = [s for s in spec if s.get("pending") and not (OUT / f"{s['name']}.0.png").exists()]
    spec = [s for s in spec if s not in pending]
    for s in pending:
        print(f"PENDING {s['name']}: {s['pending']}")
    problems: list[str] = []
    for spr in spec:
        check_sprite(OUT, spr, problems, a.hashes)
    files = sum(s["frames"] for s in spec)
    if problems:
        print("\n".join(problems))
        print(f"FAIL: {len(problems)} problems across {files} expected files")
        return 1
    print(f"PASS: {files} files, 0 problems" + (f" ({len(pending)} sprites pending)" if pending else ""))
    return 0


if __name__ == "__main__":
    sys.exit(main())
