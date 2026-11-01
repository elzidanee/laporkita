import 'package:laporkita/core/network/api_response.dart';
import 'package:laporkita/core/network/dio_client.dart';
import 'package:laporkita/data/models/risk_prediction_model.dart';

/// Datasource untuk Metrik Risiko Prediksi Zona (NestJS Backend — /predictions)
class PredictionRemoteDatasource {
  final DioClient _dioClient;

  PredictionRemoteDatasource({DioClient? dioClient})
      : _dioClient = dioClient ?? DioClient();

  /// List seluruh zona beserta metrik risiko terkini — GET /predictions/zones
  Future<ApiResponse<List<ZoneMetricsModel>>> getZones() async {
    return _dioClient.get<List<ZoneMetricsModel>>(
      '/predictions/zones',
      fromJson: (json) {
        if (json is List) {
          return json
              .whereType<Map<String, dynamic>>()
              .map((e) => ZoneMetricsModel.fromJson(e))
              .toList();
        } else if (json is Map<String, dynamic>) {
          final items = json['items'] ?? json['data'];
          if (items is List) {
            return items
                .whereType<Map<String, dynamic>>()
                .map((e) => ZoneMetricsModel.fromJson(e))
                .toList();
          }
        }
        return <ZoneMetricsModel>[];
      },
    );
  }

  static List<ZoneMetricsModel> parseZoneMetricsList(dynamic json) {
    if (json is List) {
      return json
          .whereType<Map<String, dynamic>>()
          .map((e) => ZoneMetricsModel.fromJson(e))
          .toList();
    } else if (json is Map<String, dynamic>) {
      final zone = json['zone'] as Map<String, dynamic>?;
      final rawList = json['metrics'] ?? json['items'] ?? json['data'];
      if (rawList is List) {
        return rawList.whereType<Map<String, dynamic>>().map((e) {
          final merged = <String, dynamic>{
            if (zone != null) ...{
              'zone_name': zone['name'],
              'stress_level': zone['stress_level'],
              'code': zone['code'],
            },
            ...e,
          };
          return ZoneMetricsModel.fromJson(merged);
        }).toList();
      }
    }
    return <ZoneMetricsModel>[];
  }

  /// Histori metrik zona — GET /predictions/zones/:zoneId/metrics
  Future<ApiResponse<List<ZoneMetricsModel>>> getZoneMetrics(
    String zoneId, {
    int limit = 20,
  }) async {
    return _dioClient.get<List<ZoneMetricsModel>>(
      '/predictions/zones/$zoneId/metrics',
      fromJson: parseZoneMetricsList,
      queryParameters: {'limit': limit},
    );
  }

  /// Trigger refresh prediksi metrik seluruh zona — POST /predictions/metrics/refresh
  Future<void> refreshMetrics() async {
    await _dioClient.post<void>(
      '/predictions/metrics/refresh',
      fromJson: (_) {},
      data: {},
    );
  }
}
