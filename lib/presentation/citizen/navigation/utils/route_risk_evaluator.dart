import 'package:geolocator/geolocator.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../data/models/report_model.dart';
import '../../../../data/models/route_model.dart';
import '../widgets/navigation_route_sheet.dart';

/// Helper terisolasi untuk evaluasi resiko bahaya jalan di sepanjang rute.
/// Menggunakan optimasi bounding-box pre-filtering dan point-stride sampling
/// agar kalkulasi instan (<1ms) dan tidak membebani UI thread.
class RouteRiskEvaluator {
  RouteRiskEvaluator._();

  /// Menghitung jumlah laporan jalan rusak di dalam koridor [corridorMeters] dari rute
  static int countHazardsNearRoute(
    RouteModel route,
    List<ReportModel> hazards, {
    double corridorMeters = 150.0,
  }) {
    if (route.points.isEmpty || hazards.isEmpty) return 0;

    // 1. Fast bounding-box check
    double minLat = route.points.first.latitude;
    double maxLat = route.points.first.latitude;
    double minLng = route.points.first.longitude;
    double maxLng = route.points.first.longitude;

    for (final p in route.points) {
      if (p.latitude < minLat) minLat = p.latitude;
      if (p.latitude > maxLat) maxLat = p.latitude;
      if (p.longitude < minLng) minLng = p.longitude;
      if (p.longitude > maxLng) maxLng = p.longitude;
    }

    // Perlebar bounding box ~200 meter (~0.002 derajat)
    const latMargin = 0.002;
    const lngMargin = 0.002;
    minLat -= latMargin;
    maxLat += latMargin;
    minLng -= lngMargin;
    maxLng += lngMargin;

    // Filter kandidat bahaya yang berada dalam bounding box saja
    final candidates = hazards.where((h) {
      return h.latitude >= minLat &&
          h.latitude <= maxLat &&
          h.longitude >= minLng &&
          h.longitude <= maxLng;
    }).toList();

    if (candidates.isEmpty) return 0;

    // 2. Spatial stride sampling: lewati titik polyline yang berjarak sangat rapat
    int count = 0;
    for (final hazard in candidates) {
      bool isNear = false;
      final hLat = hazard.latitude;
      final hLng = hazard.longitude;

      // Sample titik setiap 20-30 meter atau gunakan seluruh titik jika rute pendek
      final step = (route.points.length > 300) ? 2 : 1;
      for (int i = 0; i < route.points.length; i += step) {
        final pt = route.points[i];
        final dist = Geolocator.distanceBetween(
          pt.latitude,
          pt.longitude,
          hLat,
          hLng,
        );
        if (dist <= corridorMeters) {
          isNear = true;
          break;
        }
      }
      if (isNear) {
        count++;
      }
    }

    return count;
  }

  /// Menghasilkan daftar RouteOptionItem yang sudah dievaluasi resikonya
  static List<RouteOptionItem> buildRouteOptionItems({
    required List<RouteModel> routes,
    required List<ReportModel> roadHazards,
  }) {
    if (routes.isEmpty) return NavigationRouteSheet.defaultRoutes;

    return List.generate(routes.length, (i) {
      final route = routes[i];
      final isFirst = i == 0;
      final warnings = countHazardsNearRoute(route, roadHazards);
      final riskColor = warnings >= 2
          ? AppColors.statusDanger
          : (warnings == 0 ? AppColors.greenPrimary : AppColors.statusPending);

      return RouteOptionItem(
        index: i,
        title: isFirst ? 'Rute Tercepat' : 'Rute Alternatif $i',
        riskTitle: isFirst
            ? (warnings > 0 ? 'Rute awal ($warnings peringatan)' : 'Rute awal (Aman)')
            : (warnings == 0
                ? 'Rute Alternatif $i (lebih aman)'
                : 'Hindari Alternatif $i ($warnings resiko)'),
        durationKm: '${route.durationMinutes} - ${route.distanceKm}',
        warningCountText: '$warnings peringatan',
        riskColor: riskColor,
        warnings: warnings,
      );
    });
  }

  /// Format tingkat keparahan laporan
  static String formatSeverity(ReportModel? report) {
    if (report == null) return 'Sedang';
    if (report.damageSeverity != null) {
      if (report.damageSeverity! >= 0.7) return 'Berat';
      if (report.damageSeverity! >= 0.4) return 'Sedang';
      return 'Ringan';
    }
    if (report.urgencyScore != null) {
      if (report.urgencyScore! >= 4.0) return 'Berat';
      if (report.urgencyScore! >= 3.0) return 'Sedang';
      return 'Ringan';
    }
    return 'Sedang';
  }
}
