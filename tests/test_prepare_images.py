import hashlib
from pathlib import Path
import tempfile
import unittest

from PIL import Image, ImageCms
from scripts.prepare_images import Options, compose, prepare, read_image, render_variants, square_gallery


class ImagePreparationTests(unittest.TestCase):
    def test_sizes_and_aspect_ratios(self):
        overlay = Image.new('RGBA', (739, 59), (255, 255, 255, 255))
        for size, thumb in [((1200, 800), (740, 493)), ((600, 1200), (740, 1480)), ((500, 500), (740, 740))]:
            with self.subTest(size=size):
                result = render_variants(Image.new('RGB', size), overlay, Options())
                self.assertEqual(result['signed'].size, size)
                self.assertEqual(result['thumb'].size, thumb)
                self.assertEqual(result['gallery'].size, (200, 200))

    def test_gallery_landscape_is_padded_not_cover_cropped(self):
        result = square_gallery(Image.new('RGB', (800, 400), 'red'), 200)
        self.assertEqual(result.getpixel((100, 20)), (0, 0, 0))
        self.assertEqual(result.getpixel((100, 100)), (255, 0, 0))
        self.assertEqual(result.getpixel((100, 180)), (0, 0, 0))

    def test_gallery_portrait_is_center_cropped(self):
        image = Image.new('RGB', (200, 600), 'blue')
        image.paste('red', (0, 200, 200, 400))
        result = square_gallery(image, 200)
        self.assertEqual(result.getextrema(), ((255, 255), (0, 0), (0, 0)))

    def test_compositing_bottom_origin_alpha_and_black_background(self):
        result = compose(Image.new('RGB', (100, 100), 'white'),
                         Image.new('RGBA', (20, 10), (0, 0, 0, 255)), .5, (20, 10))
        self.assertEqual(result.getpixel((10, 85)), (127, 127, 127))
        self.assertEqual(result.getpixel((10, 15)), (255, 255, 255))
        unchanged = compose(result, Image.new('RGBA', (20, 10), (255, 0, 0, 0)), .5, (20, 10))
        self.assertEqual(unchanged.tobytes(), result.tobytes())

    def test_explicit_overlay_anchor_and_clipping(self):
        image = Image.new('RGB', (100, 100), 'white')
        overlay = Image.new('RGBA', (20, 10), 'black')
        result = compose(image, overlay, 1, (50, 50), (16, 2))
        self.assertEqual(result.getpixel((34, 42)), (0, 0, 0))
        self.assertEqual(result.getpixel((33, 42)), (255, 255, 255))
        self.assertEqual(compose(image, overlay, 1, (0, 0)).size, (100, 100))

    def test_preserves_input_and_refuses_partial_overwrite(self):
        with tempfile.TemporaryDirectory() as tmp:
            path = Path(tmp) / 'picture.png'
            Image.new('RGB', (900, 600), 'cyan').save(path)
            before = hashlib.sha256(path.read_bytes()).digest()
            outputs = prepare(path)
            self.assertEqual([p.name for p in outputs], ['picture_gallery.jpg', 'picture_signed.jpg', 'picture_thumb.jpg'])
            snapshots = [p.read_bytes() for p in outputs]
            with self.assertRaises(FileExistsError):
                prepare(path)
            self.assertEqual([p.read_bytes() for p in outputs], snapshots)
            prepare(path, options=Options(opacity=0), overwrite=True)
            self.assertEqual(hashlib.sha256(path.read_bytes()).digest(), before)
            outputs[0].unlink()
            with self.assertRaises(FileExistsError):
                prepare(path)
            self.assertFalse(outputs[0].exists())
            self.assertFalse(list(Path(tmp).glob('.prepare-images-*')))

    def test_exif_orientation_is_applied_once(self):
        with tempfile.TemporaryDirectory() as tmp:
            path = Path(tmp) / 'rotated.jpg'
            image = Image.new('RGB', (80, 40), 'red')
            exif = Image.Exif(); exif[274] = 6
            image.save(path, exif=exif)
            result, _ = read_image(path)
            self.assertEqual(result.size, (40, 80))
            outputs = prepare(path)
            with Image.open(outputs[1]) as result:
                self.assertEqual(result.size, (40, 80))
                self.assertIsNone(result.getexif().get(274))

    def test_icc_and_transparency(self):
        with tempfile.TemporaryDirectory() as tmp:
            path = Path(tmp) / 'profile.png'
            profile = ImageCms.ImageCmsProfile(ImageCms.createProfile('sRGB')).tobytes()
            Image.new('RGBA', (100, 100), (255, 0, 0, 0)).save(path, icc_profile=profile)
            image, result_profile = read_image(path)
            self.assertEqual(image.getpixel((0, 0)), (0, 0, 0))
            self.assertTrue(result_profile)
            outputs = prepare(path)
            with Image.open(outputs[1]) as output:
                self.assertTrue(output.info.get('icc_profile'))

    def test_rejects_high_depth(self):
        with tempfile.TemporaryDirectory() as tmp:
            path = Path(tmp) / 'deep.png'
            Image.new('I;16', (20, 20), 40000).save(path)
            with self.assertRaises(ValueError):
                prepare(path)
            self.assertEqual(list(Path(tmp).glob('*.jpg')), [])

    def test_invalid_options_create_no_outputs(self):
        for options in [Options(opacity=float('nan')), Options(quality=101), Options(signed_width=0)]:
            with self.assertRaises(ValueError):
                options.validate()

    def test_source_alias_is_protected_even_with_overwrite(self):
        with tempfile.TemporaryDirectory() as tmp:
            source = Path(tmp) / 'picture.jpg'
            Image.new('RGB', (100, 100)).save(source)
            (Path(tmp) / 'picture_signed.jpg').symlink_to(source)
            with self.assertRaises(ValueError):
                prepare(source, overwrite=True)
            self.assertFalse((Path(tmp) / 'picture_gallery.jpg').exists())


if __name__ == '__main__':
    unittest.main()
