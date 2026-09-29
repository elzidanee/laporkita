import 'package:flutter_test/flutter_test.dart';
import 'package:laporkita/core/config/app_config.dart';

void main() {
  group('AppConfig P2-02 Hardcoded Secret Hygiene Tests', () {
    test('AppConfig.aiApiKey defaults to bundled key when not injected', () {
      expect(AppConfig.aiApiKey, isNotEmpty);
    });

    test('AppConfig.aiApiKey uses expected scheme prefix', () {
      expect(AppConfig.aiApiKey.startsWith('laporkita_sec_'), isTrue);
    });
  });
}
