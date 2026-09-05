import 'package:dio/dio.dart';
import 'package:latlong2/latlong.dart';
import '../../../core/config/app_config.dart';
import '../../../core/network/api_exception.dart';
import '../../../core/network/dio_client.dart';
import '../../models/route_model.dart';

class _CachedRoute {
  final RouteModel route;
  final DateTime fetchedAt;
  _CachedRoute(this.route) : fetchedAt = DateTime.now();
  bool get isExpired =>
      DateTime.now().difference(fetchedAt) > const Duration(minutes: 5);
}

/// Remote datasource untuk OSRM dengan cache in-memory + deduplikasi request.
///
/// - Cache 5 menit per pasangan origin->destination (key dibulatkan 5 desimal ~1m)
/// - Deduplikasi: request concurrent yang sama share Future yang sama
class RoutingRemoteDatasource {
  final Dio _dio;

  // Static agar cache survive antar instance Repository
  static final Map<String, _CachedRoute> _cache = {};
  static final Map<String, Future<RouteModel>> _inFlight = {};

  RoutingRemoteDatasource({Dio? dio}) : _dio = dio ?? DioClient().dio;

  static String _key(LatLng o, LatLng d) =>
      '${o.latitude.toStringAsFixed(5)},${o.longitude.toStringAsFixed(5)}'
      '->${d.latitude.toStringAsFixed(5)},${d.longitude.toStringAsFixed(5)}';

  /// Bersihkan cache (mis. saat user ganti kota atau pull-to-refresh)
  static void clearCache() {
    _cache.clear();
  }

  Future<RouteModel> getRoute({
    required LatLng origin,
    required LatLng destination,
  }) async {
    final key = _key(origin, destination);

    // 1. Hit cache
    final cached = _cache[key];
    if (cached != null && !cached.isExpired) return cached.route;
    if (cached != null && cached.isExpired) _cache.remove(key);

    // 2. Deduplikasi: jika ada request sama yang sedang berjalan, ikut Future itu
    final inflight = _inFlight[key];
    if (inflight != null) return inflight;

    final future = _fetchRoute(origin, destination);
    _inFlight[key] = future;

    try {
      final route = await future;
      _cache[key] = _CachedRoute(route);
      return route;
    } finally {
      _inFlight.remove(key);
    }
  }

  Future<RouteModel> _fetchRoute(LatLng origin, LatLng destination) async {
    final url =
        '${AppConfig.osrmBaseUrl}/route/v1/driving/'
        '${origin.longitude},${origin.latitude};'
        '${destination.longitude},${destination.latitude}'
        '?overview=full&geometries=geojson&steps=true';

    try {
      final response = await _dio.get(url);

      if (response.data is Map<String, dynamic>) {
        return RouteModel.fromOsrmJson(response.data as Map<String, dynamic>);
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
        final code = data['code'] as String?;
        final message = data['message'] as String? ?? 'Gagal mendapatkan rute.';
        throw RouteNotFoundException(message, code: code);
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
