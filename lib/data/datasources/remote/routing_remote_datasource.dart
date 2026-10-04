import 'package:dio/dio.dart';
import 'package:latlong2/latlong.dart';
import '../../../core/network/api_exception.dart';
import '../../../core/network/dio_client.dart';
import '../../models/route_model.dart';

class _CachedRoutes {
  final List<RouteModel> routes;
  final DateTime fetchedAt;
  _CachedRoutes(this.routes) : fetchedAt = DateTime.now();
  bool get isExpired =>
      DateTime.now().difference(fetchedAt) > const Duration(minutes: 5);
}

/// Remote datasource untuk OSRM dengan cache in-memory + deduplikasi request.
///
/// - Cache 5 menit per pasangan origin->destination (key dibulatkan 4 desimal ~11m)
/// - Menyimpan seluruh opsi rute alternatif
/// - Deduplikasi: request concurrent yang sama share Future yang sama
class RoutingRemoteDatasource {
  final Dio _dio;

  // Static agar cache survive antar instance Repository
  static final Map<String, _CachedRoutes> _cache = {};
  static final Map<String, Future<List<RouteModel>>> _inFlight = {};

  RoutingRemoteDatasource({Dio? dio}) : _dio = dio ?? DioClient().dio;

  static String _key(LatLng o, LatLng d) =>
      '${o.latitude.toStringAsFixed(4)},${o.longitude.toStringAsFixed(4)}'
      '->${d.latitude.toStringAsFixed(4)},${d.longitude.toStringAsFixed(4)}';

  /// Bersihkan cache (mis. saat user ganti kota atau pull-to-refresh)
  static void clearCache() {
    _cache.clear();
  }

  Future<RouteModel> getRoute({
    required LatLng origin,
    required LatLng destination,
  }) async {
    final routes = await getRoutes(
      origin: origin,
      destination: destination,
      alternatives: false,
    );
    return routes.first;
  }

  Future<List<RouteModel>> getRoutes({
    required LatLng origin,
    required LatLng destination,
    bool alternatives = true,
  }) async {
    final key = '${_key(origin, destination)}_${alternatives ? "alt" : "single"}';

    // 1. Hit cache
    final cached = _cache[key];
    if (cached != null && !cached.isExpired) return cached.routes;
    if (cached != null && cached.isExpired) _cache.remove(key);

    // 2. Deduplikasi concurrent requests
    final inflight = _inFlight[key];
    if (inflight != null) return inflight;

    final future = _fetchRoutes(origin, destination, alternatives: alternatives);
    _inFlight[key] = future;

    try {
      final routes = await future;
      if (routes.isNotEmpty) {
        _cache[key] = _CachedRoutes(routes);
      }
      return routes;
    } finally {
      _inFlight.remove(key);
    }
  }

  Future<List<RouteModel>> _fetchRoutes(
    LatLng origin,
    LatLng destination, {
    bool alternatives = true,
  }) async {
    final payload = <String, dynamic>{
      'origin_lat': origin.latitude,
      'origin_lng': origin.longitude,
      'destination_lat': destination.latitude,
      'destination_lng': destination.longitude,
    };

    try {
      final response = await _dio.post('/maps/route', data: payload);

      if (response.data is Map<String, dynamic>) {
        return RouteModel.fromBackendMapsJson(response.data as Map<String, dynamic>);
      } else {
        throw const RouteNotFoundException(
          'Format data respons dari server rute tidak valid.',
        );
      }
    } on DioException catch (e) {
      if (e.type == DioExceptionType.connectionTimeout ||
          e.type == DioExceptionType.sendTimeout ||
          e.type == DioExceptionType.receiveTimeout ||
          e.type == DioExceptionType.connectionError) {
        throw const NetworkException(
          'Tidak dapat terhubung ke server rute. Periksa koneksi internet Anda.',
        );
      }

      final data = e.response?.data;
      if (data is Map<String, dynamic>) {
        final err = data['error'];
        String message = 'Gagal mendapatkan rute.';
        if (err is Map<String, dynamic>) {
          message = err['message'] as String? ?? message;
        } else if (data['message'] is String) {
          message = data['message'] as String;
        }
        throw RouteNotFoundException(message);
      }

      throw NetworkException(
        e.message ?? 'Terjadi kesalahan jaringan saat memanggil server rute.',
      );
    } catch (e) {
      if (e is RouteNotFoundException || e is NetworkException) rethrow;
      throw RouteNotFoundException('Terjadi kesalahan kalkulasi rute: $e');
    }
  }
}
