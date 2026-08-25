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

    List<String> recs = [];
    final rawRecs = data['recommended_actions'];
    if (rawRecs is List) {
      recs = rawRecs.map((e) => e.toString()).toList();
    }

    String? zName;
    if (data['zone'] is Map<String, dynamic>) {
      zName = (data['zone'] as Map<String, dynamic>)['name'] as String?;
    } else {
      zName = data['zone_name'] as String?;
    }

    return PolicySimulationModel(
      id: data['id'] as String? ?? '',
      promptText: data['prompt_text'] as String? ?? '',
      zoneId: data['zone_id'] as String?,
      zoneName: zName,
      simulatedRiskScore:
          (data['simulated_risk_score'] as num?)?.toDouble() ?? 0.0,
      riskReductionPct:
          (data['risk_reduction_pct'] as num?)?.toDouble() ?? 0.0,
      estimatedBudgetBro:
          (data['estimated_budget_idr'] as num?)?.toDouble() ?? 0.0,
      impactAnalysis: data['impact_analysis'] as String? ?? '',
      recommendedActions: recs,
      timeHorizonMonths:
          (data['time_horizon_months'] as num?)?.toInt() ?? 6,
      confidenceLevel:
          (data['confidence_level'] as num?)?.toDouble() ?? 0.85,
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
