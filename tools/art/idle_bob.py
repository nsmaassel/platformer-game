"""Idle bob: the last step for a converted hero whose frames are all one held key pose.

The AI draws each idle pose slightly differently (ear linings, mane flecks, robe folds), and those small differences
flicker when the frames play. So the chain first holds every frame on one key pose (touchup.py --lock with the whole
canvas), adds the eyes, blink and mane, and then this step adds the motion in code, the same way the code-drawn
heroes move: on the --frames frames, everything above the --seam row drops 1 px while the feet stay put. The seam row
itself is the one that disappears on those frames, so pick a row that only the legs cross (the default is two rows
above the lowest opaque row, as in the code-drawn heroes). Optional --sparkle pixels add a glint on chosen frames.
Deterministic: same input, same bytes.

usage: python tools/art/idle_bob.py <source name> <out name> [--work DIR] [--frames 1,2] [--seam Y]
                                [--sparkle "F:x,y=colour;..."]
"""

from __future__ import annotations

import argparse
import sys
from pathlib import Path

from PIL import Image

HERE = Path(__file__).resolve().parent
REPO = HERE.parents[1]
WORK = REPO / "logs" / "art" / "work"  # intermediate frames (gitignored); rebuild.py passes a fresh folder
sys.path.insert(0, str(HERE))
from pixlib import col  # noqa: E402

CLEAR = (0, 0, 0, 0)


def lowest_row(img: Image.Image) -> int:
    px = img.load()
    return max(y for y in range(img.height) for x in range(img.width) if px[x, y][3])


def bob(img: Image.Image, seam: int) -> Image.Image:
    """Rows above the seam move down 1 px (the seam row is overwritten); rows below it stay."""
    out = img.copy()
    src, dst = img.load(), out.load()
    for y in range(seam, 0, -1):
        for x in range(img.width):
            dst[x, y] = src[x, y - 1]
    for x in range(img.width):
        dst[x, 0] = CLEAR
    return out


def main() -> int:
    ap = argparse.ArgumentParser(description="Add a 1 px idle bob to a held key pose.")
    ap.add_argument("src")
    ap.add_argument("dst")
    ap.add_argument("--work", default=str(WORK), help="folder with the source frames; the output frames are written there too")
    ap.add_argument("--frames", default="1,2", help="frames that bob down (comma-separated)")
    ap.add_argument("--seam", type=int, help="row that is dropped on bob frames (default: lowest opaque row - 2)")
    ap.add_argument("--sparkle", default="", help='"F:x,y=colour;..." glint pixels set on frame F after the bob')
    a = ap.parse_args()
    out = Path(a.work)
    frames = []
    while (p := out / f"{a.src}.{len(frames)}.png").exists():
        frames.append(Image.open(p).convert("RGBA"))
    if not frames:
        raise SystemExit(f"no frames for {a.src} in {out}")
    bobbing = {int(v) for v in a.frames.split(",") if v}
    seam = a.seam if a.seam is not None else lowest_row(frames[0]) - 2
    sparkles: dict[int, list[tuple[int, int, tuple]]] = {}
    for item in filter(None, a.sparkle.split(";")):
        fr, rest = item.split(":")
        xy, name = rest.split("=")
        x, y = (int(v) for v in xy.split(","))
        sparkles.setdefault(int(fr), []).append((x, y, CLEAR if name == "none" else col(name)))
    for i, f in enumerate(frames):
        img = bob(f, seam) if i in bobbing else f
        px = img.load()
        for x, y, c in sparkles.get(i, []):
            px[x, y] = c
        img.save(out / f"{a.dst}.{i}.png", format="PNG", optimize=False, compress_level=9)
    print(f"wrote {a.dst}.0-{len(frames) - 1}.png to {out} (seam row {seam}, bob frames {sorted(bobbing)})")
    return 0


if __name__ == "__main__":
    sys.exit(main())
