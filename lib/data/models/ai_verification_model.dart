/// Model hasil verifikasi AI laporan dari POST /v1/verify
class AiVerificationResult {
  final bool isVerified;
  final double confidence;
  final String detectedCategory;
  final double urgencyScore;
  final String autoDescription;
  final bool isWithinMalang;
  final String? rejectionReason;
  final String? rawStatus; // "auto_verified" | "manual_review" | "rejected"

  const AiVerificationResult({
    required this.isVerified,
    required this.confidence,
    required this.detectedCategory,
    required this.urgencyScore,
    required this.autoDescription,
    required this.isWithinMalang,
    this.rejectionReason,
    this.rawStatus,
  });

  factory AiVerificationResult.fromJson(Map<String, dynamic> json) {
    // Response ada di json['data']
    final data = json['data'] as Map<String, dynamic>? ?? json;
    return AiVerificationResult(
      isVerified: data['is_verified'] as bool? ?? false,
      confidence: (data['confidence'] as num?)?.toDouble() ?? 0.0,
      detectedCategory: data['detected_category'] as String? ?? 'Tidak Terdeteksi',
      urgencyScore: (data['urgency_score'] as num?)?.toDouble() ?? 0.0,
      autoDescription: data['auto_description'] as String? ?? '',
      isWithinMalang: data['is_within_malang'] as bool? ?? false,
      rejectionReason: data['rejection_reason'] as String?,
      rawStatus: data['verification_status'] as String?,
    );
  }

  /// Confidence dalam persen (0-100)
  int get confidencePercent => (confidence * 100).round();

  /// Urgency score dalam persen (0-100)
  int get urgencyPercent => (urgencyScore * 100).round();
}
