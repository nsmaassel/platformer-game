"""Pixel-art canvas toolkit for Sun & Steel art (palette-locked, binary alpha, deterministic).

Also loads the contract (spec/sprites.json, spec/palette.json) for convert.py and validate.py.

Colours are named "<ramp>.<step>" from spec/palette.json, e.g. "steel.3" or "ink.0".
A Canvas holds RGBA tuples or None (transparent). Save with emit().
"""

from __future__ import annotations

import hashlib
import json
import math
import random
from pathlib import Path

from PIL import Image

ROOT = Path(__file__).resolve().parent
PALETTE_PATH = ROOT / "spec" / "palette.json"
SPEC_PATH = ROOT / "spec" / "sprites.json"


def _hex(h: str) -> tuple[int, int, int, int]:
    h = h.lstrip("#")
    return (int(h[0:2], 16), int(h[2:4], 16), int(h[4:6], 16), 255)


def load_palette() -> dict[str, tuple[int, int, int, int]]:
    raw = json.loads(PALETTE_PATH.read_text(encoding="utf-8"))
    out = {}
    for ramp, values in raw.items():
        if ramp.startswith("_"):
            continue
        for i, v in enumerate(values):
            out[f"{ramp}.{i}"] = _hex(v)
    return out


PALETTE = load_palette()
PALETTE_RGB = {v[:3] for v in PALETTE.values()}


def load_spec() -> dict:
    return json.loads(SPEC_PATH.read_text(encoding="utf-8"))


def col(name: str) -> tuple[int, int, int, int]:
    try:
        return PALETTE[name]
    except KeyError as exc:
        raise KeyError(f"unknown palette colour {name!r}") from exc


def rng_for(name: str, frame: int = 0) -> random.Random:
    """Deterministic RNG per sprite/frame."""
    seed = int(hashlib.sha256(f"{name}:{frame}".encode()).hexdigest()[:16], 16)
    return random.Random(seed)


class Canvas:
    def __init__(self, w: int, h: int, fill: str | None = None):
        self.w, self.h = w, h
        c = col(fill) if fill else None
        self.px = [[c for _ in range(w)] for _ in range(h)]

    # -- basic access -------------------------------------------------------
    def inside(self, x: int, y: int) -> bool:
        return 0 <= x < self.w and 0 <= y < self.h

    def set(self, x: int, y: int, c: str | None, wrap: bool = False) -> None:
        x, y = int(math.floor(x)), int(math.floor(y))
        if wrap:
            x %= self.w
            y %= self.h
        if self.inside(x, y):
            self.px[y][x] = col(c) if c else None

    def get(self, x: int, y: int, wrap: bool = False):
        if wrap:
            x %= self.w
            y %= self.h
        return self.px[y][x] if self.inside(x, y) else None

    def opaque(self, x: int, y: int) -> bool:
        return self.get(x, y) is not None

    # -- shapes -------------------------------------------------------------
    def rect(self, x0: int, y0: int, x1: int, y1: int, c: str | None, wrap: bool = False) -> None:
        """Filled rectangle, inclusive corners."""
        for y in range(min(y0, y1), max(y0, y1) + 1):
            for x in range(min(x0, x1), max(x0, x1) + 1):
                self.set(x, y, c, wrap)

    def line(self, x0: int, y0: int, x1: int, y1: int, c: str | None, wrap: bool = False) -> None:
        x0, y0, x1, y1 = int(x0), int(y0), int(x1), int(y1)
        dx, dy = abs(x1 - x0), -abs(y1 - y0)
        sx, sy = (1 if x0 < x1 else -1), (1 if y0 < y1 else -1)
        err = dx + dy
        while True:
            self.set(x0, y0, c, wrap)
            if x0 == x1 and y0 == y1:
                break
            e2 = 2 * err
            if e2 >= dy:
                err += dy
                x0 += sx
            if e2 <= dx:
                err += dx
                y0 += sy

    def ellipse(self, cx: float, cy: float, rx: float, ry: float, c: str | None, wrap: bool = False) -> None:
        """Filled ellipse sampled at pixel centres (crisp, no anti-aliasing)."""
        for y in range(int(math.floor(cy - ry)) - 1, int(math.ceil(cy + ry)) + 2):
            for x in range(int(math.floor(cx - rx)) - 1, int(math.ceil(cx + rx)) + 2):
                px, py = x + 0.5, y + 0.5
                if rx > 0 and ry > 0 and ((px - cx) / rx) ** 2 + ((py - cy) / ry) ** 2 <= 1.0:
                    self.set(x, y, c, wrap)

    def disc(self, cx: float, cy: float, r: float, c: str | None, wrap: bool = False) -> None:
        self.ellipse(cx, cy, r, r, c, wrap)

    def polygon(self, pts: list[tuple[float, float]], c: str | None, wrap: bool = False) -> None:
        """Filled polygon (even-odd rule) sampled at pixel centres."""
        if len(pts) < 3:
            return
        ys = [p[1] for p in pts]
        for y in range(int(math.floor(min(ys))), int(math.ceil(max(ys))) + 1):
            py = y + 0.5
            xs = []
            for i in range(len(pts)):
                (x0, y0), (x1, y1) = pts[i], pts[(i + 1) % len(pts)]
                if (y0 <= py < y1) or (y1 <= py < y0):
                    xs.append(x0 + (py - y0) * (x1 - x0) / (y1 - y0))
            xs.sort()
            for a, b in zip(xs[0::2], xs[1::2]):
                for x in range(int(math.ceil(a - 0.5)), int(math.floor(b - 0.5)) + 1):
                    self.set(x, y, c, wrap)

    # -- whole-canvas operations -------------------------------------------
    def outline(self, c: str = "ink.0", diagonal: bool = False) -> None:
        """Adds a 1 px outline of colour c around every opaque region (outside only)."""
        add = []
        nbrs = [(1, 0), (-1, 0), (0, 1), (0, -1)]
        if diagonal:
            nbrs += [(1, 1), (-1, -1), (1, -1), (-1, 1)]
        for y in range(self.h):
            for x in range(self.w):
                if self.px[y][x] is None and any(self.opaque(x + dx, y + dy) for dx, dy in nbrs):
                    add.append((x, y))
        for x, y in add:
            self.set(x, y, c)

    def mirror_x(self) -> None:
        """Copies the left half onto the right half (for symmetric designs)."""
        for y in range(self.h):
            for x in range(self.w // 2):
                self.px[y][self.w - 1 - x] = self.px[y][x]

    def flip_x(self) -> "Canvas":
        out = Canvas(self.w, self.h)
        out.px = [list(reversed(row)) for row in self.px]
        return out

    def blit(self, other: "Canvas", ox: int, oy: int) -> None:
        for y in range(other.h):
            for x in range(other.w):
                p = other.px[y][x]
                if p is not None and self.inside(ox + x, oy + y):
                    self.px[oy + y][ox + x] = p

    def copy(self) -> "Canvas":
        out = Canvas(self.w, self.h)
        out.px = [row[:] for row in self.px]
        return out

    def to_image(self) -> Image.Image:
        img = Image.new("RGBA", (self.w, self.h), (0, 0, 0, 0))
        img.putdata([p if p is not None else (0, 0, 0, 0) for row in self.px for p in row])
        return img


def emit(out_dir: str | Path, name: str, frame: int, canvas: Canvas) -> Path:
    """Writes <out_dir>/<name>.<frame>.png deterministically (for code-drawn sprites)."""
    out = Path(out_dir)
    out.mkdir(parents=True, exist_ok=True)
    path = out / f"{name}.{frame}.png"
    canvas.to_image().save(path, format="PNG", optimize=False, compress_level=9)
    return path
