#!/usr/bin/env python3
"""Generate GeminiChat app icons in all required macOS sizes."""

import math
import os
from PIL import Image, ImageDraw, ImageFilter

OUTPUT_DIR = "Sources/GeminiChat/Resources/Assets.xcassets/AppIcon.appiconset"

# macOS icon sizes: (logical_size, scale, actual_pixel_size, filename)
ICON_SPECS = [
    (16,  "1x",  16,   "icon_16x16.png"),
    (16,  "2x",  32,   "icon_16x16@2x.png"),
    (32,  "1x",  32,   "icon_32x32.png"),
    (32,  "2x",  64,   "icon_32x32@2x.png"),
    (128, "1x",  128,  "icon_128x128.png"),
    (128, "2x",  256,  "icon_128x128@2x.png"),
    (256, "1x",  256,  "icon_256x256.png"),
    (256, "2x",  512,  "icon_256x256@2x.png"),
    (512, "1x",  512,  "icon_512x512.png"),
    (512, "2x",  1024, "icon_512x512@2x.png"),
]


def lerp_color(c1, c2, t):
    return tuple(int(c1[i] + (c2[i] - c1[i]) * t) for i in range(len(c1)))


def draw_gradient_background(draw, size, corner_radius):
    """Draw a deep blue to near-black gradient rounded rect background."""
    top_left = (26, 38, 102, 255)      # Deep blue
    bottom_right = (13, 13, 38, 255)   # Near black

    # Create gradient via pixel rows/columns
    mask = Image.new("L", (size, size), 0)
    mask_draw = ImageDraw.Draw(mask)
    mask_draw.rounded_rectangle([0, 0, size - 1, size - 1], radius=corner_radius, fill=255)

    gradient = Image.new("RGBA", (size, size), (0, 0, 0, 0))
    grad_draw = ImageDraw.Draw(gradient)

    for y in range(size):
        for x in range(size):
            t = (x + y) / (2 * (size - 1))
            color = lerp_color(top_left, bottom_right, t)
            grad_draw.point((x, y), fill=color)

    # Apply rounded rect mask
    bg = Image.new("RGBA", (size, size), (0, 0, 0, 0))
    bg.paste(gradient, mask=mask)
    return bg


def draw_radial_glow(size):
    """Draw a subtle blue radial glow."""
    glow = Image.new("RGBA", (size, size), (0, 0, 0, 0))
    glow_draw = ImageDraw.Draw(glow)

    cx, cy = size // 2, size // 2
    max_r = int(size * 0.4)

    for r in range(max_r, 0, -1):
        t = 1.0 - (r / max_r)
        alpha = int(60 * t * t)  # quadratic falloff
        color = (30, 80, 220, alpha)
        bbox = [cx - r, cy - r, cx + r, cy + r]
        glow_draw.ellipse(bbox, fill=color)

    blur_radius = max(1, size // 20)
    glow = glow.filter(ImageFilter.GaussianBlur(radius=blur_radius))
    return glow


def draw_star(draw, cx, cy, outer_r, inner_r, points, color, alpha=255):
    """Draw a star polygon."""
    verts = []
    for i in range(points * 2):
        angle = math.pi / points * i - math.pi / 2
        r = outer_r if i % 2 == 0 else inner_r
        verts.append((cx + r * math.cos(angle), cy + r * math.sin(angle)))
    fill = color + (alpha,)
    draw.polygon(verts, fill=fill)


def draw_sparkles(img, size):
    """Draw a sparkles pattern (3 stars like the ✨ emoji)."""
    overlay = Image.new("RGBA", (size, size), (0, 0, 0, 0))
    draw = ImageDraw.Draw(overlay)

    cx, cy = size / 2, size / 2
    base = size * 0.45  # scale factor

    # Main large 4-pointed star in center
    main_outer = base * 0.35
    main_inner = main_outer * 0.22

    # Glow layer (blurred larger version)
    glow_overlay = Image.new("RGBA", (size, size), (0, 0, 0, 0))
    glow_draw = ImageDraw.Draw(glow_overlay)
    draw_star(glow_draw, cx, cy, main_outer * 1.2, main_inner * 1.2, 4, (80, 130, 255), alpha=120)

    # Small star top-right
    small_outer = main_outer * 0.42
    small_inner = small_outer * 0.22
    draw_star(glow_draw, cx + main_outer * 0.75, cy - main_outer * 0.6,
              small_outer * 1.2, small_inner * 1.2, 4, (80, 130, 255), alpha=100)

    # Tiny star bottom-left
    tiny_outer = main_outer * 0.28
    tiny_inner = tiny_outer * 0.22
    draw_star(glow_draw, cx - main_outer * 0.7, cy + main_outer * 0.55,
              tiny_outer * 1.2, tiny_inner * 1.2, 4, (80, 130, 255), alpha=90)

    blur_r = max(1, int(size * 0.025))
    glow_overlay = glow_overlay.filter(ImageFilter.GaussianBlur(radius=blur_r))
    img = Image.alpha_composite(img, glow_overlay)

    # Draw main 4-pointed star with white-to-blue gradient effect
    overlay2 = Image.new("RGBA", (size, size), (0, 0, 0, 0))
    draw2 = ImageDraw.Draw(overlay2)

    # Main star - two layers for gradient feel
    draw_star(draw2, cx, cy, main_outer, main_inner, 4, (200, 220, 255), alpha=255)
    draw_star(draw2, cx, cy, main_outer * 0.6, main_inner * 0.6, 4, (255, 255, 255), alpha=255)

    # Small star top-right
    draw_star(draw2, cx + main_outer * 0.75, cy - main_outer * 0.6,
              small_outer, small_inner, 4, (180, 210, 255), alpha=230)
    draw_star(draw2, cx + main_outer * 0.75, cy - main_outer * 0.6,
              small_outer * 0.55, small_inner * 0.55, 4, (255, 255, 255), alpha=220)

    # Tiny star bottom-left
    draw_star(draw2, cx - main_outer * 0.7, cy + main_outer * 0.55,
              tiny_outer, tiny_inner, 4, (160, 200, 255), alpha=210)
    draw_star(draw2, cx - main_outer * 0.7, cy + main_outer * 0.55,
              tiny_outer * 0.55, tiny_inner * 0.55, 4, (255, 255, 255), alpha=200)

    img = Image.alpha_composite(img, overlay2)
    return img


def generate_icon(pixel_size):
    """Generate a single icon at the given pixel size."""
    size = pixel_size
    corner_radius = int(size * 0.22)

    # Background gradient
    img = draw_gradient_background(None, size, corner_radius)

    # Radial glow
    glow = draw_radial_glow(size)
    img = Image.alpha_composite(img, glow)

    # Sparkles
    img = draw_sparkles(img, size)

    return img


def main():
    os.makedirs(OUTPUT_DIR, exist_ok=True)

    for logical, scale, pixel_size, filename in ICON_SPECS:
        print(f"Generating {filename} ({pixel_size}x{pixel_size})...")
        img = generate_icon(pixel_size)
        # Convert to RGB with white background for final PNG (keep RGBA)
        out_path = os.path.join(OUTPUT_DIR, filename)
        img.save(out_path, "PNG")

    print(f"\nAll icons saved to {OUTPUT_DIR}/")


if __name__ == "__main__":
    main()
