"""App icon (owner 2026-11-07: «العلم الموحد للخليج» → the six national flags in one circle,
no official GCC emblem). Each flag fills one 60° slice, hoist at the centre; MIDTRANS
gold mark in the middle. Run with Pillow from the project root."""
import math
from PIL import Image, ImageDraw

S = 1024
C = S // 2
R = 470                      # flag circle radius
R2 = 205                     # centre medallion radius
FW, FH = R - R2 + 40, int(2 * (R + 20) * math.tan(math.radians(30))) + 40

def flag(name):
    im = Image.new('RGB', (FW, FH)); d = ImageDraw.Draw(im)
    def hbands(cols, x0=0):
        h = FH / len(cols)
        for i, c in enumerate(cols):
            d.rectangle([x0, round(i * h), FW, round((i + 1) * h)], fill=c)
    def serrated(x, pts, col_l, col_r):
        d.rectangle([0, 0, FW, FH], fill=col_r)
        d.rectangle([0, 0, x, FH], fill=col_l)
        step = FH / pts
        poly = [(x, 0)]
        for i in range(pts):
            poly += [(x + FW * 0.16, i * step + step / 2), (x, (i + 1) * step)]
        d.polygon(poly, fill=col_l)
    if name == 'sa':
        d.rectangle([0, 0, FW, FH], fill='#006C35')
    elif name == 'ae':
        hbands(['#00732F', 'white', '#000000']); d.rectangle([0, 0, FW * 0.28, FH], fill='#FF0000')
    elif name == 'kw':
        hbands(['#007A3D', 'white', '#CE1126'])
        d.polygon([(0, 0), (FW * 0.3, FH / 3), (FW * 0.3, 2 * FH / 3), (0, FH)], fill='black')
    elif name == 'qa':
        serrated(FW * 0.22, 9, 'white', '#8A1538')
    elif name == 'bh':
        serrated(FW * 0.22, 5, 'white', '#CE1126')
    elif name == 'om':
        hbands(['white', '#DB161B', '#008000']); d.rectangle([0, 0, FW * 0.3, FH], fill='#DB161B')
    return im

base = Image.new('RGBA', (S, S))
bg = Image.open('assets/branding/icon-background.png').convert('RGBA').resize((S, S))
base.alpha_composite(bg)

for i, name in enumerate(['sa', 'ae', 'kw', 'qa', 'bh', 'om']):
    theta = -90 + i * 60                    # Saudi at the top, clockwise
    layer = Image.new('RGBA', (S, S))
    f = flag(name).convert('RGBA')
    layer.paste(f, (C + R2 - 12, C - FH // 2))
    layer = layer.rotate(-theta, center=(C, C), resample=Image.BICUBIC)
    mask = Image.new('L', (S, S)); md = ImageDraw.Draw(mask)
    md.pieslice([C - R, C - R, C + R, C + R], theta - 30, theta + 30, fill=255)
    base.paste(layer, (0, 0), mask)

d = ImageDraw.Draw(base)
gold = (201, 178, 122, 255)
for i in range(6):                           # gold spokes between the flags
    a = math.radians(-90 + i * 60 + 30)
    d.line([(C, C), (C + R * math.cos(a), C + R * math.sin(a))], fill=gold, width=10)
d.ellipse([C - R, C - R, C + R, C + R], outline=gold, width=16)
r2 = R2
d.ellipse([C - r2, C - r2, C + r2, C + r2], fill=(10, 28, 46, 255), outline=gold, width=12)
fg = Image.open('assets/branding/icon-foreground.png').convert('RGBA')
bbox = fg.getbbox(); mark = fg.crop(bbox)
k = (2 * r2 * 0.74) / max(mark.size); mark = mark.resize((round(mark.width * k), round(mark.height * k)), Image.LANCZOS)
base.alpha_composite(mark, (C - mark.width // 2, C - mark.height // 2))

icon = base.convert('RGB')
icon.save('assets/branding/icon-1024.png')
icon.resize((96, 96), Image.LANCZOS).save('assets/branding/app-icon-96.png')
for s in (1024, 512, 216):
    icon.resize((s, s), Image.LANCZOS).save(f'store/icons/icon-{s}.png')
# Android adaptive foreground: the circle inside the 66% safe zone, transparent around
fgA = base.copy(); m = Image.new('L', (S, S)); ImageDraw.Draw(m).ellipse([C - R - 8, C - R - 8, C + R + 8, C + R + 8], fill=255)
fgA.putalpha(m); fgA = fgA.resize((round(S * 0.64), round(S * 0.64)), Image.LANCZOS)
out = Image.new('RGBA', (S, S)); out.alpha_composite(fgA, ((S - fgA.width) // 2, (S - fgA.height) // 2))
out.save('assets/branding/icon-foreground-gcc.png')
print('ok')
