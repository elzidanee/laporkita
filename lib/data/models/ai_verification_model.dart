/// Model hasil verifikasi AI laporan dari POST /v1/verify
class AiVerificationResult {
  final bool isVerified;
  final bool needsManualReview;
  final double confidence;
  final String detectedCategory;
  final double urgencyScore;
  final String autoDescription;
  final bool isWithinMalang;
  final bool timestampValid;
  final String? rejectionReason;
  final String? rawStatus;
  final Map<String, double>? classProbabilities;

  const AiVerificationResult({
    required this.isVerified,
    required this.needsManualReview,
    required this.confidence,
    required this.detectedCategory,
    required this.urgencyScore,
    required this.autoDescription,
    required this.isWithinMalang,
    this.timestampValid = true,
    this.rejectionReason,
    this.rawStatus,
    this.classProbabilities,
  });

  factory AiVerificationResult.fromJson(Map<String, dynamic> json) {
    // Envelope response data check
    final data = json['data'] as Map<String, dynamic>? ?? json;

    final bool isVal = (data['is_valid'] as bool?) ??
        (data['is_verified'] as bool?) ??
        false;

    final bool gpsVal = (data['gps_valid'] as bool?) ??
        (data['is_valid_gps'] as bool?) ??
        (data['is_within_malang'] as bool?) ??
        true;

    final bool needsReview = (data['needs_manual_review'] as bool?) ??
        (isVal == false && gpsVal == true);

    final double conf = (data['ai_confidence_score'] as num?)?.toDouble() ??
        (data['confidence'] as num?)?.toDouble() ??
        0.0;

    final String cat = (data['predicted_category'] as String?) ??
        (data['detected_category'] as String?) ??
        (data['category'] as String?) ??
        'Tidak Terdeteksi';

    final double severity = (data['damage_severity'] as num?)?.toDouble() ??
        (data['urgency_score'] as num?)?.toDouble() ??
        0.0;

    final String desc = (data['description_auto'] as String?) ??
        (data['auto_description'] as String?) ??
        '';

    final bool tsVal = (data['timestamp_valid'] as bool?) ??
        (data['is_valid_timestamp'] as bool?) ??
        true;

    final String? reason = (data['reason'] as String?) ??
        (data['rejection_reason'] as String?);

    Map<String, double>? probs;
    if (data['class_probabilities'] is Map) {
      probs = (data['class_probabilities'] as Map).map(
        (k, v) => MapEntry(k.toString(), (v as num).toDouble()),
      );
    }

    return AiVerificationResult(
      isVerified: isVal,
      needsManualReview: needsReview,
      confidence: conf,
      detectedCategory: cat,
      urgencyScore: severity,
      autoDescription: desc,
      isWithinMalang: gpsVal,
      timestampValid: tsVal,
      rejectionReason: reason,
      rawStatus: data['verification_status'] as String?,
      classProbabilities: probs,
    );
  }

  /// Confidence dalam persen (0-100)
  int get confidencePercent => (confidence * 100).round();

  /// Urgency score dalam persen (0-100)
  int get urgencyPercent => (urgencyScore * 100).round();
}
