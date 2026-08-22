import '../datasources/remote/category_remote_datasource.dart';
import '../models/category_model.dart';

class CategoryRepository {
  final CategoryRemoteDatasource _datasource;

  CategoryRepository({CategoryRemoteDatasource? datasource})
      : _datasource = datasource ?? CategoryRemoteDatasource();

  Future<List<CategoryModel>> getCategories() => _datasource.getCategories();
}
