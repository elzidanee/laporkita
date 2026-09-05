import 'package:flutter_test/flutter_test.dart';
import 'package:laporkita/core/services/tts_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('TtsService Unit Tests', () {
    late TtsService service;

    setUp(() {
      service = TtsService();
    });

    test('TtsService adalah singleton yang konsisten', () {
      final instance1 = TtsService();
      final instance2 = TtsService();
      expect(identical(instance1, instance2), isTrue);
    });

    test('speak dengan teks kosong tidak melempar exception', () async {
      await expectLater(service.speak('   '), completes);
    });

    test('stop tidak melempar exception', () async {
      await expectLater(service.stop(), completes);
    });
  });
}
