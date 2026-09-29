import 'package:laporkita/core/network/dio_client.dart';
import 'package:laporkita/data/models/agency_model.dart';

/// Agency Remote Datasource.
/// STATUS: NOT YET VERIFIED — GET /agencies butuh Bearer (lihat Swagger),
/// skema response belum pasti. Parse defensif: terima List langsung
/// maupun envelope {items|data|agencies}.
class AgencyRemoteDatasource {
  final DioClient _dioClient;

  AgencyRemoteDatasource({DioClient? dioClient})
      : _dioClient = dioClient ?? DioClient();

  Future<List<AgencyModel>> getAgencies() async {
    final response = await _dioClient.get<List<AgencyModel>>(
      '/agencies',
      fromJson: (json) {
        if (json is List) {
          return json
              .whereType<Map<String, dynamic>>()
              .map((e) => AgencyModel.fromJson(e))
              .toList();
        } else if (json is Map<String, dynamic>) {
          final items = json['items'] ?? json['data'] ?? json['agencies'];
          if (items is List) {
            return items
                .whereType<Map<String, dynamic>>()
                .map((e) => AgencyModel.fromJson(e))
                .toList();
          }
        }
        return <AgencyModel>[];
      },
    );
    return response.data ?? [];
  }
}
