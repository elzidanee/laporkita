import '../datasources/remote/agency_remote_datasource.dart';
import '../models/agency_model.dart';

class AgencyRepository {
  final AgencyRemoteDatasource _datasource;

  AgencyRepository({AgencyRemoteDatasource? datasource})
      : _datasource = datasource ?? AgencyRemoteDatasource();

  Future<List<AgencyModel>> getAgencies() => _datasource.getAgencies();
}
