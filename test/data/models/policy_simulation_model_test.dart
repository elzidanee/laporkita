import 'package:flutter_test/flutter_test.dart';
import 'package:laporkita/data/models/policy_simulation_model.dart';

void main() {
  group('PolicySimulationModel.fromJson MM-04 Contract Tests', () {
    test('MM-04 (DART-MODEL-02): parses AI Service POST /v1/policy-simulate payload fields accurately without falling back to hardcoded defaults', () {
      final aiPayload = {
        'success': true,
        'data': {
          'result_narrative': 'Analisis dampak kebijakan normalisasi drainase di wilayah Klojen Kota Malang.',
          'result_data': {
            'estimated_incident_reduction_pct': 42.5,
            'budget_estimate_idr': 4750000000,
            'time_to_impact_weeks': 12,
            'target_department': 'DPUPRPKP Kota Malang',
            'public_satisfaction_increase_pct': 32,
            'risk_mitigations': [
              'Sosialisasi jadwal pengerjaan kepada masyarakat Klojen',
              'Penyediaan jalur alternatif selama pengerjaan',
            ],
          },
          'key_recommendations': [
            'Menerapkan program pemeliharaan drainase rutin pasca-normalisasi',
            'Mengintegrasikan data curah hujan dengan pemantauan drainase',
            'Melakukan edukasi tidak membuang sampah ke saluran drainase',
          ],
          'model_used': 'gemini-2.5-flash',
        },
        'error': null,
      };

      final model = PolicySimulationModel.fromJson(aiPayload);

      expect(model.riskReductionPct, equals(42.5));
      expect(model.estimatedBudgetBro, equals(4750000000.0));
      expect(model.timeHorizonMonths, equals(3));
      expect(model.recommendedActions, hasLength(3));
      expect(model.recommendedActions.first, contains('pemeliharaan drainase'));
      expect(model.simulatedRiskScore, isNot(equals(3.2)));
      expect(model.simulatedRiskScore, closeTo(2.88, 0.05));
    });

    test('MM-04 (DART-MODEL-01): parses Backend POST /policy-simulations camelCase and snake_case fields', () {
      final backendPayload = {
        'success': true,
        'data': {
          'id': 'sim-uuid-01',
          'promptText': 'Normalisasi drainase Klojen',
          'zoneId': 'b1000000-0000-4000-8000-000000000001',
          'resultNarrative': 'Analisis komprehensif normalisasi drainase Klojen.',
          'resultData': {
            'estimated_complaint_reduction_percent': 44.0,
            'estimated_budget_idr': 1450000000,
            'implementation_months': 6,
            'target_zone': 'Klojen (Pusat Kota)',
            'confidence_index': 0.88,
            'risk_factors': [
              'Curah hujan tinggi pada musim penghujan',
              'Disrupsi arus lalu lintas lokal',
            ],
          },
          'createdAt': '2026-11-01T08:56:16.289Z',
        },
      };

      final model = PolicySimulationModel.fromJson(backendPayload);

      expect(model.id, equals('sim-uuid-01'));
      expect(model.promptText, equals('Normalisasi drainase Klojen'));
      expect(model.zoneId, equals('b1000000-0000-4000-8000-000000000001'));
      expect(model.impactAnalysis, contains('Analisis komprehensif'));
      expect(model.riskReductionPct, equals(44.0));
      expect(model.estimatedBudgetBro, equals(1450000000.0));
      expect(model.simulatedRiskScore, closeTo(2.80, 0.05));
      expect(model.recommendedActions, isNotEmpty);
    });
  });
}
