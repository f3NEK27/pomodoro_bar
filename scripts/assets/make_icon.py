import math, sys
import numpy as np
from PIL import Image, ImageDraw, ImageFilter

S = 2048
def lerp(a, b, t): return a + (b - a) * t

def gradient_layer(func):
    y, x = np.mgrid[0:S, 0:S].astype(np.float32)
    return func(x, y)

def to_img(rgb, alpha):
    arr = np.dstack([np.clip(rgb, 0, 255), np.clip(alpha, 0, 255)]).astype(np.uint8)
    return Image.fromarray(arr, "RGBA")

def mask_rounded(box, r):
    m = Image.new("L", (S, S), 0)
    ImageDraw.Draw(m).rounded_rectangle(box, r, fill=255)
    return m

canvas = Image.new("RGBA", (S, S), (0, 0, 0, 0))

# Тень под плашкой
box = (200, 190, 1848, 1838)
shadow = Image.new("RGBA", (S, S), (0, 0, 0, 0))
ImageDraw.Draw(shadow).rounded_rectangle((box[0], box[1] + 24, box[2], box[3] + 24), 370, fill=(0, 0, 0, 110))
canvas = Image.alpha_composite(canvas, shadow.filter(ImageFilter.GaussianBlur(28)))

# Фон плашки: тёмный фиолетово-сливовый градиент + тёплое свечение
def bg(x, y):
    t = (y - box[1]) / (box[3] - box[1])
    top = np.array([52, 24, 72], np.float32); bot = np.array([16, 8, 26], np.float32)
    rgb = top[None, None, :] * (1 - t[..., None]) + bot[None, None, :] * t[..., None]
    d = np.sqrt((x - 1024) ** 2 + (y - 1120) ** 2) / 900
    glow = np.clip(1 - d, 0, 1) ** 2
    rgb += glow[..., None] * np.array([150, 40, 30], np.float32)
    return rgb
rgb = gradient_layer(bg)
plate = to_img(rgb, np.full((S, S), 255, np.float32))
canvas.paste(plate, (0, 0), mask_rounded(box, 370))

# Помидор
cx, cy, rx, ry = 1024, 1130, 540, 490
def tomato(x, y):
    nx, ny = (x - cx) / rx, (y - cy) / ry
    d = np.sqrt(nx ** 2 + ny ** 2)
    hx, hy = (x - (cx - 200)) / rx, (y - (cy - 220)) / ry
    h = np.clip(1 - np.sqrt(hx ** 2 + hy ** 2) / 1.6, 0, 1)
    light = np.array([255, 112, 84], np.float32); dark = np.array([170, 22, 34], np.float32)
    rgb = dark[None, None, :] + (light - dark)[None, None, :] * (h[..., None] ** 1.2)
    alpha = np.clip((1 - d) * rx, 0, 1) * 255
    return rgb, alpha
rgb, a = tomato(*np.mgrid[0:S, 0:S][::-1].astype(np.float32))
canvas = Image.alpha_composite(canvas, to_img(rgb, a))

# Блик
shine = Image.new("RGBA", (S, S), (0, 0, 0, 0))
ImageDraw.Draw(shine).ellipse((cx - 400, cy - 400, cx - 120, cy - 220), fill=(255, 255, 255, 90))
canvas = Image.alpha_composite(canvas, shine.filter(ImageFilter.GaussianBlur(40)))

# Кольцо-таймер: дорожка и дуга на 3/4 со светящейся точкой
R, W = 330, 64
ring = Image.new("RGBA", (S, S), (0, 0, 0, 0))
d = ImageDraw.Draw(ring)
bbox = (cx - R, cy - R + 30, cx + R, cy + R + 30)
d.arc(bbox, 0, 360, fill=(255, 255, 255, 50), width=W)
start, span = -90, 270
d.arc(bbox, start, start + span, fill=(255, 244, 230, 255), width=W)
rcx, rcy, rr = cx, cy + 30, R - W / 2
for ang in (start, start + span):
    px, py = rcx + rr * math.cos(math.radians(ang)), rcy + rr * math.sin(math.radians(ang))
    d.ellipse((px - W / 2, py - W / 2, px + W / 2, py + W / 2), fill=(255, 244, 230, 255))
glow = ring.filter(ImageFilter.GaussianBlur(26))
canvas = Image.alpha_composite(canvas, glow)
canvas = Image.alpha_composite(canvas, ring)
# Стрелка от центра к концу дуги
hand = Image.new("RGBA", (S, S), (0, 0, 0, 0))
hd = ImageDraw.Draw(hand)
ang = math.radians(start + span)
ex, ey = rcx + (rr - 90) * math.cos(ang), rcy + (rr - 90) * math.sin(ang)
hd.line((rcx, rcy, ex, ey), fill=(255, 244, 230, 255), width=40)
for (px, py, r) in ((rcx, rcy, 44), (ex, ey, 20)):
    hd.ellipse((px - r, py - r, px + r, py + r), fill=(255, 244, 230, 255))
canvas = Image.alpha_composite(canvas, hand)

# Чашелистик: пять листиков и хвостик
leaves = Image.new("RGBA", (S, S), (0, 0, 0, 0))
ld = ImageDraw.Draw(leaves)
lx, ly = 1024, 660
for i, a_deg in enumerate((-90, -18, 54, 126, 198)):
    a = math.radians(a_deg + 180)  # листья смотрят вниз и в стороны
    length = 230 if i != 0 else 200
    tip = (lx + length * math.cos(a), ly + length * 0.62 * math.sin(a) + 40)
    perp = a + math.pi / 2
    w = 70
    base1 = (lx + w * math.cos(perp), ly + w * 0.6 * math.sin(perp))
    base2 = (lx - w * math.cos(perp), ly - w * 0.6 * math.sin(perp))
    ld.polygon([base1, tip, base2], fill=(64, 190, 104, 255))
ld.ellipse((lx - 95, ly - 60, lx + 95, ly + 60), fill=(52, 168, 90, 255))
ld.rounded_rectangle((lx - 26, ly - 200, lx + 26, ly - 20), 26, fill=(46, 150, 80, 255))
leaf_shadow = Image.new("RGBA", (S, S), (0, 0, 0, 0))
leaf_shadow.paste((60, 0, 0, 120), (0, 30), leaves.split()[3])
canvas = Image.alpha_composite(canvas, leaf_shadow.filter(ImageFilter.GaussianBlur(18)))
canvas = Image.alpha_composite(canvas, leaves)

# Обрезать всё по плашке (листья не вылезают), тень оставить
clip = mask_rounded(box, 370)
fg = Image.new("RGBA", (S, S), (0, 0, 0, 0))
fg.paste(canvas, (0, 0), clip)
final = Image.alpha_composite(Image.composite(canvas, Image.new("RGBA", (S, S)), Image.eval(clip, lambda v: 255 - v)), fg)

big = final.resize((1024, 1024), Image.LANCZOS)
out = sys.argv[1]
big.save(f"{out}/preview.png")
sizes = {"16x16": 16, "16x16@2x": 32, "32x32": 32, "32x32@2x": 64, "128x128": 128,
         "128x128@2x": 256, "256x256": 256, "256x256@2x": 512, "512x512": 512, "512x512@2x": 1024}
import os
os.makedirs(f"{out}/AppIcon.iconset", exist_ok=True)
for name, px in sizes.items():
    big.resize((px, px), Image.LANCZOS).save(f"{out}/AppIcon.iconset/icon_{name}.png")
