import 'package:latlong2/latlong.dart';

/// Exception yang dilempar ketika OSRM tidak dapat menemukan rute
/// atau merespons dengan code selain 'Ok'.
class RouteNotFoundException implements Exception {
  final String message;
  final String? code;

  const RouteNotFoundException(this.message, {this.code});

  @override
  String toString() => 'RouteNotFoundException: $message (code: $code)';
}

/// Model hasil kalkulasi rute dari OSRM.
class RouteModel {
  final List<LatLng> points;
  final double distanceMeters;
  final double durationSeconds;

  const RouteModel({
    required this.points,
    required this.distanceMeters,
    required this.durationSeconds,
  });

  /// Jarak dalam kilometer dengan format 1 angka di belakang koma (misal: "1.5 km").
  String get distanceKm {
    final km = distanceMeters / 1000.0;
    return '${km.toStringAsFixed(1)} km';
  }

  /// Estimasi waktu tempuh dalam menit (misal: "4 menit" atau "< 1 menit").
  String get durationMinutes {
    final minutes = (durationSeconds / 60.0).round();
    if (minutes <= 0) {
      return '< 1 menit';
    }
    return '$minutes menit';
  }

  /// Factory untuk mem-parsing response OSRM format GeoJSON.
  /// Memastikan urutan koordinat dibalik dari [lon, lat] ke LatLng(lat, lon).
  factory RouteModel.fromOsrmJson(Map<String, dynamic> json) {
    final code = json['code'] as String?;
    if (code != 'Ok') {
      final msg = json['message'] as String? ?? 'Rute tidak ditemukan antara kedua titik.';
      throw RouteNotFoundException(msg, code: code);
    }

    final routes = json['routes'] as List<dynamic>?;
    if (routes == null || routes.isEmpty) {
      throw const RouteNotFoundException('Tidak ada data rute yang tersedia.');
    }

    final firstRoute = routes.first as Map<String, dynamic>;
    final geometry = firstRoute['geometry'] as Map<String, dynamic>?;
    if (geometry == null) {
      throw const RouteNotFoundException('Geometry rute tidak ditemukan.');
    }

    final coordinates = geometry['coordinates'] as List<dynamic>?;
    if (coordinates == null || coordinates.isEmpty) {
      throw const RouteNotFoundException('Titik koordinat rute kosong.');
    }

    // OSRM menghasilkan [lon, lat], konversi ke LatLng(lat, lon) untuk flutter_map
    final points = coordinates.map<LatLng>((coord) {
      final coordList = coord as List<dynamic>;
      final lon = (coordList[0] as num).toDouble();
      final lat = (coordList[1] as num).toDouble();
      return LatLng(lat, lon);
    }).toList();

    final distance = (firstRoute['distance'] as num?)?.toDouble() ?? 0.0;
    final duration = (firstRoute['duration'] as num?)?.toDouble() ?? 0.0;

    return RouteModel(
      points: points,
      distanceMeters: distance,
      durationSeconds: duration,
    );
  }
}
