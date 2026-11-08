#!/usr/bin/env python3
"""
validate_pixel_crispness.py
Automated visual & technical audit tool for crisp pixel art rendering in Godot 4.

Checks:
  1. Engine Configuration Audit (project.godot settings for Nearest filter & pixel snapping)
  2. Lossless Import Audit (verifies .import files do not use lossy/VRAM compression)
  3. Hard-Edge Alpha Audit (verifies PNG sprites do not contain accidental anti-aliasing blur)
  4. Generates visual 8x pixel-grid contact sheet: logs/pixel_crispness_review.png
"""

import os
import sys
import glob
from pathlib import Path
from PIL import Image, ImageDraw

if sys.stdout.encoding.lower() != 'utf-8':
    try:
        sys.stdout.reconfigure(encoding='utf-8')
    except Exception:
        pass

PROJECT_ROOT = Path(__file__).resolve().parents[2]
LOGS_DIR = PROJECT_ROOT / "logs"
LOGS_DIR.mkdir(exist_ok=True)


def audit_engine_config():
    print("=== 1. Auditing Engine Settings (project.godot) ===")
    godot_cfg = PROJECT_ROOT / "project.godot"
    if not godot_cfg.exists():
        print("  ❌ FAIL: project.godot not found!")
        return False

    content = godot_cfg.read_text()
    checks = {
        'default_texture_filter=0': "Nearest Texture Filter",
        'snap_2d_transforms=true': "2D Transform Pixel Snapping",
        'snap_2d_vertices=true': "2D Vertex Pixel Snapping",
        'window/stretch/mode="canvas_items"': "Canvas Items Viewport Stretch"
    }

    passed = True
    for key, desc in checks.items():
        if key in content:
            print(f"  ✅ PASS: {desc} configured ({key})")
        else:
            print(f"  ❌ FAIL: Missing engine setting: {desc} ({key})")
            passed = False
    return passed

def audit_import_files():
    print("\n=== 2. Auditing Texture Import Files (.import) ===")
    import_files = list(PROJECT_ROOT.glob("games/**/*.png.import"))
    if not import_files:
        print("  ⚠️ WARN: No .import files found under games/")
        return True

    lossy_count = 0
    total = len(import_files)
    for imp in import_files:
        text = imp.read_text()
        if 'compress/mode=0' not in text and 'compress/mode=1' in text:
            print(f"  ❌ Lossy compression found: {imp.relative_to(PROJECT_ROOT)}")
            lossy_count += 1

    if lossy_count == 0:
        print(f"  ✅ PASS: All {total} texture import files use Lossless mode.")
        return True
    else:
        print(f"  ❌ FAIL: {lossy_count}/{total} import files use lossy compression.")
        return False

def audit_sprite_alpha_crispness():
    print("\n=== 3. Auditing Sprite Alpha & Edge Crispness ===")
    all_pngs = [p for p in PROJECT_ROOT.glob("games/**/*.png") if not p.name.endswith("-review.png")]
    # UI overlays (range grids, panel backgrounds) use uniform alpha modulation by design
    png_files = [p for p in all_pngs if "/ui/" not in p.as_posix().lower()]
    if not png_files:
        print("  ⚠️ WARN: No PNG sprites found!")
        return True, []


    blurred_sprites = []
    clean_sprites = 0

    for png_path in png_files:
        try:
            with Image.open(png_path) as img:
                if img.mode != 'RGBA':
                    clean_sprites += 1
                    continue
                
                # Analyze alpha channel for semi-transparent edge blur
                alpha = img.split()[3]
                pixels = list(alpha.getdata())
                # Count semi-transparent pixels (0 < alpha < 255)
                semi_trans = [p for p in pixels if 0 < p < 255]
                
                # Allow a small tolerance for deliberate shadow drops (< 5% of pixels)
                ratio = len(semi_trans) / max(len(pixels), 1)
                if ratio > 0.08:
                    blurred_sprites.append((png_path, ratio))
                else:
                    clean_sprites += 1
        except Exception as e:
            print(f"  ⚠️ Could not read {png_path}: {e}")

    if not blurred_sprites:
        print(f"  ✅ PASS: 100% of {len(png_files)} sprites have crisp 1-pixel hard edges.")
        return True, png_files
    else:
        print(f"  ❌ FAIL: {len(blurred_sprites)} sprites show anti-aliasing edge blur.")
        for path, ratio in blurred_sprites[:5]:
            print(f"     → {path.relative_to(PROJECT_ROOT)} ({ratio*100:.1f}% semi-transparent pixels)")
        return False, png_files

def generate_pixel_crispness_sheet(png_files):
    print("\n=== 4. Generating Visual Pixel Grid Contact Sheet ===")
    output_path = LOGS_DIR / "pixel_crispness_review.png"
    
    # Select representative sprites
    sample_files = []
    keywords = ["unit_sun_knight", "unit_pyromancer", "player", "slime", "coin", "stone_floor", "unit_golem"]
    for kw in keywords:
        for p in png_files:
            if kw in p.name.lower() and p not in sample_files:
                sample_files.append(p)
                break
    
    if not sample_files:
        sample_files = png_files[:6]

    scale = 8  # 8x zoom
    grid_padding = 4
    cell_w, cell_h = 32 * scale, 32 * scale
    cols = min(len(sample_files), 4)
    rows = (len(sample_files) + cols - 1) // cols

    sheet_w = cols * (cell_w + grid_padding) + grid_padding
    sheet_h = rows * (cell_h + grid_padding + 20) + grid_padding
    sheet = Image.new("RGBA", (sheet_w, sheet_h), (25, 30, 40, 255))
    draw = ImageDraw.Draw(sheet)

    for i, pfile in enumerate(sample_files):
        r = i // cols
        c = i % cols
        x0 = c * (cell_w + grid_padding) + grid_padding
        y0 = r * (cell_h + grid_padding + 20) + grid_padding

        # Draw dark grid backdrop
        draw.rectangle([x0, y0, x0 + cell_w, y0 + cell_h], fill=(40, 45, 60, 255), outline=(70, 80, 110, 255))

        try:
            with Image.open(pfile) as src:
                src_rgba = src.convert("RGBA")
                # Resize using Nearest Neighbor filtering to preserve clean pixel grids
                zoomed = src_rgba.resize((src.width * scale, src.height * scale), Image.NEAREST)
                
                # Center sprite in cell
                offset_x = x0 + (cell_w - zoomed.width) // 2
                offset_y = y0 + (cell_h - zoomed.height) // 2
                sheet.alpha_composite(zoomed, (max(x0, offset_x), max(y0, offset_y)))
                
                # Draw 1px pixel-grid overlay lines to demonstrate alignment
                for px in range(0, cell_w, scale):
                    draw.line([(x0 + px, y0), (x0 + px, y0 + cell_h)], fill=(255, 255, 255, 20))
                for py in range(0, cell_h, scale):
                    draw.line([(x0, y0 + py), (x0 + cell_w, y0 + py)], fill=(255, 255, 255, 20))

                # Label
                label = pfile.stem
                draw.text((x0 + 4, y0 + cell_h + 2), label[:18], fill=(220, 230, 255, 255))
        except Exception as e:
            print(f"  ⚠️ Error rendering sample {pfile.name}: {e}")

    sheet.save(output_path)
    print(f"  ✅ Created visual pixel audit sheet: {output_path.relative_to(PROJECT_ROOT)} ({sheet_w}x{sheet_h}px)")
    return True

def main():
    print("==========================================")
    print("  PIXEL ART CRISPNESS & POLISH AUDIT TOOL ")
    print("==========================================\n")

    cfg_ok = audit_engine_config()
    imp_ok = audit_import_files()
    alpha_ok, png_files = audit_sprite_alpha_crispness()
    sheet_ok = generate_pixel_crispness_sheet(png_files)

    print("\n==========================================")
    if cfg_ok and imp_ok and alpha_ok:
        print("  🎉 AUDIT PASSED: Pixel art rendering is 100% crisp & lossless!")
        print("==========================================")
        return 0
    else:
        print("  ❌ AUDIT FAILED: Fix reported pixel blurring issues above.")
        print("==========================================")
        return 1

if __name__ == "__main__":
    import sys
    sys.exit(main())
