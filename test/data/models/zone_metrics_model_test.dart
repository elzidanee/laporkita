import 'package:flutter_test/flutter_test.dart';
import 'package:laporkita/data/datasources/remote/prediction_remote_datasource.dart';

void main() {
  group('PredictionRemoteDatasource & ZoneMetricsModel MM-13 Contract Tests', () {
    test('MM-13 (DART-MODEL-04): parseZoneMetricsList unwraps {zone, metrics} Map from GET /predictions/zones/{zoneId}/metrics', () {
      final backendDataMap = {
        'zone': {
          'id': 'b1000000-0000-4000-8000-000000000001',
          'name': 'Klojen (Pusat Kota)',
          'stress_level': 'medium',
        },
        'metrics': List.generate(
          20,
          (i) => {
            'id': 'metric-$i',
            'zone_id': 'b1000000-0000-4000-8000-000000000001',
            'report_density': 4 + i,
            'weather_context': {
              'condition': 'Hujan Ringan / Berawan',
              'rainfall_mm': 28.0,
              'humidity_percentage': 82,
              'temperature_celsius': 24.5,
            },
            'traffic_density': 0.5,
            'flood_risk_probability': 0.3339,
            'recorded_at': '2026-11-01T09:00:00.025Z',
          },
        ),
      };

      final items = PredictionRemoteDatasource.parseZoneMetricsList(backendDataMap);

      expect(items, hasLength(20));
      expect(items.first.name, equals('Klojen (Pusat Kota)'));
      expect(items.first.stressLevel, equals('medium'));
      expect(items.first.reportDensity, equals(4));
      expect(items.first.floodRiskProbability, closeTo(0.3339, 0.0001));
      expect(items.first.rainfallMm, equals(28.0));
      expect(items.first.temperatureC, equals(24.5));
    });
  });
}
