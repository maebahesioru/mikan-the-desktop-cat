"""Draw the desktop pet — 'Mikan' a round orange tabby cat. Pixel art, 32x32-ish.
Frames: walk1, walk2, idle1, idle2, sleep1, sleep2, drag (surprised)
Output: PNG files with transparency at 4x scale (128x128) for crisp look.
"""
from PIL import Image, ImageDraw
from pathlib import Path

OUT = Path(__file__).parent / "pet" / "assets" / "sprites"
OUT.mkdir(parents=True, exist_ok=True)

# palette
ORANGE = (247, 163, 84, 255)
ORANGE_D = (222, 124, 60, 255)   # stripes
CREAM = (255, 231, 196, 255)     # belly / muzzle
DARK = (61, 43, 38, 255)         # eyes / outline
PINK = (247, 168, 168, 255)      # nose / inner ear
WHITE = (255, 255, 255, 255)

S = 4  # scale


def canvas():
    img = Image.new("RGBA", (32, 32), (0, 0, 0, 0))
    return img, ImageDraw.Draw(img)


def body(d, x=0, y=0, squash=0):
    """Round cat body. squash = how much to squish vertically (idle breathing)."""
    cx, cy = 16 + x, 20 + y
    # body blob
    d.ellipse([cx - 9, cy - 7 + squash, cx + 9, cy + 7], fill=ORANGE)
    # belly
    d.ellipse([cx - 5, cy - 3 + squash, cx + 5, cy + 6], fill=CREAM)
    # stripes
    d.line([cx - 7, cy - 5 + squash, cx - 4, cy - 5 + squash], fill=ORANGE_D, width=1)
    d.line([cx + 3, cy - 6 + squash, cx + 7, cy - 5 + squash], fill=ORANGE_D, width=1)
    d.line([cx - 8, cy - 1 + squash, cx - 5, cy - 1 + squash], fill=ORANGE_D, width=1)


def head(d, x=0, y=0, ears_up=False, surprised=False):
    cx, cy = 16 + x, 11 + y
    # ears
    if ears_up:
        d.polygon([(cx - 7, cy - 5), (cx - 10, cy - 12), (cx - 3, cy - 7)], fill=ORANGE)
        d.polygon([(cx + 3, cy - 7), (cx + 10, cy - 12), (cx + 7, cy - 5)], fill=ORANGE)
        d.polygon([(cx - 6, cy - 6), (cx - 8, cy - 10), (cx - 4, cy - 7)], fill=PINK)
        d.polygon([(cx + 4, cy - 7), (cx + 8, cy - 10), (cx + 6, cy - 6)], fill=PINK)
    else:
        d.polygon([(cx - 7, cy - 4), (cx - 9, cy - 9), (cx - 3, cy - 6)], fill=ORANGE)
        d.polygon([(cx + 3, cy - 6), (cx + 9, cy - 9), (cx + 7, cy - 4)], fill=ORANGE)
        d.polygon([(cx - 6, cy - 5), (cx - 7, cy - 8), (cx - 4, cy - 6)], fill=PINK)
        d.polygon([(cx + 4, cy - 6), (cx + 7, cy - 8), (cx + 6, cy - 5)], fill=PINK)
    # head
    d.ellipse([cx - 9, cy - 7, cx + 9, cy + 6], fill=ORANGE)
    # forehead stripes
    d.line([cx - 2, cy - 6, cx - 2, cy - 3], fill=ORANGE_D, width=1)
    d.line([cx + 2, cy - 6, cx + 2, cy - 3], fill=ORANGE_D, width=1)
    # muzzle
    d.ellipse([cx - 4, cy + 1, cx + 4, cy + 5], fill=CREAM)
    # eyes
    if surprised:
        d.ellipse([cx - 5, cy - 3, cx - 2, cy + 1], fill=DARK)
        d.ellipse([cx + 2, cy - 3, cx + 5, cy + 1], fill=DARK)
        d.ellipse([cx - 4, cy - 2, cx - 3, cy - 1], fill=WHITE)
        d.ellipse([cx + 3, cy - 2, cx + 4, cy - 1], fill=WHITE)
    else:
        d.ellipse([cx - 5, cy - 3, cx - 3, cy], fill=DARK)
        d.ellipse([cx + 3, cy - 3, cx + 5, cy], fill=DARK)
    # nose + mouth
    d.polygon([(cx - 1, cy + 2), (cx + 1, cy + 2), (cx, cy + 3)], fill=PINK)
    d.line([cx, cy + 3, cx - 1, cy + 4], fill=DARK, width=1)
    d.line([cx, cy + 3, cx + 1, cy + 4], fill=DARK, width=1)
    # whiskers
    d.line([cx - 9, cy + 2, cx - 5, cy + 3], fill=DARK, width=1)
    d.line([cx + 5, cy + 3, cx + 9, cy + 2], fill=DARK, width=1)


def tail(d, x=0, y=0, up=False):
    if up:
        d.line([(24 + x, 22 + y), (27 + x, 18 + y), (26 + x, 14 + y)], fill=ORANGE, width=3)
        d.line([(27 + x, 18 + y), (26 + x, 14 + y)], fill=ORANGE_D, width=1)
    else:
        d.line([(24 + x, 22 + y), (28 + x, 22 + y), (29 + x, 19 + y)], fill=ORANGE, width=3)


def legs(d, x=0, y=0, phase=0):
    """phase: 0 = both down, 1 = front up, 2 = back up"""
    ly = 27 + y
    if phase == 0:
        d.rectangle([13 + x, ly - 2, 15 + x, ly], fill=ORANGE)
        d.rectangle([17 + x, ly - 2, 19 + x, ly], fill=ORANGE)
    elif phase == 1:
        d.rectangle([13 + x, ly - 2, 15 + x, ly], fill=ORANGE)
        d.rectangle([17 + x, ly - 3, 19 + x, ly - 1], fill=ORANGE)
    else:
        d.rectangle([13 + x, ly - 3, 15 + x, ly - 1], fill=ORANGE)
        d.rectangle([17 + x, ly - 2, 19 + x, ly], fill=ORANGE)


def save(img, name):
    img = img.resize((32 * S, 32 * S), Image.NEAREST)
    img.save(OUT / f"{name}.png")
    print("saved", name)


# walk1
img, d = canvas()
tail(d)
body(d, y=0)
head(d, y=0)
legs(d, phase=1)
save(img, "walk1")

# walk2
img, d = canvas()
tail(d, up=True)
body(d, y=-1)
head(d, y=-1)
legs(d, phase=2)
save(img, "walk2")

# idle1
img, d = canvas()
tail(d)
body(d, squash=0)
head(d)
legs(d, phase=0)
save(img, "idle1")

# idle2 (breathing)
img, d = canvas()
tail(d, up=True)
body(d, squash=1)
head(d, y=1)
legs(d, phase=0)
save(img, "idle2")

# sleep1 (eyes closed = draw then overlay)
img, d = canvas()
tail(d)
body(d, squash=1)
head(d, y=2)
# closed eyes: cover with lines
d.line([(10, 13), (13, 13)], fill=DARK, width=1)
d.line([(19, 13), (22, 13)], fill=DARK, width=1)
save(img, "sleep1")

# sleep2 (z's + breathing)
img, d = canvas()
tail(d, up=True)
body(d, squash=2)
head(d, y=3)
d.line([(10, 14), (13, 14)], fill=DARK, width=1)
d.line([(19, 14), (22, 14)], fill=DARK, width=1)
# Zzz
d.text((25, 6), "z", fill=DARK)
d.text((27, 3), "z", fill=DARK)
save(img, "sleep2")

# drag (surprised, ears up, tail up, legs dangling)
img, d = canvas()
tail(d, up=True)
body(d, y=-1)
head(d, y=-1, ears_up=True, surprised=True)
legs(d, phase=0, y=-1)
save(img, "drag")

print("ALL DONE ->", OUT)
