/// Model weather context untuk dikirim ke POST /v1/predict-risk
class WeatherContextRequest {
  final double rainfallMm;
  final double temperatureC;
  final String condition;
  final double drainageIssueRatio;

  const WeatherContextRequest({
    this.rainfallMm = 0.0,
    this.temperatureC = 27.0,
    this.condition = 'Berawan',
    this.drainageIssueRatio = 0.2,
  });

  Map<String, dynamic> toJson() => {
        'rainfall_mm': rainfallMm,
        'temperature_c': temperatureC,
        'condition': condition,
        'drainage_issue_ratio': drainageIssueRatio,
      };
}

/// Model hasil prediksi risiko wilayah dari POST /v1/predict-risk
class RiskPredictionResult {
  final double floodRiskProbability;
  final String stressLevel; // "low" | "medium" | "high"
  final String recommendation;
  final double rainfallMm;
  final double temperatureC;
  final String weatherCondition;
  final int reportDensity;

  const RiskPredictionResult({
    required this.floodRiskProbability,
    required this.stressLevel,
    required this.recommendation,
    required this.rainfallMm,
    required this.temperatureC,
    required this.weatherCondition,
    required this.reportDensity,
  });

  factory RiskPredictionResult.fromJson(Map<String, dynamic> json) {
    final data = json['data'] as Map<String, dynamic>? ?? json;
    final weather = data['weather_context_snapshot'] as Map<String, dynamic>?
        ?? data['weather_context'] as Map<String, dynamic>?
        ?? {};
    return RiskPredictionResult(
      floodRiskProbability: (data['flood_risk_probability'] as num?)?.toDouble() ?? 0.0,
      stressLevel: data['stress_level'] as String? ?? 'low',
      recommendation: data['recommendation'] as String?
          ?? data['action_recommendation'] as String?
          ?? 'Pantau kondisi wilayah secara berkala.',
      rainfallMm: (weather['rainfall_mm'] as num?)?.toDouble() ?? 0.0,
      temperatureC: (weather['temperature_c'] as num?)?.toDouble() ?? 27.0,
      weatherCondition: weather['condition'] as String? ?? 'Berawan',
      reportDensity: (data['report_density'] as num?)?.toInt() ?? 0,
    );
  }

  /// Flood risk dalam persen (0-100)
  int get floodRiskPercent => (floodRiskProbability * 100).round();

  /// Apakah risiko tinggi?
  bool get isHighRisk => stressLevel == 'high';
  bool get isMediumRisk => stressLevel == 'medium';
  bool get isLowRisk => stressLevel == 'low';
}
