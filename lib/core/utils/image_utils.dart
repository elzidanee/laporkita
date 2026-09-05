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

  /// Kompres [filePath] ke file temp. Return path baru (compressed) atau
  /// [filePath] asli jika kompresi gagal / file sudah kecil.
  ///
  /// Target: maxWidth 1280, quality 75 -> hasil ~400-700KB untuk foto 12MP.
  static Future<String> compressIfNeeded(String filePath) async {
    try {
      final file = File(filePath);
      if (!file.existsSync()) return filePath;
      final originalSize = await file.length();
      // Sudah kecil (< 900KB) skip kompresi
      if (originalSize < 900 * 1024) return filePath;

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
      if (await compressedFile.length() >= originalSize) {
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

  /// Encode file di [filePath] ke base64 di isolate (tanpa block UI).
  static Future<String?> fileToBase64Isolate(String filePath) async {
    try {
      final file = File(filePath);
      if (!file.existsSync()) return null;
      final bytes = await file.readAsBytes();
      return await compute(_encodeBase64, bytes);
    } catch (_) {
      return null;
    }
  }
}
