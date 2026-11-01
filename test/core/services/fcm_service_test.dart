import 'package:flutter_test/flutter_test.dart';
import 'package:laporkita/core/services/fcm_service.dart';

void main() {
  group('FcmService MM-12 Startup Auth Gate Tests', () {
    test('MM-12: shouldSyncTokenWithBackend returns false when access token is null or empty (preventing 401 on cold boot)', () {
      expect(FcmService.shouldSyncTokenWithBackend(null), isFalse);
      expect(FcmService.shouldSyncTokenWithBackend(''), isFalse);
      expect(FcmService.shouldSyncTokenWithBackend('   '), isFalse);
      expect(FcmService.shouldSyncTokenWithBackend('eyJhbGciOiJIUzI1NiJ9.valid'), isTrue);
    });
  });
}
