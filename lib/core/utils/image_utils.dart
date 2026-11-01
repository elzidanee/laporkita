import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:path_provider/path_provider.dart';

String _encodeBase64(Uint8List bytes) => base64Encode(bytes);

/// Helper kompresi & encode gambar untuk mengurangi latency upload.
///
/// - Kompres foto kamera 5-10MB -> target ~700KB sebelum multipart
/// - Encode base64 di isolate agar tidak freeze UI
class ImageUtils {
  ImageUtils._();
  /// Periksa apakah byte awal file adalah JPEG (FF D8 FF) atau PNG (89 50 4E 47)
  static bool isSupportedJpegOrPngBytes(List<int> bytes) {
    if (bytes.length >= 3 &&
        bytes[0] == 0xFF &&
        bytes[1] == 0xD8 &&
        bytes[2] == 0xFF) {
      return true;
    }
    if (bytes.length >= 4 &&
        bytes[0] == 0x89 &&
        bytes[1] == 0x50 &&
        bytes[2] == 0x4E &&
        bytes[3] == 0x47) {
      return true;
    }
    return false;
  }

  /// Hanya lewati kompresi jika ukuran < 900KB DAN format sudah JPEG/PNG.
  /// Jika WebP/HEIC, wajib ditranskode ke JPEG agar lolos FileValidationPipe backend.
  static bool shouldSkipCompression(int originalSizeBytes, List<int> headerBytes) {
    return originalSizeBytes < 900 * 1024 &&
        isSupportedJpegOrPngBytes(headerBytes);
  }

  static Future<String> compressIfNeeded(String filePath) async {
    try {
      final file = File(filePath);
      if (!file.existsSync()) return filePath;
      final originalSize = await file.length();
      final headerBytes = await file.openRead(0, 12).fold<List<int>>(
        <int>[],
        (prev, chunk) => prev..addAll(chunk),
      );
      final isNativeJpegOrPng = isSupportedJpegOrPngBytes(headerBytes);
      if (shouldSkipCompression(originalSize, headerBytes)) return filePath;

      final tmpDir = await getTemporaryDirectory();
      final targetPath =
          '${tmpDir.path}/cmp_${DateTime.now().millisecondsSinceEpoch}.jpg';

      final XFile? compressed = await FlutterImageCompress.compressAndGetFile(
        filePath,
        targetPath,
        minWidth: 1280,
        minHeight: 1280,
        quality: 75,
        format: CompressFormat.jpeg,
      );

      if (compressed == null) return filePath;
      final compressedFile = File(compressed.path);
      if (!compressedFile.existsSync()) return filePath;
      if (isNativeJpegOrPng && await compressedFile.length() >= originalSize) {
        try {
          await compressedFile.delete();
        } catch (_) {}
        return filePath;
      }
      return compressed.path;
    } catch (_) {
      return filePath;
    }
  }

  /// Encode file di [filePath] ke base64 di isolate (kompres/transkode terlebih dahulu).
  static Future<String?> fileToBase64Isolate(String filePath) async {
    try {
      final normalizedPath = await compressIfNeeded(filePath);
      final file = File(normalizedPath);
      if (!file.existsSync()) return null;
      final bytes = await file.readAsBytes();
      return await compute(_encodeBase64, bytes);
    } catch (_) {
      return null;
    }
  }
}
