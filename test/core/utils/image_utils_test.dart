import 'package:flutter_test/flutter_test.dart';
import 'package:laporkita/core/utils/image_utils.dart';

void main() {
  group('ImageUtils MM-08 Magic Byte & Transcode Gate Tests', () {
    test('MM-08: detects JPEG and PNG magic bytes and forces transcoding on < 900KB WebP', () {
      const jpegHeader = [0xFF, 0xD8, 0xFF, 0xE0, 0x00, 0x10];
      const pngHeader = [0x89, 0x50, 0x4E, 0x47, 0x0D, 0x0A, 0x1A, 0x0A];
      // RIFF....WEBP
      const webpHeader = [
        0x52, 0x49, 0x46, 0x46, 0x24, 0x00, 0x00, 0x00, 0x57, 0x45, 0x42, 0x50
      ];

      expect(ImageUtils.isSupportedJpegOrPngBytes(jpegHeader), isTrue);
      expect(ImageUtils.isSupportedJpegOrPngBytes(pngHeader), isTrue);
      expect(ImageUtils.isSupportedJpegOrPngBytes(webpHeader), isFalse);

      // < 900KB JPEG/PNG can skip re-compression
      expect(ImageUtils.shouldSkipCompression(150 * 1024, jpegHeader), isTrue);
      expect(ImageUtils.shouldSkipCompression(150 * 1024, pngHeader), isTrue);

      // < 900KB WebP MUST NOT skip compression (must transcode to JPEG for Backend FileValidationPipe)
      expect(ImageUtils.shouldSkipCompression(150 * 1024, webpHeader), isFalse);

      // >= 900KB JPEG must compress
      expect(ImageUtils.shouldSkipCompression(950 * 1024, jpegHeader), isFalse);
    });
  });
}
