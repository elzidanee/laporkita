import 'package:latlong2/latlong.dart';
import '../datasources/remote/routing_remote_datasource.dart';
import '../models/route_model.dart';

/// Repository untuk mengakses layanan rute dan navigasi OSRM.
class RoutingRepository {
  final RoutingRemoteDatasource _datasource;

  RoutingRepository({RoutingRemoteDatasource? datasource})
      : _datasource = datasource ?? RoutingRemoteDatasource();

  /// Mendapatkan kalkulasi rute dari titik [origin] ke [destination].
  Future<RouteModel> getRoute({
    required LatLng origin,
    required LatLng destination,
  }) {
    return _datasource.getRoute(origin: origin, destination: destination);
  }
}
