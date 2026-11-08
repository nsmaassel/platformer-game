import os
import glob
import uuid

for png in glob.glob('**/*.png', recursive=True):
    if png.startswith('.godot'): continue
    if 'sprites-review.png' in png: continue
    
    import_path = png + '.import'
    if not os.path.exists(import_path):
        uid = f'uid://{uuid.uuid4().hex[:12]}'
        with open(import_path, 'w') as f:
            f.write(f'''[remap]

importer="texture"
type="CompressedTexture2D"
uid="{uid}"
path="res://.godot/imported/{os.path.basename(png)}-{uuid.uuid4().hex[:32]}.ctex"
metadata={{
"vram_texture": false
}}

[deps]

source_file="res://{png.replace(chr(92), '/')}"
dest_files=["res://.godot/imported/{os.path.basename(png)}-{uuid.uuid4().hex[:32]}.ctex"]

[params]

compress/mode=0
compress/high_quality=false
compress/lossy_quality=0.7
compress/uastc_level=0
compress/rdo_quality_loss=0.0
compress/hdr_compression=1
compress/normal_map=0
compress/channel_pack=0
mipmaps/generate=false
mipmaps/limit=-1
roughness/mode=0
roughness/src_normal=""
process/channel_remap/red=0
process/channel_remap/green=1
process/channel_remap/blue=2
process/channel_remap/alpha=3
process/fix_alpha_border=true
process/premult_alpha=false
process/normal_map_invert_y=false
process/hdr_as_srgb=false
process/hdr_clamp_exposure=false
process/size_limit=0
detect_3d/compress_to=1
''')
        print(f'Created {import_path}')

