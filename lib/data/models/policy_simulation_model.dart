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
        data['recommendedActions'] ??
        data['key_recommendations'] ??
        resultData?['recommended_actions'] ??
        resultData?['recommendedActions'] ??
        resultData?['key_recommendations'] ??
        resultData?['risk_mitigations'] ??
        resultData?['risk_factors'];
    if (rawRecs is List) {
      recs = rawRecs.map((e) => e.toString()).toList();
    }

    String? zName;
    if (data['zone'] is Map<String, dynamic>) {
      zName = (data['zone'] as Map<String, dynamic>)['name'] as String?;
    } else {
      zName = data['zone_name'] as String? ??
          data['zoneName'] as String? ??
          resultData?['target_zone'] as String? ??
          resultData?['target_department'] as String?;
    }

    final num? rawReduction = (data['risk_reduction_pct'] as num?) ??
        (data['riskReductionPct'] as num?) ??
        (data['estimated_complaint_reduction_percent'] as num?) ??
        (data['estimated_incident_reduction_pct'] as num?) ??
        (resultData?['estimated_complaint_reduction_percent'] as num?) ??
        (resultData?['estimated_incident_reduction_pct'] as num?) ??
        (resultData?['risk_reduction_pct'] as num?) ??
        (resultData?['riskReductionPct'] as num?);

    final double reductionPct = rawReduction?.toDouble() ?? 35.0;

    final double riskScore =
        (data['simulated_risk_score'] as num?)?.toDouble() ??
            (data['simulatedRiskScore'] as num?)?.toDouble() ??
            (resultData?['simulated_risk_score'] as num?)?.toDouble() ??
            (resultData?['simulatedRiskScore'] as num?)?.toDouble() ??
            (rawReduction != null
                ? double.parse(
                    (5.0 * (1.0 - (reductionPct.clamp(0.0, 100.0) / 100.0)))
                        .toStringAsFixed(2),
                  )
                : 3.2);

    final double budget =
        (data['estimated_budget_idr'] as num?)?.toDouble() ??
            (data['estimatedBudgetIdr'] as num?)?.toDouble() ??
            (data['budget_estimate_idr'] as num?)?.toDouble() ??
            (resultData?['estimated_budget_idr'] as num?)?.toDouble() ??
            (resultData?['estimatedBudgetIdr'] as num?)?.toDouble() ??
            (resultData?['budget_estimate_idr'] as num?)?.toDouble() ??
            1500000000.0;

    final String impact = (data['impact_analysis'] as String?) ??
        (data['impactAnalysis'] as String?) ??
        (data['result_narrative'] as String?) ??
        (data['resultNarrative'] as String?) ??
        (resultData?['impact_analysis'] as String?) ??
        (resultData?['impactAnalysis'] as String?) ??
        (resultData?['result_narrative'] as String?) ??
        (resultData?['narrative'] as String?) ??
        '';

    final int? weeksToMonths = resultData?['time_to_impact_weeks'] is num
        ? (((resultData!['time_to_impact_weeks'] as num).toDouble() / 4.0)
            .round()
            .clamp(1, 120))
        : null;

    final int horizon = (data['time_horizon_months'] as num?)?.toInt() ??
        (data['timeHorizonMonths'] as num?)?.toInt() ??
        (resultData?['implementation_months'] as num?)?.toInt() ??
        (resultData?['time_horizon_months'] as num?)?.toInt() ??
        (resultData?['timeHorizonMonths'] as num?)?.toInt() ??
        weeksToMonths ??
        6;

    final double confidence =
        (data['confidence_level'] as num?)?.toDouble() ??
            (data['confidenceLevel'] as num?)?.toDouble() ??
            (resultData?['confidence_index'] as num?)?.toDouble() ??
            (resultData?['confidence_level'] as num?)?.toDouble() ??
            (resultData?['confidenceLevel'] as num?)?.toDouble() ??
            0.88;

    final rawCreatedAt = data['created_at'] ?? data['createdAt'];

    return PolicySimulationModel(
      id: data['id']?.toString() ?? '',
      promptText: (data['prompt_text'] as String?) ??
          (data['promptText'] as String?) ??
          '',
      zoneId: (data['zone_id'] as String?) ?? (data['zoneId'] as String?),
      zoneName: zName,
      simulatedRiskScore: riskScore,
      riskReductionPct: reductionPct,
      estimatedBudgetBro: budget,
      impactAnalysis: impact,
      recommendedActions: recs,
      timeHorizonMonths: horizon,
      confidenceLevel: confidence,
      createdAt: rawCreatedAt != null
          ? DateTime.tryParse(rawCreatedAt.toString())
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
