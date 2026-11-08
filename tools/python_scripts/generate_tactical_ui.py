import os
from pathlib import Path
from PIL import Image, ImageDraw

def create_cursor(path):
    img = Image.new('RGBA', (16, 16), (0, 0, 0, 0))
    draw = ImageDraw.Draw(img)
    color = (255, 255, 0, 255) # Yellow
    # Corners
    # Top Left
    draw.line([(0, 0), (4, 0)], fill=color, width=1)
    draw.line([(0, 0), (0, 4)], fill=color, width=1)
    # Top Right
    draw.line([(15, 0), (11, 0)], fill=color, width=1)
    draw.line([(15, 0), (15, 4)], fill=color, width=1)
    # Bottom Left
    draw.line([(0, 15), (4, 15)], fill=color, width=1)
    draw.line([(0, 15), (0, 11)], fill=color, width=1)
    # Bottom Right
    draw.line([(15, 15), (11, 15)], fill=color, width=1)
    draw.line([(15, 15), (15, 11)], fill=color, width=1)
    
    img.save(path / 'cursor.png')

def create_overlay(path, name, color):
    img = Image.new('RGBA', (16, 16), color)
    # add a subtle 1px border slightly more opaque
    draw = ImageDraw.Draw(img)
    border_color = (color[0], color[1], color[2], min(255, color[3] + 80))
    draw.rectangle([0, 0, 15, 15], outline=border_color, width=1)
    img.save(path / f'{name}.png')

def create_path_dot(path):
    img = Image.new('RGBA', (16, 16), (0, 0, 0, 0))
    draw = ImageDraw.Draw(img)
    # Draw a 4x4 white circle in the middle
    draw.ellipse([6, 6, 9, 9], fill=(255, 255, 255, 200))
    img.save(path / 'path_dot.png')

def create_panel_bg(path):
    # 48x48 9-slice panel
    img = Image.new('RGBA', (48, 48), (0, 0, 0, 0))
    draw = ImageDraw.Draw(img)
    
    bg_color = (20, 25, 40, 220)
    border_color = (100, 150, 255, 255)
    
    # Fill rounded rectangle
    draw.rounded_rectangle([0, 0, 47, 47], radius=4, fill=bg_color, outline=border_color, width=2)
    
    # Draw some inner sci-fi lines
    draw.line([(4, 12), (12, 12)], fill=(100, 150, 255, 100), width=1)
    draw.line([(4, 43), (12, 43)], fill=(100, 150, 255, 100), width=1)
    
    img.save(path / 'panel_bg.png')

def main():
    ui_dir = Path('games/tactics/assets/sprites/ui')
    ui_dir.mkdir(parents=True, exist_ok=True)
    
    create_cursor(ui_dir)
    create_overlay(ui_dir, 'move_range', (0, 136, 255, 100)) # Blue
    create_overlay(ui_dir, 'attack_range', (255, 50, 50, 100)) # Red
    create_path_dot(ui_dir)
    create_panel_bg(ui_dir)
    
    print('Tactical UI assets generated successfully in', ui_dir)

if __name__ == '__main__':
    main()

