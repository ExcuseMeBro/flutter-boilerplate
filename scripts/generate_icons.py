"""Generate flat 2048 launcher icons for iOS and Android (requires Pillow)."""
from pathlib import Path
from PIL import Image, ImageDraw, ImageFont

ROOT = Path(__file__).resolve().parents[1]
IOS = ROOT / 'ios/Runner/Assets.xcassets/AppIcon.appiconset'
ANDROID = ROOT / 'android/app/src/main/res'
FONT = '/System/Library/Fonts/Avenir Next.ttc'
SIZE = 1024
BACKGROUND = (19, 31, 48)
TILE = (255, 202, 126)
INK = (19, 31, 48)


def draw_tile(image, bounds, font_size):
    """A single flat tile; no gradients, borders, lighting or drop shadows."""
    draw = ImageDraw.Draw(image)
    draw.rounded_rectangle(bounds, radius=int((bounds[2] - bounds[0]) * .19), fill=TILE)
    font = ImageFont.truetype(FONT, font_size, index=1)
    cx = (bounds[0] + bounds[2]) // 2
    cy = (bounds[1] + bounds[3]) // 2
    offset = int(font_size * .43)
    draw.text((cx, cy - offset), '20', anchor='mm', font=font, fill=INK)
    draw.text((cx, cy + offset), '48', anchor='mm', font=font, fill=INK)


# Let the OS apply the iOS icon mask. The background deliberately reaches the edges.
image = Image.new('RGB', (SIZE, SIZE), BACKGROUND)
draw_tile(image, (164, 164, 860, 860), 306)
for name, size in [
    ('Icon-App-20x20@1x.png', 20), ('Icon-App-20x20@2x.png', 40),
    ('Icon-App-20x20@3x.png', 60), ('Icon-App-29x29@1x.png', 29),
    ('Icon-App-29x29@2x.png', 58), ('Icon-App-29x29@3x.png', 87),
    ('Icon-App-40x40@1x.png', 40), ('Icon-App-40x40@2x.png', 80),
    ('Icon-App-40x40@3x.png', 120), ('Icon-App-60x60@2x.png', 120),
    ('Icon-App-60x60@3x.png', 180), ('Icon-App-76x76@1x.png', 76),
    ('Icon-App-76x76@2x.png', 152), ('Icon-App-83.5x83.5@2x.png', 167),
    ('Icon-App-1024x1024@1x.png', 1024),
]:
    image.resize((size, size), Image.Resampling.LANCZOS).save(IOS / name)

for density, size in [('mdpi', 48), ('hdpi', 72), ('xhdpi', 96),
                      ('xxhdpi', 144), ('xxxhdpi', 192)]:
    folder = ANDROID / f'mipmap-{density}'
    folder.mkdir(exist_ok=True)
    image.resize((size, size), Image.Resampling.LANCZOS).save(folder / 'ic_launcher.png')

# Android adaptive icon: separate transparent foreground and full-bleed background.
foreground = Image.new('RGBA', (SIZE, SIZE), (0, 0, 0, 0))
draw_tile(foreground, (230, 230, 794, 794), 250)
for density, size in [('mdpi', 108), ('hdpi', 162), ('xhdpi', 216),
                      ('xxhdpi', 324), ('xxxhdpi', 432)]:
    foreground.resize((size, size), Image.Resampling.LANCZOS).save(
        ANDROID / f'mipmap-{density}' / 'ic_launcher_foreground.png')

print('Generated flat iOS and Android 2048 icons.')
