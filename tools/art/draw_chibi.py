"""Code-drawn chibi sprites: the snow leopard Frost Blade, the lamb Cleric and the pebble Golem.

Their pale or glowing designs turned to speckle in crisp_convert.py, so they are drawn here in logical pixels with
pixlib, from the AI concepts in games/tactics/art/raw/<name>_chibi.png, using the converted heroes as the style
target (1 px ink outline, 2x3 eyes with a white highlight, rosy cheeks). An upper assembly drops 1 px on frames 1-2
while the feet stay planted; no random texture. Deterministic: same input, same bytes.

usage: python tools/art/draw_chibi.py <unit_frost_blade|unit_cleric|unit_golem> [--work DIR]
"""

from __future__ import annotations

import argparse
import sys
from pathlib import Path

HERE = Path(__file__).resolve().parent
REPO = HERE.parents[1]
WORK = REPO / "logs" / "art" / "work"  # intermediate frames (gitignored); rebuild.py passes a fresh folder
sys.path.insert(0, str(HERE))
from pixlib import Canvas, emit  # noqa: E402

BOB = (0, 1, 1, 0)


def face(c, frame, blink, left=15, right=20, y=15):
    """Shared party eyes, matching the converted heroes' code eye pass."""
    for x in (left, right):
        if frame == blink:
            c.line(x, y + 2, x + 1, y + 2, "ink.0")
        else:
            c.rect(x, y, x + 1, y + 2, "ink.0")
            c.set(x, y, "ink.6")
    c.set(left - 1, y + 3, "crimson.4")
    c.set(right + 2, y + 3, "crimson.4")
    c.set(18, y + 3, "ink.0")


def frost_blade(frame):
    c, u = Canvas(32, 32), Canvas(32, 32)

    def rosette(canvas, x, y):
        # Broken 3x3 ring: a shaded fur centre, never a filled square.
        canvas.set(x + 1, y + 1, "steel.3")
        for dx, dy in ((1, 0), (0, 1), (2, 1), (0, 2), (1, 2)):
            canvas.set(x + dx, y + dy, "steel.1")

    # Blue-grey paws remain planted through the whole breathing cycle.
    c.rect(13, 26, 15, 29, "steel.4")
    c.rect(19, 26, 21, 29, "steel.4")
    rosette(c, 13, 26)
    rosette(c, 19, 26)
    c.line(13, 29, 15, 29, "steel.5")
    c.line(19, 29, 20, 29, "steel.5")

    # Long, leg-thick tail sweeps out and up, with a dark rounded tip.
    u.polygon([(12, 27), (8, 27), (4, 25), (2, 22), (2, 17),
               (3, 14), (5, 13), (8, 13), (9, 15), (8, 17),
               (6, 17), (6, 20), (7, 23), (10, 24), (12, 24)], "steel.4")
    u.line(3, 17, 3, 21, "steel.5")
    u.line(4, 23, 7, 25, "steel.5")
    u.line(8, 26, 11, 26, "steel.3")
    u.line(6, 13, 7, 13, "steel.1")
    u.rect(7, 14, 8, 15, "steel.1")
    u.line(6, 16, 7, 16, "steel.1")
    u.line(2, 18, 5, 19, "steel.1")
    u.line(2, 19, 5, 20, "steel.1")
    u.line(3, 22, 6, 21, "steel.1")
    u.line(3, 23, 6, 22, "steel.1")
    u.line(6, 25, 8, 23, "steel.1")
    u.line(10, 26, 10, 24, "steel.1")

    # Short half-cape and compact blue cuirass, one steel shoulder plate.
    u.polygon([(11, 20), (19, 20), (22, 26), (17, 26),
               (11, 27), (9, 25)], "blue.1")
    u.line(10, 24, 11, 22, "blue.3")
    u.rect(13, 21, 21, 25, "blue.2")
    u.rect(15, 22, 19, 24, "blue.3")
    u.line(15, 22, 18, 22, "blue.4")
    u.line(14, 26, 20, 26, "steel.1")
    u.rect(17, 25, 19, 26, "steel.4")
    u.ellipse(12, 22, 2.5, 2, "steel.1")
    u.ellipse(11.5, 21.5, 2, 1.5, "steel.4")
    u.line(11, 21, 12, 21, "steel.5")
    u.rect(10, 23, 12, 26, "steel.4")
    u.rect(21, 23, 23, 25, "steel.4")
    rosette(u, 21, 23)
    u.line(11, 23, 12, 23, "steel.5")

    # Round cub head; pale face stays separate from the blue-grey crown.
    u.line(12, 21, 21, 21, "ink.0")
    u.ellipse(17, 15.5, 7, 5.5, "steel.3")
    u.ellipse(16, 14.5, 5.5, 4.5, "steel.4")
    u.ellipse(18, 18, 5.5, 3, "steel.5")
    u.ellipse(18.5, 19, 3.5, 1.5, "ink.6")
    # Short, wide, round ears sit in front of the crown, dark backs visible.
    for x in (10, 20):
        u.line(x + 1, 9, x + 2, 9, "steel.1")
        u.rect(x, 10, x + 3, 11, "steel.1")
        u.line(x + 1, 12, x + 2, 12, "steel.3")
        u.line(x + 1, 10, x + 1, 11, "steel.5")
    # Forehead dots and open crown/cheek rosettes frame the pale muzzle.
    u.line(14, 11, 15, 11, "steel.1")
    rosette(u, 16, 11)
    u.set(20, 11, "steel.1")
    rosette(u, 11, 14)
    u.line(22, 13, 22, 14, "steel.1")
    face(u, frame, blink=3)
    u.set(18, 18, "crimson.3")
    u.set(18, 19, "steel.1")
    u.line(17, 20, 19, 20, "steel.1")
    # Blue scarf is one readable band underneath the bright chin.
    u.line(14, 21, 20, 21, "blue.1")
    u.line(15, 21, 19, 21, "blue.4")
    # A coherent shoulder plate survives the head overlap at this scale.
    u.line(10, 22, 13, 22, "steel.4")
    u.line(10, 23, 13, 23, "steel.1")
    u.line(10, 22, 11, 22, "steel.5")
    u.line(20, 23, 20, 25, "blue.1")
    u.line(15, 26, 18, 26, "steel.5")
    # Exposed forearm and haunch carry readable rings below the blue plates.
    rosette(u, 10, 24)
    u.rect(12, 25, 14, 27, "steel.4")
    rosette(u, 12, 25)

    # A short outward-pointing crystal sword clears the face and paws.
    u.line(23, 25, 24, 24, "steel.1")
    u.line(22, 23, 25, 26, "blue.1")
    u.set(22, 23, "steel.4")
    u.polygon([(24, 23), (27, 18), (29, 17), (29, 20),
               (26, 24)], "teal.3")
    u.line(25, 22, 28, 18, "teal.5")
    u.line(26, 22, 28, 20, "teal.4")
    u.set(*((27, 19), (26, 20), (25, 21), (28, 18))[frame], "ink.6")
    c.blit(u, 0, BOB[frame])
    c.outline()
    return c


def cleric(frame):
    c, u = Canvas(32, 32), Canvas(32, 32)
    # Warm little hooves distinguish the lamb from the ice fighter.
    c.rect(13, 27, 15, 29, "stone.3")
    c.rect(19, 27, 21, 29, "stone.3")
    c.line(13, 28, 15, 28, "skin.4")
    c.line(19, 28, 20, 28, "skin.4")

    # Wide gold vestments frame the white robe and round sun pendant.
    u.polygon([(12, 21), (21, 21), (23, 27), (12, 27),
               (10, 26)], "ink.5")
    u.rect(14, 22, 19, 26, "ink.6")
    u.line(12, 22, 11, 26, "gold.3")
    u.line(13, 23, 12, 26, "gold.4")
    u.line(20, 22, 21, 26, "gold.4")
    u.line(12, 27, 21, 27, "gold.3")
    u.line(13, 27, 19, 27, "gold.4")
    u.ellipse(10.5, 23, 2, 2, "ink.5")
    u.set(10, 22, "ink.6")
    u.line(9, 24, 11, 24, "gold.4")
    u.line(10, 25, 11, 25, "skin.4")
    u.ellipse(22.5, 23, 2, 2, "ink.6")
    u.line(22, 24, 23, 24, "gold.3")
    u.set(23, 25, "skin.4")
    u.line(13, 21, 17, 23, "gold.4")
    u.line(20, 21, 18, 23, "gold.3")
    u.rect(16, 22, 18, 24, "gold.2")
    u.line(16, 22, 18, 22, "gold.4")
    u.set(16, 23, "gold.4")
    u.set(17, 23, "gold.5")

    # Five smooth wool lobes rather than many tiny curls.
    u.ellipse(16.5, 16, 7, 5, "ink.5")
    u.ellipse(12, 17, 3, 4, "ink.6")
    u.ellipse(21.5, 17, 2.5, 4, "ink.5")
    u.ellipse(18, 17, 5.5, 4, "skin.4")
    u.ellipse(17.5, 16.5, 4.5, 3.5, "gold.5")
    u.line(14, 14, 19, 14, "stone.5")
    u.line(21, 16, 21, 18, "stone.5")
    u.line(13, 16, 13, 18, "stone.5")
    # Floppy cream ears sit below the two curled horns.
    u.polygon([(11, 14), (8, 16), (9, 17), (12, 16)], "skin.4")
    u.line(9, 16, 10, 16, "skin.2")
    u.polygon([(22, 14), (25, 16), (24, 17), (22, 16)], "skin.4")
    u.set(24, 16, "skin.2")
    u.ellipse(13.5, 12.5, 2.5, 2.5, "ink.6")
    u.ellipse(17, 11.5, 2.5, 2.5, "ink.6")
    u.ellipse(20.5, 12.5, 2.5, 2.5, "ink.5")
    u.line(19, 11, 20, 11, "ink.6")
    u.line(15, 13, 15, 14, "ink.5")
    u.set(19, 14, "ink.4")
    u.line(11, 19, 12, 20, "ink.5")
    # Gold horn curls are in front of the wool so neither gets swallowed.
    for x in (9, 22):
        u.rect(x, 11, x + 2, 13, "gold.3")
        u.line(x, 11, x + 1, 11, "gold.5")
        u.set(x + 1, 12, "gold.1")
        u.set(x + 2, 13, "gold.2")
    face(u, frame, blink=1)
    u.line(17, 20, 19, 20, "skin.1")

    # Short sceptre, with a flat round sun disc and a travelling twinkle.
    u.line(24, 26, 26, 21, "gold.1")
    u.line(24, 25, 26, 21, "gold.4")
    u.disc(26.5, 20, 2.5, "gold.2")
    u.disc(26.5, 19.5, 2, "gold.4")
    u.line(25, 18, 26, 18, "gold.5")
    u.set(*((25, 19), (26, 18), (27, 19), (26, 20))[frame], "ink.6")
    c.blit(u, 0, BOB[frame])
    c.outline()
    return c


def pebble(c, cx, cy, rx, ry, base="stone.2", light="stone.3"):
    """One softly stepped stone, with a small upward-facing light plane."""
    c.ellipse(cx, cy, rx, ry, "stone.0")
    c.ellipse(cx - .5, cy - .5, rx - .8, ry - .8, base)
    c.ellipse(cx - 1, cy - 1.5, max(1, rx - 2), max(1, ry - 2), light)


def golem(frame):
    c = Canvas(32, 32)
    u = Canvas(32, 32)
    bob = (0, 1, 0, 0)[frame]
    heat = (3, 4, 4, 3)[frame]

    # A wide stance on little rounded pebble feet, never moving off row 29.
    pebble(c, 11.5, 27.5, 4.5, 2.5, "stone.2", "stone.3")
    pebble(c, 21, 27.5, 4, 2.5, "stone.1", "stone.2")

    # The torso is one large pebble with only a few coherent facets.
    pebble(u, 16, 22, 7.5, 5.5, "stone.1", "stone.2")
    u.ellipse(14, 21.5, 4, 3.5, "stone.2")
    u.line(13, 24, 16, 25, "stone.3")
    u.line(19, 20, 20, 22, "ember.1")
    u.line(20, 22, 19, 24, f"ember.{heat - 1}")
    u.set(20, 22, f"ember.{heat}")

    # Asymmetric small arms, one fist tucked up like a grumpy little boxer.
    pebble(u, 7, 22, 3.5, 4, "stone.2", "stone.3")
    pebble(u, 25, 23, 3.5, 3.5, "stone.1", "stone.2")
    u.line(5, 23, 7, 23, "stone.1")
    u.set(6, 24, "stone.1")
    u.line(24, 24, 26, 24, "stone.0")

    # Big head, turned to the left: a rounded boulder rather than a mask.
    pebble(u, 15.5, 14.5, 8.5, 6.5, "stone.2", "stone.3")
    u.ellipse(12, 11, 3.5, 2, "stone.4")
    u.ellipse(20.5, 16, 2.5, 3.5, "stone.1")
    u.line(20, 10, 20, 12, "stone.1")
    u.line(20, 12, 22, 13, "stone.0")

    # Ember eyes in dark sockets, with low brows and a tiny sulky mouth.
    for x in (10, 16):
        u.rect(x, 14, x + 2, 16, "stone.0")
        if frame == 3:
            u.line(x, 16, x + 1, 16, f"ember.{heat}")
        else:
            u.rect(x, 14, x + 1, 15, f"ember.{heat}")
            u.set(x + 2, 15, "ember.2")
            u.set(x, 14, "gold.5")
            u.set(x + 1, 16, "ember.2")
    u.line(9, 12, 12, 13, "ink.0")
    u.line(16, 13, 19, 12, "ink.0")
    u.set(13, 17, "stone.3")
    u.line(13, 18, 15, 18, "stone.0")
    u.set(12, 19, "stone.0")
    u.set(16, 19, "stone.0")

    # A tiny growing tuft softens the silhouette without resembling a horn.
    wag = (0, 0, 1, 0)[frame]
    u.line(15, 9, 13 + wag, 7, "forest.2")
    u.line(15, 9, 17 + wag, 7, "forest.2")
    u.set(14 + wag, 7, "forest.4")
    u.set(16 + wag, 7, "forest.3")
    u.line(14, 9, 17, 9, "forest.3")
    u.set(14, 8, "forest.5")
    c.blit(u, 0, bob)
    c.outline()
    return c


DRAW = {"unit_frost_blade": frost_blade, "unit_cleric": cleric, "unit_golem": golem}


def main() -> int:
    ap = argparse.ArgumentParser(description="Draw a code-drawn chibi sprite.")
    ap.add_argument("name", choices=sorted(DRAW))
    ap.add_argument("--work", default=str(WORK), help="folder holding the output frames")
    a = ap.parse_args()
    for frame in range(4):
        emit(a.work, a.name, frame, DRAW[a.name](frame))
    print(f"wrote {a.name}.0-3.png to {a.work}")
    return 0


if __name__ == "__main__":
    sys.exit(main())
