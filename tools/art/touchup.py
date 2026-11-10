"""Touch-up pass: steadies and cleans a converted sprite before the eye pass.

Reads the frames of an already processed sprite (it does not re-run earlier passes) and, in this order:
  --lock RECTS --from N   copies those rectangles from frame N into every frame, so a face or head that the AI drew
                          slightly differently in each pose holds still (only the blink, added later, changes);
  --recolour OLD=NEW,...  swaps palette colours everywhere (for a stray colour the palette snap picked);
  --patch X,Y=COLOUR;...  sets single pixels in every frame (palette name, or "none" for transparent).
Deterministic: same input, same bytes.

usage: python tools/art/touchup.py <source name> <out name> [--work DIR] [--lock "x0,y0,x1,y1;..." --from N]
                               [--recolour "violet.3=ember.3"] [--patch "17,16=ink.6;21,16=ink.6"]
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


def colour(name: str) -> tuple[int, int, int, int]:
    return CLEAR if name == "none" else col(name)


def rects(text: str) -> list[tuple[int, int, int, int]]:
    out = []
    for part in filter(None, text.split(";")):
        x0, y0, x1, y1 = (int(v) for v in part.split(","))
        out.append((x0, y0, x1, y1))
    return out


def main() -> int:
    ap = argparse.ArgumentParser(description="Steady and clean a converted sprite before the eye pass.")
    ap.add_argument("src")
    ap.add_argument("dst")
    ap.add_argument("--work", default=str(WORK), help="folder with the source frames; the output frames are written there too")
    ap.add_argument("--lock", default="", help='"x0,y0,x1,y1;..." inclusive rectangles copied from --from')
    ap.add_argument("--from", dest="ref", type=int, default=0, help="frame the locked rectangles come from")
    ap.add_argument("--recolour", default="", help='"old=new,..." palette names')
    ap.add_argument("--patch", default="", help='"x,y=colour;..." palette name or none')
    a = ap.parse_args()
    out = Path(a.work)
    frames = []
    while (p := out / f"{a.src}.{len(frames)}.png").exists():
        frames.append(Image.open(p).convert("RGBA"))
    if not frames:
        raise SystemExit(f"no frames for {a.src} in {out}")
    ref_frame = frames[a.ref].copy()  # a copy: the reference frame itself is recoloured and patched below
    ref = ref_frame.load()
    swaps = {}
    for pair in filter(None, a.recolour.split(",")):
        old, new = pair.split("=")
        swaps[col(old)] = colour(new)
    patches = []
    for item in filter(None, a.patch.split(";")):
        xy, name = item.split("=")
        x, y = (int(v) for v in xy.split(","))
        patches.append((x, y, colour(name)))
    for i, f in enumerate(frames):
        px = f.load()
        for x0, y0, x1, y1 in rects(a.lock):
            for y in range(y0, y1 + 1):
                for x in range(x0, x1 + 1):
                    px[x, y] = ref[x, y]
        for y in range(f.height):
            for x in range(f.width):
                if px[x, y] in swaps:
                    px[x, y] = swaps[px[x, y]]
        for x, y, c in patches:
            px[x, y] = c
        f.save(out / f"{a.dst}.{i}.png", format="PNG", optimize=False, compress_level=9)
    print(f"wrote {a.dst}.0-{len(frames) - 1}.png to {out}")
    return 0


if __name__ == "__main__":
    sys.exit(main())
