"""Eye pass: stamps code-drawn cute eyes and cheeks onto an already converted sprite.

Reads the frames of a converted sprite (it does not re-run the converter), finds the existing eye pixels in each
frame inside a search window, and replaces them with the code lion's eye: 2x3 ink with a white highlight in the
top-left corner, plus a rosy cheek below and outside each eye and a small nose between them. The --blink frame gets
closed eyes (a 2 px line) instead. Deterministic: same input, same bytes.

The defaults fit the lion's face. Other heroes pass their own search window and left/right split, or explicit eye
positions with --eyes when the face has dark markings that would be mistaken for eyes. Give each hero a different
--blink frame so the party doesn't blink in unison.

usage: python tools/art/eye_pass.py <source name> <out name> [--work DIR] [--window x0,y0,x1,y1] [--split X]
                                [--eyes LX,RX,ROW[;LX,RX,ROW...]] [--blink N|-1] [--no-nose]
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

INK, WHITE, CHEEK = col("ink.0"), col("ink.6"), col("crimson.4")
NOSE = col("crimson.0")
EYE_W, EYE_H = 2, 3
# Lion defaults: search window for the old eyes (x0, y0, x1, y1 inclusive), the split between left and right eye,
# and the blink frame.
WINDOW = (13, 14, 20, 18)
SPLIT_X = 17
BLINK = 3


def lum(c) -> float:
    return 0.299 * c[0] + 0.587 * c[1] + 0.114 * c[2]


def dark(px, x: int, y: int) -> bool:
    """A dark interior pixel (not the outline): an eye, the nose or the mouth."""
    c = px[x, y]
    interior = all(px[x + dx, y + dy][3] == 255 for dx, dy in ((1, 0), (-1, 0), (0, 1), (0, -1)))
    return c[3] == 255 and interior and lum(c) < 45


def old_eyes(img: Image.Image, window=WINDOW, split=SPLIT_X) -> tuple[int, int, int]:
    """Returns (left eye x, right eye x, eye row): the first row in the window with dark pixels on both sides.

    The nose and mouth sit lower and lean to one side, so they never start a row with dark pixels on both sides
    before the eyes do.
    """
    px = img.load()
    x0, y0, x1, y1 = window
    for y in range(y0, y1 + 1):
        left = [x for x in range(x0, split) if dark(px, x, y)]
        right = [x for x in range(split, x1 + 1) if dark(px, x, y)]
        if left and right:
            return min(left), min(right), y
    raise SystemExit(f"no eye row found in window {window}; pass --window/--split or --eyes")


def stamp(img: Image.Image, frame: int, window=WINDOW, split=SPLIT_X, eyes=None, blink=BLINK,
          nose: bool = True) -> Image.Image:
    img = img.copy()
    px = img.load()
    lx, rx, bottom = eyes if eyes else old_eyes(img, window, split)
    face = px[(lx + rx) // 2 + 1, bottom - 2]  # skin between the eyes, above the old eye row
    # clear the old dark eye and nose pixels (eye rows plus the nose row, eyes and cheeks wide) first
    hits = [(x, y) for y in range(bottom - EYE_H + 1, bottom + 2) for x in range(lx - 1, rx + EYE_W + 1)
            if dark(px, x, y)]
    for x, y in hits:
        px[x, y] = face
    for ex in (lx, rx):
        if frame == blink:
            for dx in range(EYE_W):
                px[ex + dx, bottom] = INK
        else:
            for dy in range(EYE_H):
                for dx in range(EYE_W):
                    px[ex + dx, bottom - EYE_H + 1 + dy] = INK
            px[ex, bottom - EYE_H + 1] = WHITE
    px[lx - 1, bottom + 1] = CHEEK
    px[rx + EYE_W, bottom + 1] = CHEEK
    if nose:
        nx = (lx + EYE_W + rx) // 2  # centred in the gap between the eyes
        px[nx, bottom + 1] = NOSE
    return img


def ints(text: str, n: int) -> tuple[int, ...]:
    v = tuple(int(t) for t in text.split(","))
    if len(v) != n:
        raise argparse.ArgumentTypeError(f"expected {n} comma-separated integers, got {text!r}")
    return v


def main() -> int:
    ap = argparse.ArgumentParser(description="Stamp cute eyes and cheeks onto a converted sprite.")
    ap.add_argument("src")
    ap.add_argument("dst")
    ap.add_argument("--work", default=str(WORK), help="folder with the source frames; the output frames are written there too")
    ap.add_argument("--window", type=lambda t: ints(t, 4), default=WINDOW, help="x0,y0,x1,y1 search window")
    ap.add_argument("--split", type=int, default=SPLIT_X, help="x where the right eye's half starts")
    ap.add_argument("--eyes", type=lambda t: [ints(v, 3) for v in t.split(";")],
                    help="LX,RX,ROW (left eye x, right eye x, eye bottom row) for all frames, or one triple per frame "
                         "separated by ';' when the face shifts between frames")
    ap.add_argument("--blink", type=int, default=BLINK, help="frame with closed eyes (-1 for none)")
    ap.add_argument("--no-nose", action="store_true", help="keep the sprite's own nose")
    a = ap.parse_args()
    out = Path(a.work)
    count = 0
    while (out / f"{a.src}.{count}.png").exists():
        count += 1
    if a.eyes and len(a.eyes) not in (1, count):
        raise SystemExit(f"--eyes has {len(a.eyes)} triples; give one, or one per frame ({count})")
    i = 0
    while (p := out / f"{a.src}.{i}.png").exists():
        eyes = (a.eyes[i] if len(a.eyes) > 1 else a.eyes[0]) if a.eyes else None
        img = stamp(Image.open(p).convert("RGBA"), i, a.window, a.split, eyes, a.blink, not a.no_nose)
        img.save(out / f"{a.dst}.{i}.png", format="PNG", optimize=False, compress_level=9)
        i += 1
    if not i:
        raise SystemExit(f"no frames for {a.src} in {out}")
    print(f"wrote {a.dst}.0-{i - 1}.png to {out}")
    return 0


if __name__ == "__main__":
    sys.exit(main())
