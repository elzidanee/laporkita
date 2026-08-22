import 'package:laporkita/core/network/dio_client.dart';
import 'package:laporkita/data/models/category_model.dart';

/// Category Remote Datasource
/// STATUS: VERIFIED — GET /categories (publik, dari categories.controller.ts)
class CategoryRemoteDatasource {
  final DioClient _dioClient;

  CategoryRemoteDatasource({DioClient? dioClient})
      : _dioClient = dioClient ?? DioClient();

  Future<List<CategoryModel>> getCategories() async {
    final response = await _dioClient.get<List<CategoryModel>>(
      '/categories',
      fromJson: (json) => (json as List<dynamic>)
          .map((e) => CategoryModel.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
    return response.data ?? [];
  }
}
