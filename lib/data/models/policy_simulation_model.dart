/// Model Simulasi Kebijakan Publik (POST /policy-simulations & /v1/policy-simulate)
class PolicySimulationModel {
  final String id;
  final String promptText;
  final String? zoneId;
  final String? zoneName;
  final double simulatedRiskScore;
  final double riskReductionPct;
  final double estimatedBudgetBro;
  final String impactAnalysis;
  final List<String> recommendedActions;
  final int timeHorizonMonths;
  final double confidenceLevel;
  final DateTime? createdAt;

  const PolicySimulationModel({
    required this.id,
    required this.promptText,
    this.zoneId,
    this.zoneName,
    required this.simulatedRiskScore,
    required this.riskReductionPct,
    required this.estimatedBudgetBro,
    required this.impactAnalysis,
    required this.recommendedActions,
    this.timeHorizonMonths = 6,
    this.confidenceLevel = 0.85,
    this.createdAt,
  });

  factory PolicySimulationModel.fromJson(Map<String, dynamic> json) {
    final data = json['data'] as Map<String, dynamic>? ?? json;
    final Map<String, dynamic>? resultData =
        data['result_data'] as Map<String, dynamic>? ??
        data['resultData'] as Map<String, dynamic>?;

    List<String> recs = [];
    final rawRecs = data['recommended_actions'] ??
        resultData?['recommended_actions'] ??
        resultData?['recommendedActions'];
    if (rawRecs is List) {
      recs = rawRecs.map((e) => e.toString()).toList();
    }

    String? zName;
    if (data['zone'] is Map<String, dynamic>) {
      zName = (data['zone'] as Map<String, dynamic>)['name'] as String?;
    } else {
      zName = data['zone_name'] as String? ??
          resultData?['target_zone'] as String?;
    }

    final double riskScore =
        (data['simulated_risk_score'] as num?)?.toDouble() ??
            (resultData?['simulated_risk_score'] as num?)?.toDouble() ??
            (resultData?['simulatedRiskScore'] as num?)?.toDouble() ??
            3.2;

    final double reductionPct =
        (data['risk_reduction_pct'] as num?)?.toDouble() ??
            (data['estimated_complaint_reduction_percent'] as num?)?.toDouble() ??
            (resultData?['estimated_complaint_reduction_percent'] as num?)?.toDouble() ??
            (resultData?['risk_reduction_pct'] as num?)?.toDouble() ??
            (resultData?['riskReductionPct'] as num?)?.toDouble() ??
            35.0;

    final double budget =
        (data['estimated_budget_idr'] as num?)?.toDouble() ??
            (resultData?['estimated_budget_idr'] as num?)?.toDouble() ??
            (resultData?['estimatedBudgetIdr'] as num?)?.toDouble() ??
            1500000000.0;

    final String impact = (data['impact_analysis'] as String?) ??
        (data['result_narrative'] as String?) ??
        (resultData?['impact_analysis'] as String?) ??
        (resultData?['result_narrative'] as String?) ??
        '';

    final int horizon = (data['time_horizon_months'] as num?)?.toInt() ??
        (resultData?['implementation_months'] as num?)?.toInt() ??
        (resultData?['time_horizon_months'] as num?)?.toInt() ??
        6;

    final double confidence =
        (data['confidence_level'] as num?)?.toDouble() ??
            (resultData?['confidence_index'] as num?)?.toDouble() ??
            (resultData?['confidence_level'] as num?)?.toDouble() ??
            0.88;

    return PolicySimulationModel(
      id: data['id'] as String? ?? '',
      promptText: data['prompt_text'] as String? ?? '',
      zoneId: data['zone_id'] as String?,
      zoneName: zName,
      simulatedRiskScore: riskScore,
      riskReductionPct: reductionPct,
      estimatedBudgetBro: budget,
      impactAnalysis: impact,
      recommendedActions: recs,
      timeHorizonMonths: horizon,
      confidenceLevel: confidence,
      createdAt: data['created_at'] != null
          ? DateTime.tryParse(data['created_at'].toString())
          : null,
    );
  }

  /// Format Anggaran ke Rp
  String get formattedBudget {
    if (estimatedBudgetBro >= 1000000000) {
      return 'Rp ${(estimatedBudgetBro / 1000000000).toStringAsFixed(1)} Miliar';
    } else if (estimatedBudgetBro >= 1000000) {
      return 'Rp ${(estimatedBudgetBro / 1000000).toStringAsFixed(0)} Juta';
    }
    return 'Rp ${estimatedBudgetBro.toStringAsFixed(0)}';
  }
}
