import 'package:dio/dio.dart';
import 'package:latlong2/latlong.dart';
import '../../../core/config/app_config.dart';
import '../../../core/network/api_exception.dart';
import '../../../core/network/dio_client.dart';
import '../../models/route_model.dart';

/// Remote datasource untuk mengambil rute navigasi dari OSRM (Open Source Routing Machine).
class RoutingRemoteDatasource {
  final Dio _dio;

  RoutingRemoteDatasource({Dio? dio}) : _dio = dio ?? DioClient().dio;

  /// Mengambil rute dari titik [origin] ke [destination] menggunakan OSRM.
  /// URL disusun dengan urutan longitude,latitude (sesuai format OSRM).
  Future<RouteModel> getRoute({
    required LatLng origin,
    required LatLng destination,
  }) async {
    // ⚠️ PENTING: OSRM menggunakan format {lon},{lat} (kebalikan dari lat,lng)
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
      if (e is RouteNotFoundException || e is NetworkException) {
        rethrow;
      }
      throw RouteNotFoundException('Terjadi kesalahan kalkulasi rute: $e');
    }
  }
}
