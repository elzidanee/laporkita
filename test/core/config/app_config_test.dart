import 'package:flutter_test/flutter_test.dart';
import 'package:laporkita/core/config/app_config.dart';

void main() {
  group('AppConfig P2-02 Hardcoded Secret Hygiene Tests', () {
    test('AppConfig.aiApiKey defaults to empty string when not injected', () {
      expect(AppConfig.aiApiKey, isEmpty);
      expect(AppConfig.aiApiKey, equals(''));
    });

    test('AppConfig.aiApiKey does not leak hardcoded credential strings', () {
      expect(AppConfig.aiApiKey.contains('laporkita-'), isFalse);
    });
  });
}
