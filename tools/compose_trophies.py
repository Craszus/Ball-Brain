"""Setter Blender-gjengivelsene (tools/make_trophies.py) på samme bakgrunn som de andre pokalene:
mørkegrønt, varm glød, skygge og glitter. Bruk: python tools/compose_trophies.py MAPPE"""
import glob
import os
import random
import sys

from PIL import Image, ImageChops, ImageDraw, ImageFilter

S = 768
root = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
out_dir = os.path.join(root, 'assets', 'trophies')


def blob(box, color, blur):
    """Myk lysflekk som kan legges til bildet (svart = ingen endring)."""
    layer = Image.new('RGB', (S, S), (0, 0, 0))
    ImageDraw.Draw(layer).ellipse(box, fill=color)
    return layer.filter(ImageFilter.GaussianBlur(blur))


def sparkle(img, x, y, r):
    layer = Image.new('RGB', (S, S), (0, 0, 0))
    d = ImageDraw.Draw(layer)
    thin = r * 0.12
    for pts in ([(x - r, y), (x, y - thin), (x + r, y), (x, y + thin)],
                [(x, y - r), (x + thin, y), (x, y + r), (x - thin, y)]):
        d.polygon(pts, fill=(255, 236, 180))
    img = ImageChops.screen(img, layer.filter(ImageFilter.GaussianBlur(r * 0.35)))
    return ImageChops.screen(img, layer.filter(ImageFilter.GaussianBlur(1)))


for path in sorted(glob.glob(os.path.join(sys.argv[1], '*.png'))):
    name = os.path.basename(path)
    fg = Image.open(path).convert('RGBA')
    # lik størrelse og plass uansett figur
    box = fg.getchannel('A').point(lambda v: 255 if v > 20 else 0).getbbox()
    fg = fg.crop(box)
    k = min(S * 0.78 / fg.height, S * 0.80 / fg.width)
    fg = fg.resize((round(fg.width * k), round(fg.height * k)), Image.LANCZOS)
    x, y = (S - fg.width) // 2, round(S * 0.52 - fg.height / 2)

    bg = Image.new('RGB', (S, S), (14, 36, 24))
    shade = Image.new('L', (S, S), 0)
    ImageDraw.Draw(shade).ellipse((-S * 0.2, -S * 0.2, S * 1.2, S * 1.2), fill=255)
    bg = Image.composite(bg, Image.new('RGB', (S, S), (8, 20, 15)),
                         shade.filter(ImageFilter.GaussianBlur(S * 0.2)))
    bg = ImageChops.add(bg, blob((S * 0.13, S * 0.16, S * 0.87, S * 0.88), (100, 70, 30), S * 0.09))
    bg = ImageChops.add(bg, blob((S * 0.30, S * 0.30, S * 0.70, S * 0.76), (72, 50, 22), S * 0.08))
    # skygge under sokkelen
    shadow = Image.new('L', (S, S), 0)
    foot = y + fg.height
    ImageDraw.Draw(shadow).ellipse((S * 0.26, foot - S * 0.035, S * 0.74, foot + S * 0.035), fill=170)
    bg.paste((4, 10, 7), (0, 0), shadow.filter(ImageFilter.GaussianBlur(S * 0.02)))

    bg.paste(fg, (x, y), fg)
    # lett glorie rundt blanke flater
    bright = bg.point(lambda v: max(0, v - 205) * 3).filter(ImageFilter.GaussianBlur(S * 0.018))
    bg = ImageChops.screen(bg, bright.point(lambda v: v // 2))
    rng = random.Random(name)
    spots = [(0.16, 0.30), (0.83, 0.20), (0.88, 0.62), (0.12, 0.66), (0.74, 0.80)]
    for px, py in rng.sample(spots, 3):
        bg = sparkle(bg, S * px + rng.randint(-20, 20), S * py + rng.randint(-20, 20),
                     rng.randint(14, 30))
    for _ in range(14):
        px, py, r = rng.randint(80, S - 80), rng.randint(80, S - 80), rng.randint(2, 4)
        bg = ImageChops.screen(bg, blob((px - r, py - r, px + r, py + r), (255, 214, 130), 2))
    bg.resize((384, 384), Image.LANCZOS).save(os.path.join(out_dir, name), optimize=True)
    print('laget', name)
