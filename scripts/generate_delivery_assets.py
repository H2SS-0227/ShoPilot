#!/usr/bin/env python3
from __future__ import annotations

from pathlib import Path

from PIL import Image, ImageDraw, ImageFont

ROOT = Path(__file__).resolve().parents[1]
ASSETS = ROOT / "docs" / "assets"
SCREENSHOTS = ROOT / "client" / "assets" / "stitch" / "screenshots"


def main() -> None:
    ASSETS.mkdir(parents=True, exist_ok=True)
    make_banner()
    make_poster()
    make_gif()
    print(f"Wrote assets to {ASSETS}")


def font(size: int, bold: bool = False) -> ImageFont.FreeTypeFont | ImageFont.ImageFont:
    candidates = [
        "/System/Library/Fonts/Supplemental/Arial Bold.ttf" if bold else "/System/Library/Fonts/Supplemental/Arial.ttf",
        "/System/Library/Fonts/Supplemental/Helvetica.ttc",
        "/System/Library/Fonts/PingFang.ttc",
    ]
    for candidate in candidates:
        if candidate and Path(candidate).exists():
            return ImageFont.truetype(candidate, size=size)
    return ImageFont.load_default()


def gradient(size: tuple[int, int], start=(252, 248, 255), end=(226, 220, 255)) -> Image.Image:
    width, height = size
    image = Image.new("RGB", size, start)
    draw = ImageDraw.Draw(image)
    for y in range(height):
        ratio = y / max(height - 1, 1)
        color = tuple(int(start[index] * (1 - ratio) + end[index] * ratio) for index in range(3))
        draw.line([(0, y), (width, y)], fill=color)
    return image


def rounded_rect(draw: ImageDraw.ImageDraw, box: tuple[int, int, int, int], radius: int, fill: tuple[int, int, int]) -> None:
    draw.rounded_rectangle(box, radius=radius, fill=fill)


def make_banner() -> None:
    image = gradient((1600, 600))
    draw = ImageDraw.Draw(image)
    draw.ellipse((-140, 220, 360, 720), fill=(211, 207, 255))
    draw.ellipse((1210, -180, 1760, 360), fill=(237, 207, 255))
    rounded_rect(draw, (1010, 92, 1490, 508), 42, (255, 255, 255))
    draw.text((110, 112), "ShopPilot AI", fill=(70, 72, 212), font=font(84, bold=True))
    draw.text((112, 224), "Conversational RAG Shopping Assistant", fill=(27, 27, 35), font=font(38, bold=True))
    draw.text((116, 292), "SSE streaming | Product cards | Compare | Cart | TikTok review references", fill=(70, 69, 84), font=font(28))

    for index, text in enumerate(["Local product RAG", "Doubao answer copy", "SwiftUI native app"]):
        x = 112 + index * 290
        rounded_rect(draw, (x, 408, x + 245, 468), 30, (255, 255, 255))
        draw.text((x + 24, 424), text, fill=(70, 72, 212), font=font(20, bold=True))

    draw.text((1065, 150), "Core Demo Flow", fill=(27, 27, 35), font=font(34, bold=True))
    flow = ["1. Ask shopping need", "2. Stream grounded answer", "3. Compare products", "4. Add to cart"]
    for index, item in enumerate(flow):
        y = 220 + index * 62
        draw.ellipse((1065, y, 1093, y + 28), fill=(70, 72, 212))
        draw.text((1112, y - 2), item, fill=(70, 69, 84), font=font(24))

    image.save(ASSETS / "banner.png")


def make_poster() -> None:
    image = gradient((1200, 1600), start=(252, 248, 255), end=(240, 224, 255))
    draw = ImageDraw.Draw(image)
    draw.text((84, 92), "ShopPilot AI", fill=(70, 72, 212), font=font(76, bold=True))
    draw.text((88, 190), "Trustworthy AI shopping decisions", fill=(27, 27, 35), font=font(36, bold=True))
    draw.text((90, 250), "Grounded in a local e-commerce dataset with RAG + Agent orchestration.", fill=(70, 69, 84), font=font(25))

    cards = [
        ("RAG Grounding", "Product facts, prices and review links come from the local dataset."),
        ("Streaming UX", "FastAPI SSE emits meta, delta, final, done and error events."),
        ("Decision Tools", "Product cards, detail sheets, comparison and cart actions."),
        ("Native Delivery", "SwiftUI iOS app shares the same JSON/SSE protocol."),
    ]
    y = 380
    for title, body in cards:
        rounded_rect(draw, (84, y, 1116, y + 188), 36, (255, 255, 255))
        draw.text((130, y + 36), title, fill=(70, 72, 212), font=font(31, bold=True))
        draw.text((130, y + 88), body, fill=(70, 69, 84), font=font(24))
        y += 230

    rounded_rect(draw, (84, 1320, 1116, 1490), 38, (70, 72, 212))
    draw.text((130, 1364), "Benchmark Snapshot", fill=(255, 255, 255), font=font(32, bold=True))
    draw.text((130, 1418), "25 demo queries | Precision@3 0.8267 | Grounding 1.0000 | Avg latency 2.89ms", fill=(255, 255, 255), font=font(23))
    image.save(ASSETS / "poster.png")


def make_gif() -> None:
    frames: list[Image.Image] = []
    steps = [
        ("Home", "Start from natural-language product needs"),
        ("Streaming", "SSE delta chunks animate the assistant reply"),
        ("Recommendations", "Grounded products appear with review references"),
        ("Detail", "Open product details and TikTok references"),
        ("Compare + Cart", "Compare top products and add one to cart"),
    ]
    screenshot_files = [
        SCREENSHOTS / "home.png",
        SCREENSHOTS / "chat-streaming.png",
        SCREENSHOTS / "chat-recommendations.png",
        SCREENSHOTS / "product-detail-sheet.png",
        SCREENSHOTS / "cart-drawer.png",
    ]

    for (title, subtitle), screenshot in zip(steps, screenshot_files):
        frame = gradient((960, 640))
        draw = ImageDraw.Draw(frame)
        draw.text((54, 52), f"ShopPilot AI - {title}", fill=(70, 72, 212), font=font(42, bold=True))
        draw.text((56, 110), subtitle, fill=(70, 69, 84), font=font(24))
        if screenshot.exists():
            shot = Image.open(screenshot).convert("RGB")
            shot.thumbnail((380, 430))
            frame.paste(shot, (530, 150))
        rounded_rect(draw, (56, 212, 470, 445), 30, (255, 255, 255))
        draw.text((92, 252), "Flow", fill=(27, 27, 35), font=font(30, bold=True))
        draw.text((92, 310), "Ask -> Stream -> Cards", fill=(70, 69, 84), font=font(22))
        draw.text((92, 350), "Detail -> Compare -> Cart", fill=(70, 69, 84), font=font(22))
        frames.append(frame)

    frames[0].save(
        ASSETS / "shoppilot-core-flow.gif",
        save_all=True,
        append_images=frames[1:],
        duration=900,
        loop=0,
        optimize=True,
    )


if __name__ == "__main__":
    main()
