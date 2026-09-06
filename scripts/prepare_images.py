#!/usr/bin/env python3
"""Manually prepare blog JPEGs, porting Create.nb's Signed -> True branch.

Run: uv run scripts/prepare_images.py picture.jpg
See scripts/IMAGE_PREPARATION.md for the notebook mapping and numerical limits.
"""
from __future__ import annotations

import argparse
from dataclasses import dataclass
from io import BytesIO
import math
import os
from pathlib import Path
import tempfile

from PIL import Image, ImageCms, ImageOps

DEFAULT_WATERMARK = Path(__file__).resolve().parent / 'assets' / 'filigranne.png'


def nearest(value: float) -> int:
    """Round pixel coordinates to nearest integer, with half values upward."""
    return math.floor(value + 0.5)


def resize_width(image: Image.Image, width: int) -> Image.Image:
    height = max(1, nearest(image.height * width / image.width))
    return image.resize((width, height), Image.Resampling.LANCZOS)


def scale(image: Image.Image, factor: float) -> Image.Image:
    return image.resize((max(1, nearest(image.width * factor)),
                         max(1, nearest(image.height * factor))), Image.Resampling.LANCZOS)


def square_gallery(image: Image.Image, size: int) -> Image.Image:
    """Resize to width, then center-crop or black-pad; do not use cover/fit."""
    resized = resize_width(image, size)
    canvas = Image.new('RGB', (size, size), 'black')
    canvas.paste(resized, (0, (size - resized.height) // 2))
    return canvas


def compose(image: Image.Image, overlay: Image.Image, opacity: float,
            position: tuple[float, float],
            anchor: tuple[float, float] | None = None) -> Image.Image:
    """Wolfram-style position and overlay anchor measured from bottom-left."""
    overlay = overlay.convert('RGBA')
    overlay.putalpha(overlay.getchannel('A').point(lambda a: nearest(a * opacity)))
    ax, ay = anchor if anchor is not None else (overlay.width / 2, overlay.height / 2)
    px, py = position
    left = nearest(px - ax)
    top = nearest(image.height - py - (overlay.height - ay))
    result = image.convert('RGBA')
    result.alpha_composite(overlay, dest=(left, top))
    return result.convert('RGB')


@dataclass(frozen=True)
class Options:
    thumb_width: int = 740
    signed_width: int | None = None
    gallery_size: int = 200
    opacity: float = 0.5
    center: bool = False
    quality: int = 90

    def validate(self) -> None:
        if self.thumb_width < 1 or self.gallery_size < 1 or (
                self.signed_width is not None and self.signed_width < 1):
            raise ValueError('Image dimensions must be positive integers')
        if not math.isfinite(self.opacity) or not 0 <= self.opacity <= 1:
            raise ValueError('Opacity must be between 0 and 1')
        if not 1 <= self.quality <= 100:
            raise ValueError('JPEG quality must be between 1 and 100')


def render_variants(image: Image.Image, watermark: Image.Image,
                    options: Options) -> dict[str, Image.Image]:
    options.validate()
    signed = resize_width(image, options.signed_width or image.width)
    thumb = resize_width(image, options.thumb_width)
    signed_overlay = scale(watermark, 0.4)
    thumb_overlay = scale(watermark, 0.3)
    # Rotate first, preserving the original black rectangle with transparent corners.
    gallery_overlay = scale(watermark.convert('RGBA').rotate(
        45, resample=Image.Resampling.BICUBIC, expand=True, fillcolor=(0, 0, 0, 0)), 0.3)
    if options.center:
        signed = compose(signed, signed_overlay, options.opacity,
                         (signed.width / 2, signed.height / 2), (160, 20))
        thumb = compose(thumb, thumb_overlay, options.opacity,
                        (thumb.width / 2, thumb.height / 2), (120, 15))
    else:
        signed = compose(signed, signed_overlay, options.opacity, (160, 20))
        thumb = compose(thumb, thumb_overlay, options.opacity, (120, 15))
    gallery = square_gallery(image, options.gallery_size)
    gallery = compose(gallery, gallery_overlay, options.opacity,
                      (options.gallery_size / 2, options.gallery_size / 2))
    return {'gallery': gallery, 'signed': signed, 'thumb': thumb}


def read_image(path: Path) -> tuple[Image.Image, bytes | None]:
    with Image.open(path) as raw:
        if getattr(raw, 'n_frames', 1) != 1:
            raise ValueError('Use a single still image, not an animation or multi-page image')
        if raw.format == 'PNG':
            with path.open('rb') as header:
                if header.read(25)[24] > 8:
                    raise ValueError('Export an 8-bit PNG before preparing web JPEGs')
        if raw.format == 'TIFF':
            depths = raw.tag_v2.get(258, (1,))
            depths = (depths,) if isinstance(depths, int) else depths
            if any(depth > 8 for depth in depths):
                raise ValueError('Export an 8-bit TIFF before preparing web JPEGs')
        if raw.mode not in ('1', 'L', 'LA', 'P', 'RGB', 'RGBA', 'CMYK'):
            raise ValueError(f'Unsupported image mode {raw.mode}; export an 8-bit image first')
        image = ImageOps.exif_transpose(raw)
        profile = raw.info.get('icc_profile')
        if profile:
            alpha = image.convert('RGBA').getchannel('A')
            working = image if image.mode in ('RGB', 'CMYK', 'L') else image.convert('RGB')
            srgb = ImageCms.ImageCmsProfile(ImageCms.createProfile('sRGB'))
            image = ImageCms.profileToProfile(
                working, ImageCms.ImageCmsProfile(BytesIO(profile)), srgb, outputMode='RGB')
            image.putalpha(alpha)
            profile = srgb.tobytes()
        background = Image.new('RGBA', image.size, (0, 0, 0, 255))
        background.alpha_composite(image.convert('RGBA'))
        return background.convert('RGB'), profile


def prepare(source: Path, output_dir: Path | None = None, *,
            watermark: Path = DEFAULT_WATERMARK, options: Options = Options(),
            overwrite: bool = False) -> list[Path]:
    options.validate()
    source = source.absolute()
    output_dir = output_dir or source.parent
    targets = [output_dir / f'{source.stem}_{kind}.jpg' for kind in ('gallery', 'signed', 'thumb')]
    # Reject all known collisions before decoding or creating any output.
    for target in targets:
        for protected in (source, watermark):
            if target.resolve() == protected.resolve() or (
                    target.exists() and protected.exists() and os.path.samefile(target, protected)):
                raise ValueError(f'Output would replace an input: {target}')
        if os.path.lexists(target) and not overwrite:
            raise FileExistsError(f'{target} already exists; use --overwrite to replace generated versions')
        if target.is_dir():
            raise IsADirectoryError(str(target))
    image, profile = read_image(source)
    with Image.open(watermark) as raw_watermark:
        overlay = raw_watermark.convert('RGBA')
    variants = render_variants(image, overlay, options)
    output_dir.mkdir(parents=True, exist_ok=True)
    # Encode all three before publishing any, so encoding errors leave no outputs.
    with tempfile.TemporaryDirectory(prefix='.prepare-images-', dir=output_dir) as staging:
        for target, result in zip(targets, variants.values()):
            result.save(Path(staging) / target.name, format='JPEG', quality=options.quality,
                        subsampling=0, optimize=True, icc_profile=profile)
        for target in targets:
            staged = Path(staging) / target.name
            if overwrite:
                os.replace(staged, target)
            else:
                # Atomic no-clobber creation, even if a file appeared after preflight.
                os.link(staged, target)
    return targets


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    parser.add_argument('image', type=Path, help='Source still image (never modified)')
    parser.add_argument('--output-dir', type=Path, help='Default: beside the input image')
    parser.add_argument('--watermark', type=Path, default=DEFAULT_WATERMARK, help='Default: bundled filigranne.png')
    parser.add_argument('--thumb-width', type=int, default=740)
    parser.add_argument('--signed-width', type=int, help='Default: input width after EXIF orientation')
    parser.add_argument('--gallery-size', type=int, default=200)
    parser.add_argument('--opacity', type=float, default=0.5)
    parser.add_argument('--center', action='store_true', help="Reproduce the notebook's Center -> True placement")
    parser.add_argument('--quality', type=int, default=90, help='JPEG quality 1–100 (default 90)')
    parser.add_argument('--overwrite', action='store_true', help='Replace existing generated versions')
    args = parser.parse_args()
    options = Options(args.thumb_width, args.signed_width, args.gallery_size,
                      args.opacity, args.center, args.quality)
    try:
        for path in prepare(args.image, args.output_dir, watermark=args.watermark,
                            options=options, overwrite=args.overwrite):
            with Image.open(path) as output:
                print(f'{path}  ({output.width} × {output.height})')
    except (OSError, ValueError, ImageCms.PyCMSError, Image.DecompressionBombError) as exc:
        parser.exit(1, f'Error: {exc}\n')
    return 0


if __name__ == '__main__':
    raise SystemExit(main())
