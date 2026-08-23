#!/usr/bin/env python3
"""Convert an fbdev raw framebuffer dump to a PNG.

Usage: raw2png.py <screen.raw> <fb-meta.txt> <out.png> [--swap] [--bgr]
"""
import re
import sys
import numpy as np
from PIL import Image


def load_meta(path):
    meta = {}
    for line in open(path, encoding="utf-8", errors="replace"):
        m = re.match(r"virtual_size=(\d+)x(\d+)", line)
        if m:
            meta["w"], meta["h"] = int(m.group(1)), int(m.group(2))
        m = re.match(r"bits_per_pixel=(\d+)", line)
        if m:
            meta["bpp"] = int(m.group(1))
    return meta


def main():
    args = sys.argv[1:]
    raw_path, meta_path, out_path = args[0], args[1], args[2]
    swap = "--swap" in args   # R/B already correct, swap nothing
    data = np.fromfile(raw_path, dtype=np.uint8)
    meta = load_meta(meta_path)
    bpp = meta.get("bpp", 32)
    bpp //= 8
    w, h = meta.get("w"), meta.get("h")

    if w and h and len(data) >= w * h * bpp:
        data = data[: w * h * bpp].reshape(h, w, bpp)
    else:
        # Try to infer geometry from file size (assume 4 bpp).
        px = len(data) // 4
        if px <= 0:
            sys.exit("empty framebuffer")
        for hh in (1600, 1280, 1080, 800, 720):
            if px % hh == 0:
                h, w = hh, px // hh
                break
        else:
            sys.exit(f"cannot infer geometry from {len(data)} bytes")
        data = data.reshape(h, w, 4)

    if bpp >= 4:
        b, g, r = data[..., 0], data[..., 1], data[..., 2]
        if swap:
            r, b = b, r
        rgb = np.stack([r, g, b], axis=-1)
    else:
        rgb = data[..., :3] if bpp == 3 else np.repeat(data[..., 0, np.newaxis], 3, axis=-1)

    img = Image.fromarray(rgb, "RGB")
    img.save(out_path)
    print(f"saved {out_path}: {w}x{h}")


if __name__ == "__main__":
    main()
