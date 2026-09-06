# Preparing artwork manually

From the project root, run:

```sh
uv run scripts/prepare_images.py /path/to/picture.jpg
```

This produces three files beside the input, without modifying it:

- `picture_gallery.jpg`: 200 × 200 pixels, with a diagonal watermark.
- `picture_signed.jpg`: input dimensions (after applying EXIF orientation), with a watermark near the bottom left.
- `picture_thumb.jpg`: 740 pixels wide, proportional height, with a watermark near the bottom left.

The bundled `scripts/assets/filigranne.png` is a copy of the watermark used by the original Mathematica notebook. The script has no dependency on the original project or Mathematica. All three versions are signed, as in the notebook's `Signed -> True` branch.

To generate directly into this blog's source assets:

```sh
uv run scripts/prepare_images.py /path/to/picture.jpg \
  --output-dir static/assets/2026-09-06
```

Then use it in a Verso post:

```text
:::art "assets/2026-09-06/picture" "My picture"
:::
```

Add the gallery image path (`assets/2026-09-06/picture_gallery.jpg`) and its post link to `Blog/Data.lean` when you want it to appear in the gallery. Preparation does not edit Lean files or run during `lake build`. Run `lake exe generate-blog` separately to copy prepared assets into `_site`.

## Options

```sh
uv run scripts/prepare_images.py picture.jpg --opacity 0.3
uv run scripts/prepare_images.py picture.jpg --center
uv run scripts/prepare_images.py picture.jpg --signed-width 1600 --thumb-width 740
uv run scripts/prepare_images.py picture.jpg --gallery-size 300 --quality 95
uv run scripts/prepare_images.py picture.jpg --watermark /path/to/another-watermark.png
uv run scripts/prepare_images.py picture.jpg --overwrite
uv run scripts/prepare_images.py --help
```

Existing output files cause an error before any new output is written. `--overwrite` replaces the three generated versions; input files are protected even if an output is a symlink or hard link to one. If a filesystem error occurs during publication, some of the three completed JPEGs may already have been written. JPEG encoding completes for all three before publication begins.

Supported inputs are 8-bit RGB, RGBA, grayscale, palette, and CMYK still images in formats understood by Pillow, including JPEG and PNG. Transparent pixels are composited onto black. Embedded ICC profiles are converted to sRGB and the resulting profile is embedded. EXIF orientation is applied before resizing, and the orientation tag is not copied to the outputs. Higher-depth and multi-frame images are rejected rather than silently selecting a frame or clipping higher-depth data.

## Notebook mapping

The implementation follows the `Signed -> True` branch of `Create.nb` in the original project's `notebook/Blog` directory:

| Notebook operation | Python behavior |
|---|---|
| String-input `ImageWidth` default | Keep the oriented source width for `_signed` |
| `Width -> 740` | `--thumb-width 740`; preserve aspect ratio |
| `Gallery -> 200` | Resize to width 200, then center-crop or black-pad to 200 × 200 |
| `ImageResize[overlay, Scaled[0.4]]` | Scale the watermark's own dimensions by 0.4 for `_signed` |
| `ImageResize[overlay, Scaled[0.3]]` | Scale the watermark's own dimensions by 0.3 for `_thumb` |
| Gallery watermark | Rotate the original watermark 45° counterclockwise with transparent corners, then scale by 0.3 |
| `Alpha -> 0.5` | Multiply the watermark alpha channel by 0.5 |
| Default signed placement | Center of watermark at (160, 20), measured from the image's bottom-left corner |
| Default thumbnail placement | Center of watermark at (120, 15), measured from the image's bottom-left corner |
| `Center -> True` | Place watermark point (160, 20), or (120, 15) for the thumbnail, at the output image center |
| Gallery placement | Center on the gallery image; (100, 100) with the default size |
| `CompressionLevel -> 0.1` | JPEG quality 90, 4:4:4; approximately comparable quality, not identical encoding |

The original watermark is a **739 × 59 RGB image with white text on black**. Its black background is intentionally retained: with 50% opacity it darkens the rectangle underneath the text. It is not converted into a white-text-only mask. The default scaled sizes are 296 × 24 for signed images and 222 × 18 for thumbnails. Changing image width does not change these watermark sizes or offsets, matching the notebook. Small images may clip the watermark; use `--center` if needed.

Landscape gallery images have black padding above and below; portrait gallery images are center-cropped vertically. This is the original resize-then-crop behavior, not a square cover crop. See Wolfram's [ImageResize](https://reference.wolfram.com/language/ref/ImageResize.html), [ImageCrop](https://reference.wolfram.com/language/ref/ImageCrop.html), and [ImageCompose](https://reference.wolfram.com/language/ref/ImageCompose.html) definitions.

Pillow uses Lanczos resizing and bicubic rotation. New pixel dimensions and composition coordinates round to nearest integer with half values upward; gallery centering uses integer floor division. Mathematica's interpolation, rotation canvas rounding, and JPEG encoder can differ. This is a geometry/appearance port, not a pixel-identical reproduction. No Mathematica kernel was used for validation.

## Python environment and checks

`pyproject.toml` declares Pillow, `uv.lock` pins dependencies, and `uv` uses the project's existing Python 3.12 `.venv`. On a fresh checkout, `uv run` creates/synchronizes the environment automatically. You can also run `uv sync` explicitly.

```sh
uv run python -m unittest discover -s tests -v
```

Tests use synthetic images and temporary directories. They do not regenerate any existing artwork or change the original blog.
