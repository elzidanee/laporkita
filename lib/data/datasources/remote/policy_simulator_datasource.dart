import 'package:laporkita/core/network/api_response.dart';
import 'package:laporkita/core/network/dio_client.dart';
import 'package:laporkita/data/models/policy_simulation_model.dart';

/// Datasource untuk Policy Simulator (NestJS Backend — /policy-simulations)
class PolicySimulatorDatasource {
  final DioClient _dioClient;

  PolicySimulatorDatasource({DioClient? dioClient})
      : _dioClient = dioClient ?? DioClient();

  /// Jalankan Simulasi Kebijakan Publik Baru — POST /policy-simulations
  Future<PolicySimulationModel> createSimulation({
    required String promptText,
    String? zoneId,
  }) async {
    final payload = <String, dynamic>{
      'prompt_text': promptText,
      if (zoneId != null && zoneId.isNotEmpty) 'zone_id': zoneId,
    };

    final response = await _dioClient.post<PolicySimulationModel>(
      '/policy-simulations',
      fromJson: (json) =>
          PolicySimulationModel.fromJson(json as Map<String, dynamic>),
      data: payload,
    );
    return response.data!;
  }

  /// Daftar Riwayat Simulasi Kebijakan — GET /policy-simulations
  Future<ApiResponse<List<PolicySimulationModel>>> getSimulations({
    int limit = 20,
    String? cursor,
  }) async {
    return _dioClient.get<List<PolicySimulationModel>>(
      '/policy-simulations',
      fromJson: (json) {
        if (json is List) {
          return json
              .whereType<Map<String, dynamic>>()
              .map((e) => PolicySimulationModel.fromJson(e))
              .toList();
        } else if (json is Map<String, dynamic>) {
          final items = json['items'] ?? json['data'];
          if (items is List) {
            return items
                .whereType<Map<String, dynamic>>()
                .map((e) => PolicySimulationModel.fromJson(e))
                .toList();
          }
        }
        return <PolicySimulationModel>[];
      },
      queryParameters: {
        'limit': limit,
        if (cursor case final c?) 'cursor': c,
      },
    );
  }

  /// Detail Simulasi Kebijakan — GET /policy-simulations/:id
  Future<PolicySimulationModel> getSimulationById(String id) async {
    final response = await _dioClient.get<PolicySimulationModel>(
      '/policy-simulations/$id',
      fromJson: (json) =>
          PolicySimulationModel.fromJson(json as Map<String, dynamic>),
    );
    return response.data!;
  }
}
