from collections import deque
from pathlib import Path

from PIL import Image, ImageDraw


ROOT = Path(__file__).resolve().parents[1]
SOURCE = ROOT / "jenasolo.png"
WINDOWS_ICON = ROOT / "windows" / "runner" / "resources" / "app_icon.ico"
ANDROID_RES = ROOT / "android" / "app" / "src" / "main" / "res"


ANDROID_SIZES = {
    "mipmap-mdpi": 48,
    "mipmap-hdpi": 72,
    "mipmap-xhdpi": 96,
    "mipmap-xxhdpi": 144,
    "mipmap-xxxhdpi": 192,
}


def remove_edge_background(image: Image.Image) -> Image.Image:
    image = image.convert("RGBA")
    width, height = image.size
    pixels = image.load()
    queue: deque[tuple[int, int]] = deque()
    seen = set()

    def is_background(x: int, y: int) -> bool:
        red, green, blue, alpha = pixels[x, y]
        return alpha > 0 and red > 245 and green > 245 and blue > 245

    for x in range(width):
        queue.append((x, 0))
        queue.append((x, height - 1))
    for y in range(height):
        queue.append((0, y))
        queue.append((width - 1, y))

    while queue:
        x, y = queue.popleft()
        if (x, y) in seen or x < 0 or y < 0 or x >= width or y >= height:
            continue
        seen.add((x, y))
        if not is_background(x, y):
            continue
        pixels[x, y] = (255, 255, 255, 0)
        queue.extend(((x - 1, y), (x + 1, y), (x, y - 1), (x, y + 1)))

    bbox = image.getbbox()
    if bbox is None:
        return image
    return image.crop(bbox)


def compose_icon(size: int, rounded: bool) -> Image.Image:
    foreground = remove_edge_background(Image.open(SOURCE))
    canvas = Image.new("RGBA", (size, size), (0, 0, 0, 0))
    draw = ImageDraw.Draw(canvas)

    inset = max(1, int(size * 0.03))
    radius = size // 2 if rounded else int(size * 0.22)
    bounds = (inset, inset, size - inset, size - inset)
    draw.rounded_rectangle(bounds, radius=radius, fill=(10, 17, 23, 255))

    border_width = max(1, size // 36)
    draw.rounded_rectangle(
        bounds,
        radius=radius,
        outline=(0, 214, 141, 255),
        width=border_width,
    )

    max_width = int(size * 0.86)
    max_height = int(size * 0.56)
    scale = min(max_width / foreground.width, max_height / foreground.height)
    icon_size = (
        max(1, int(foreground.width * scale)),
        max(1, int(foreground.height * scale)),
    )
    foreground = foreground.resize(icon_size, Image.Resampling.LANCZOS)

    x = (size - foreground.width) // 2
    y = (size - foreground.height) // 2 + int(size * 0.02)
    canvas.alpha_composite(foreground, (x, y))
    return canvas


def main() -> None:
    for density, size in ANDROID_SIZES.items():
        output_dir = ANDROID_RES / density
        output_dir.mkdir(parents=True, exist_ok=True)
        compose_icon(size, rounded=False).save(output_dir / "ic_launcher.png")
        compose_icon(size, rounded=True).save(output_dir / "ic_launcher_round.png")

    base = compose_icon(1024, rounded=False)
    base.save(
        WINDOWS_ICON,
        format="ICO",
        sizes=[(16, 16), (24, 24), (32, 32), (48, 48), (64, 64), (128, 128), (256, 256)],
    )


if __name__ == "__main__":
    main()
