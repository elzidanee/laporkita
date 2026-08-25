import '../datasources/remote/prediction_remote_datasource.dart';
import '../models/risk_prediction_model.dart';

class PredictionRepository {
  final PredictionRemoteDatasource _datasource;

  PredictionRepository({PredictionRemoteDatasource? datasource})
      : _datasource = datasource ?? PredictionRemoteDatasource();

  Future<List<ZoneMetricsModel>> getZones() async {
    final response = await _datasource.getZones();
    return response.data ?? [];
  }

  Future<List<ZoneMetricsModel>> getZoneMetrics(
    String zoneId, {
    int limit = 20,
  }) async {
    final response = await _datasource.getZoneMetrics(zoneId, limit: limit);
    return response.data ?? [];
  }

  Future<void> refreshMetrics() {
    return _datasource.refreshMetrics();
  }
}
