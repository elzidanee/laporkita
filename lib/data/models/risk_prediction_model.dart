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
  final String riskLevel; // "low" | "medium" | "high"
  final String stressLevel; // "low" | "medium" | "high"
  final String recommendation;
  final Map<String, double> factors;
  final double rainfallMm;
  final double temperatureC;
  final String weatherCondition;
  final int reportDensity;

  const RiskPredictionResult({
    required this.floodRiskProbability,
    this.riskLevel = 'low',
    required this.stressLevel,
    required this.recommendation,
    this.factors = const {},
    required this.rainfallMm,
    required this.temperatureC,
    required this.weatherCondition,
    required this.reportDensity,
  });

  factory RiskPredictionResult.fromJson(Map<String, dynamic> json) {
    final data = json['data'] as Map<String, dynamic>? ?? json;
    final weather = data['weather_context_snapshot'] as Map<String, dynamic>? ??
        data['weather_context'] as Map<String, dynamic>? ??
        {};

    Map<String, double> factorsMap = {};
    if (data['factors'] is Map) {
      factorsMap = (data['factors'] as Map).map(
        (k, v) => MapEntry(k.toString(), (v as num).toDouble()),
      );
    }

    return RiskPredictionResult(
      floodRiskProbability:
          (data['flood_risk_probability'] as num?)?.toDouble() ?? 0.0,
      riskLevel: data['risk_level'] as String? ??
          data['stress_level'] as String? ??
          'low',
      stressLevel: data['predicted_stress_level'] as String? ??
          data['stress_level'] as String? ??
          'low',
      recommendation: data['recommendation'] as String? ??
          data['action_recommendation'] as String? ??
          'Pantau kondisi wilayah secara berkala.',
      factors: factorsMap,
      rainfallMm: (weather['rainfall_mm'] as num?)?.toDouble() ?? 0.0,
      temperatureC: (weather['temperature_c'] as num?)?.toDouble() ?? 27.0,
      weatherCondition: weather['condition'] as String? ?? 'Berawan',
      reportDensity: (data['report_density'] as num?)?.toInt() ?? 0,
    );
  }

  int get floodRiskPercent => (floodRiskProbability * 100).round();
  bool get isHighRisk => stressLevel == 'high' || riskLevel == 'high';
  bool get isMediumRisk => stressLevel == 'medium' || riskLevel == 'medium';
  bool get isLowRisk => stressLevel == 'low' || riskLevel == 'low';
}

/// Model Metrik Zona Per Wilayah (GET /predictions/zones)
class ZoneMetricsModel {
  final String id;
  final String name;
  final String? code;
  final int reportDensity;
  final double trafficDensity;
  final double floodRiskProbability;
  final String stressLevel;
  final String weatherCondition;
  final double rainfallMm;
  final DateTime? updatedAt;

  const ZoneMetricsModel({
    required this.id,
    required this.name,
    this.code,
    required this.reportDensity,
    required this.trafficDensity,
    required this.floodRiskProbability,
    required this.stressLevel,
    required this.weatherCondition,
    required this.rainfallMm,
    this.updatedAt,
  });

  factory ZoneMetricsModel.fromJson(Map<String, dynamic> json) {
    final metric = json['latest_metric'] as Map<String, dynamic>? ?? json;
    final weather = metric['weather_context'] as Map<String, dynamic>? ??
        json['weather_context'] as Map<String, dynamic>? ??
        {};
    return ZoneMetricsModel(
      id: json['id'] as String? ?? '',
      name: json['name'] as String? ?? json['zone_name'] as String? ?? 'Zona',
      code: json['code'] as String?,
      reportDensity: (metric['report_density'] as num?)?.toInt() ??
          (metric['active_reports'] as num?)?.toInt() ??
          (json['report_density'] as num?)?.toInt() ??
          (json['active_reports'] as num?)?.toInt() ??
          0,
      trafficDensity: (metric['traffic_density'] as num?)?.toDouble() ??
          (json['traffic_density'] as num?)?.toDouble() ??
          0.0,
      floodRiskProbability:
          (metric['flood_risk_probability'] as num?)?.toDouble() ??
              (json['flood_risk_probability'] as num?)?.toDouble() ??
              0.0,
      stressLevel: json['stress_level'] as String? ??
          metric['stress_level'] as String? ??
          'low',
      weatherCondition: weather['condition'] as String? ?? 'Berawan',
      rainfallMm: (weather['rainfall_mm'] as num?)?.toDouble() ?? 0.0,
      updatedAt: json['updated_at'] != null
          ? DateTime.tryParse(json['updated_at'].toString())
          : (metric['recorded_at'] != null
              ? DateTime.tryParse(metric['recorded_at'].toString())
              : null),
    );
  }

  int get floodRiskPercent => (floodRiskProbability * 100).round();
}
