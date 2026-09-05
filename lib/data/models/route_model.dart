import 'package:flutter/material.dart';
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

/// Langkah navigasi per manuver dari OSRM (turn-by-turn).
class RouteStep {
  final String name;
  final double distanceMeters;
  final double durationSeconds;
  final String maneuverType;
  final String? maneuverModifier;

  const RouteStep({
    required this.name,
    required this.distanceMeters,
    required this.durationSeconds,
    required this.maneuverType,
    this.maneuverModifier,
  });

  /// Ikon manuver yang sesuai
  IconData get maneuverIcon {
    final mod = (maneuverModifier ?? '').toLowerCase();
    final type = maneuverType.toLowerCase();

    if (type == 'arrive') return Icons.flag_rounded;
    if (type == 'depart') return Icons.navigation_rounded;

    if (mod.contains('left')) {
      return mod.contains('slight')
          ? Icons.turn_slight_left_rounded
          : Icons.turn_left_rounded;
    }
    if (mod.contains('right')) {
      return mod.contains('slight')
          ? Icons.turn_slight_right_rounded
          : Icons.turn_right_rounded;
    }
    if (mod.contains('uturn')) return Icons.u_turn_left_rounded;

    return Icons.straight_rounded;
  }

  /// Instruksi tekstual ramah pengguna dalam Bahasa Indonesia
  String get instructionText {
    final street = name.isEmpty ? 'jalan berikutnya' : name;
    final mod = (maneuverModifier ?? '').toLowerCase();
    final type = maneuverType.toLowerCase();

    if (type == 'arrive') return 'Tiba di tujuan';
    if (type == 'depart') return 'Mulai perjalanan ke arah $street';

    if (mod == 'left') return 'Belok kiri ke $street';
    if (mod == 'slight left') return 'Serong kiri ke $street';
    if (mod == 'sharp left') return 'Belok tajam ke kiri ke $street';
    if (mod == 'right') return 'Belok kanan ke $street';
    if (mod == 'slight right') return 'Serong kanan ke $street';
    if (mod == 'sharp right') return 'Belok tajam ke kanan ke $street';
    if (mod == 'straight') return 'Lurus terus di $street';
    if (mod.contains('uturn')) return 'Putar balik di $street';

    return 'Lanjut di $street';
  }

  factory RouteStep.fromJson(Map<String, dynamic> json) {
    final maneuver = json['maneuver'] as Map<String, dynamic>? ?? {};
    return RouteStep(
      name: (json['name'] as String? ?? '').trim(),
      distanceMeters: (json['distance'] as num?)?.toDouble() ?? 0.0,
      durationSeconds: (json['duration'] as num?)?.toDouble() ?? 0.0,
      maneuverType: maneuver['type'] as String? ?? 'turn',
      maneuverModifier: maneuver['modifier'] as String?,
    );
  }
}

/// Model hasil kalkulasi rute dari OSRM.
class RouteModel {
  final List<LatLng> points;
  final double distanceMeters;
  final double durationSeconds;
  final List<RouteStep> steps;
  final String summary;

  const RouteModel({
    required this.points,
    required this.distanceMeters,
    required this.durationSeconds,
    this.steps = const [],
    this.summary = '',
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

  /// Format jam estimasi waktu tiba (ETA), misal: "09.53"
  String get etaFormatted {
    final arrival = DateTime.now().add(Duration(seconds: durationSeconds.round()));
    final hour = arrival.hour.toString().padLeft(2, '0');
    final minute = arrival.minute.toString().padLeft(2, '0');
    return '$hour.$minute';
  }

  /// Parsing satu objek rute dalam array `routes`
  factory RouteModel.fromRouteJson(Map<String, dynamic> routeJson) {
    final geometry = routeJson['geometry'] as Map<String, dynamic>?;
    if (geometry == null) {
      throw const RouteNotFoundException('Geometry rute tidak ditemukan.');
    }

    final coordinates = geometry['coordinates'] as List<dynamic>?;
    if (coordinates == null || coordinates.isEmpty) {
      throw const RouteNotFoundException('Titik koordinat rute kosong.');
    }

    final points = coordinates.map<LatLng>((coord) {
      final coordList = coord as List<dynamic>;
      final lon = (coordList[0] as num).toDouble();
      final lat = (coordList[1] as num).toDouble();
      return LatLng(lat, lon);
    }).toList();

    final distance = (routeJson['distance'] as num?)?.toDouble() ?? 0.0;
    final duration = (routeJson['duration'] as num?)?.toDouble() ?? 0.0;
    final summary = (routeJson['summary'] as String? ?? '').trim();

    final legs = routeJson['legs'] as List<dynamic>? ?? [];
    final stepsList = <RouteStep>[];
    for (final leg in legs) {
      if (leg is Map<String, dynamic> && leg['steps'] is List) {
        for (final step in leg['steps'] as List) {
          if (step is Map<String, dynamic>) {
            stepsList.add(RouteStep.fromJson(step));
          }
        }
      }
    }

    return RouteModel(
      points: points,
      distanceMeters: distance,
      durationSeconds: duration,
      steps: stepsList,
      summary: summary,
    );
  }

  /// Factory untuk mem-parsing response OSRM format GeoJSON (mengambil rute pertama).
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

    return RouteModel.fromRouteJson(routes.first as Map<String, dynamic>);
  }

  /// Factory untuk mem-parsing SEMUA rute (termasuk rute alternatif) dari response OSRM.
  static List<RouteModel> fromOsrmJsonList(Map<String, dynamic> json) {
    final code = json['code'] as String?;
    if (code != 'Ok') {
      final msg = json['message'] as String? ?? 'Rute tidak ditemukan antara kedua titik.';
      throw RouteNotFoundException(msg, code: code);
    }

    final routes = json['routes'] as List<dynamic>?;
    if (routes == null || routes.isEmpty) {
      throw const RouteNotFoundException('Tidak ada data rute yang tersedia.');
    }

    return routes
        .map((r) => RouteModel.fromRouteJson(r as Map<String, dynamic>))
        .toList();
  }
}
