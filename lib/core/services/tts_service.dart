import 'dart:io';
import 'package:flutter_tts/flutter_tts.dart';

/// Service untuk menangani panduan suara navigasi dan Text-to-Speech (TTS) peringatan bahaya jalan rusak
class TtsService {
  static final TtsService _instance = TtsService._internal();
  factory TtsService() => _instance;
  TtsService._internal();

  final FlutterTts _flutterTts = FlutterTts();
  bool _isInitialized = false;
  bool _isPlaying = false;

  bool get isPlaying => _isPlaying;

  /// Inisialisasi engine TTS dengan bahasa Indonesia (id-ID)
  Future<void> initialize() async {
    if (_isInitialized) return;

    try {
      // Set bahasa Indonesia
      final languages = await _flutterTts.getLanguages;
      if (languages != null && languages is List) {
        if (languages.contains('id-ID')) {
          await _flutterTts.setLanguage('id-ID');
        } else if (languages.contains('id')) {
          await _flutterTts.setLanguage('id');
        } else {
          await _flutterTts.setLanguage('id-ID');
        }
      } else {
        await _flutterTts.setLanguage('id-ID');
      }

      // Konfigurasi kecepatan, nada, dan volume bicara
      await _flutterTts.setSpeechRate(0.5); // Kecepatan normal & ramah
      await _flutterTts.setVolume(1.0);     // Volume maksimal
      await _flutterTts.setPitch(1.0);      // Pitch alami

      if (Platform.isIOS) {
        await _flutterTts.setIosAudioCategory(
          IosTextToSpeechAudioCategory.ambientSolo,
          [
            IosTextToSpeechAudioCategoryOptions.allowBluetooth,
            IosTextToSpeechAudioCategoryOptions.defaultToSpeaker,
          ],
        );
      }

      _flutterTts.setStartHandler(() {
        _isPlaying = true;
      });

      _flutterTts.setCompletionHandler(() {
        _isPlaying = false;
      });

      _flutterTts.setCancelHandler(() {
        _isPlaying = false;
      });

      _flutterTts.setErrorHandler((_) {
        _isPlaying = false;
      });

      _isInitialized = true;
    } catch (_) {
      // Tangani jika perangkat tidak memiliki engine TTS
    }
  }

  /// Mengucapkan teks kustom via speaker perangkat
  Future<void> speak(String text) async {
    if (text.trim().isEmpty) return;

    try {
      await initialize();
      await _flutterTts.stop();
      await _flutterTts.speak(text);
    } catch (_) {}
  }

  /// Peringatan suara saat mendekati fasilitas rusak / jalan berlubang (Figma 464:837)
  Future<void> speakHazardAlert({
    required String hazardType,
    required int distanceMeters,
    String? streetName,
  }) async {
    final streetPart = (streetName != null && streetName.trim().isNotEmpty)
        ? ' di $streetName'
        : '';
    final message =
        'Perhatian! $distanceMeters meter di depan terdapat $hazardType$streetPart. Harap kurangi kecepatan dan berhati-hati.';
    await speak(message);
  }

  /// Peringatan suara saat telah melewati titik bahaya (Figma 471:1467)
  Future<void> speakHazardPassed() async {
    const message =
        'Lokasi bahaya telah dilewati. Tetap berhati-hati dan perhatikan kondisi jalan di depan.';
    await speak(message);
  }

  /// Panduan suara instruksi belokan turn-by-turn navigasi (Figma 462:126)
  Future<void> speakInstruction({
    required String instruction,
    String? distanceText,
  }) async {
    final prefix = (distanceText != null && distanceText.trim().isNotEmpty)
        ? 'Dalam $distanceText, '
        : '';
    await speak('$prefix$instruction');
  }

  /// Hentikan suara yang sedang berbicara
  Future<void> stop() async {
    try {
      await _flutterTts.stop();
      _isPlaying = false;
    } catch (_) {}
  }
}
