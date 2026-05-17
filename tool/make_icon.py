"""Generate the app launcher icon (no external deps).

Produces a 1024x1024 PNG: teal background with a white ">_" terminal
glyph. Run: python3 tool/make_icon.py
"""
import os
import struct
import zlib

W = H = 1024
BG = (0, 137, 123, 255)   # teal 600
FG = (255, 255, 255, 255)

px = bytearray()
for _ in range(W * H):
    px += bytes(BG)


def put(x, y, c):
    if 0 <= x < W and 0 <= y < H:
        i = (y * W + x) * 4
        px[i:i + 4] = bytes(c)


def seg(x1, y1, x2, y2, half):
    """Draw a thick line segment."""
    import math
    dx, dy = x2 - x1, y2 - y1
    length = max(1.0, math.hypot(dx, dy))
    steps = int(length)
    for s in range(steps + 1):
        t = s / steps
        cx, cy = x1 + dx * t, y1 + dy * t
        for ox in range(-half, half + 1):
            for oy in range(-half, half + 1):
                if ox * ox + oy * oy <= half * half:
                    put(int(cx) + ox, int(cy) + oy, FG)


# ">" chevron
seg(330, 330, 560, 512, 26)
seg(560, 512, 330, 694, 26)
# "_" underscore
seg(600, 690, 760, 690, 24)

raw = bytearray()
for y in range(H):
    raw.append(0)  # filter: none
    raw += px[y * W * 4:(y + 1) * W * 4]


def chunk(tag, data):
    return (struct.pack(">I", len(data)) + tag + data +
            struct.pack(">I", zlib.crc32(tag + data) & 0xFFFFFFFF))


png = b"\x89PNG\r\n\x1a\n"
png += chunk(b"IHDR", struct.pack(">IIBBBBB", W, H, 8, 6, 0, 0, 0))
png += chunk(b"IDAT", zlib.compress(bytes(raw), 9))
png += chunk(b"IEND", b"")

out = os.path.join(os.path.dirname(__file__), "..", "assets", "icon",
                   "icon.png")
os.makedirs(os.path.dirname(out), exist_ok=True)
with open(out, "wb") as f:
    f.write(png)
print("wrote", os.path.normpath(out), len(png), "bytes")
