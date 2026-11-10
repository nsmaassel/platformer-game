"""Rebuilds every sprite whose spec entry has a "chain", or checks that the committed frames still match it.

A chain is the exact list of tool runs that makes a sprite: each step is a script in tools/art plus its arguments,
run from the repo root. rebuild.py appends "--work <folder>" to every step itself, so chains never name a folder,
and it runs each chain in a fresh temporary folder, so nothing left over from an earlier run can leak in. The last
step must write frames named after the sprite; those are copied to games/tactics/assets/sprites/sun_steel/.

With --check it writes nothing and fails when a committed frame's pixels differ from what its chain makes now. That
proves the chain in the spec is the one that made the art, and that a tool change didn't quietly alter a finished
sprite. Pixels are compared rather than file bytes, because PNG compression can differ between zlib builds.

usage: python tools/art/rebuild.py [--name SPRITE] [--check]
"""

from __future__ import annotations

import argparse
import shlex
import shutil
import subprocess
import sys
import tempfile
from pathlib import Path

from PIL import Image

HERE = Path(__file__).resolve().parent
REPO = HERE.parents[1]
OUT = REPO / "games" / "tactics" / "assets" / "sprites" / "sun_steel"
sys.path.insert(0, str(HERE))
from pixlib import load_spec  # noqa: E402


def run_chain(spr: dict, work: Path) -> list[Path]:
    for step in spr["chain"]:
        script, *args = shlex.split(step)
        cmd = [sys.executable, str(HERE / script), *args, "--work", str(work)]
        done = subprocess.run(cmd, cwd=REPO, capture_output=True, text=True)
        if done.returncode:
            raise SystemExit(f"{spr['name']}: step failed: {step}\n{done.stdout}{done.stderr}")
    frames = [work / f"{spr['name']}.{i}.png" for i in range(spr["frames"])]
    missing = [p.name for p in frames if not p.exists()]
    if missing:
        raise SystemExit(f"{spr['name']}: the chain's last step must write {', '.join(missing)}")
    return frames


def pixels(path: Path) -> tuple:
    with Image.open(path) as img:
        return img.mode, img.size, img.tobytes()


def main() -> int:
    ap = argparse.ArgumentParser(description="Rebuild chained sprites from their spec chains.")
    ap.add_argument("--name")
    ap.add_argument("--check", action="store_true", help="compare with the committed frames instead of writing")
    a = ap.parse_args()
    chained = [s for s in load_spec()["sprites"] if s.get("chain") and (not a.name or s["name"] == a.name)]
    if not chained:
        print(f"no chained sprite{' named ' + a.name if a.name else 's'} in the spec")
        return 2
    problems = []
    for spr in chained:
        with tempfile.TemporaryDirectory() as tmp:
            for made in run_chain(spr, Path(tmp)):
                committed = OUT / made.name
                if not a.check:
                    shutil.copyfile(made, committed)
                elif not committed.exists():
                    problems.append(f"{made.name}: missing (run tools/art/rebuild.py --name {spr['name']})")
                elif pixels(made) != pixels(committed):
                    problems.append(f"{made.name}: committed pixels differ from what its chain makes")
        print(f"{'checked' if a.check else 'built'} {spr['name']} ({len(spr['chain'])} steps)")
    if problems:
        print("\n".join(problems))
        print(f"FAIL: {len(problems)} frames differ")
        return 1
    print(f"PASS: {len(chained)} sprites {'match their chains' if a.check else 'rebuilt'}")
    return 0


if __name__ == "__main__":
    sys.exit(main())
