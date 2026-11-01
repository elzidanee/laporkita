import 'package:flutter_test/flutter_test.dart';
import 'package:laporkita/core/config/app_config.dart';

void main() {
  group('AppConfig MM-01 & MM-02 URL and Secret Hygiene Tests', () {
    test('MM-01: AppConfig.baseUrl and aiServiceUrl default to live api-server and ai-server hosts', () {
      expect(AppConfig.baseUrl, equals('https://api-server.canadev.my.id/api/v1'));
      expect(AppConfig.aiServiceUrl, equals('https://ai-server.canadev.my.id'));
    });

    test('MM-02: AppConfig.aiApiKey and geminiApiKey default to empty string (injected via --dart-define only)', () {
      expect(AppConfig.aiApiKey, isEmpty);
      expect(AppConfig.geminiApiKey, isEmpty);
    });
  });
}
