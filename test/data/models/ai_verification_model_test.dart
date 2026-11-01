import 'package:flutter_test/flutter_test.dart';
import 'package:laporkita/data/models/ai_verification_model.dart';

void main() {
  group('AiVerificationResult.fromJson MM-15 Contract Tests', () {
    test('MM-15 (DART-MODEL-05): populates rejectionReason from description_auto when reason key is omitted on invalid/manual-review response', () {
      final oodPayload = {
        'success': true,
        'data': {
          'ai_confidence_score': 0.9999,
          'predicted_category': 'bukan_fasilitas',
          'is_valid': false,
          'needs_manual_review': true,
          'damage_severity': 0.0,
          'description_auto': 'Citra teridentifikasi bukan merupakan kerusakan fasilitas publik (bukan_fasilitas).',
          'gps_valid': true,
          'timestamp_valid': true,
        },
      };

      final parsed = AiVerificationResult.fromJson(oodPayload);
      expect(parsed.isVerified, isFalse);
      expect(parsed.needsManualReview, isTrue);
      expect(parsed.rejectionReason, isNotNull);
      expect(parsed.rejectionReason, contains('bukan_fasilitas'));
    });
  });
}
