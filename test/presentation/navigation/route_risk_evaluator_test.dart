import 'package:flutter_test/flutter_test.dart';
import 'package:latlong2/latlong.dart';
import 'package:laporkita/core/theme/app_colors.dart';
import 'package:laporkita/data/models/report_model.dart';
import 'package:laporkita/data/models/route_model.dart';
import 'package:laporkita/presentation/citizen/navigation/utils/route_risk_evaluator.dart';

void main() {
  group('RouteRiskEvaluator Unit Tests', () {
    final sampleRoute = RouteModel(
      points: const [
        LatLng(-7.9500, 112.6100),
        LatLng(-7.9510, 112.6120),
        LatLng(-7.9520, 112.6140),
        LatLng(-7.9530, 112.6160),
      ],
      distanceMeters: 1000.0,
      durationSeconds: 120.0,
      summary: 'Jl. Utama',
    );

    final hazardNear = ReportModel(
      id: 'h-near',
      reportCode: 'LK-001',
      reporterId: 'u1',
      categoryId: 'c1',
      status: ReportStatus.verified,
      latitude: -7.9511, // ~15 meter dari titik kedua
      longitude: 112.6121,
      damageSeverity: 0.8,
      supportCount: 0,
      viewCount: 0,
      needsManualReview: false,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );

    final hazardFar = ReportModel(
      id: 'h-far',
      reportCode: 'LK-002',
      reporterId: 'u1',
      categoryId: 'c1',
      status: ReportStatus.verified,
      latitude: -7.9800, // ~3 km jauhnya
      longitude: 112.6500,
      damageSeverity: 0.2,
      supportCount: 0,
      viewCount: 0,
      needsManualReview: false,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );

    test('countHazardsNearRoute returns 0 when hazards list is empty', () {
      final count = RouteRiskEvaluator.countHazardsNearRoute(sampleRoute, []);
      expect(count, 0);
    });

    test('countHazardsNearRoute correctly filters hazards outside corridor and counts hazards inside', () {
      final count = RouteRiskEvaluator.countHazardsNearRoute(
        sampleRoute,
        [hazardNear, hazardFar],
      );
      expect(count, 1);
    });

    test('buildRouteOptionItems generates evaluated routes with correct risk colors and counts', () {
      final altRoute = RouteModel(
        points: const [
          LatLng(-7.9500, 112.6100),
          LatLng(-7.9490, 112.6130),
          LatLng(-7.9530, 112.6160),
        ],
        distanceMeters: 1100.0,
        durationSeconds: 140.0,
        summary: 'Jl. Alternatif Aman',
      );

      final items = RouteRiskEvaluator.buildRouteOptionItems(
        routes: [sampleRoute, altRoute],
        roadHazards: [hazardNear],
      );

      expect(items.length, 2);
      // Rute 1 (dekat bahaya)
      expect(items[0].warnings, 1);
      expect(items[0].warningCountText, '1 peringatan');
      expect(items[0].riskColor, AppColors.statusPending);

      // Rute 2 (jauh dari bahaya)
      expect(items[1].warnings, 0);
      expect(items[1].warningCountText, '0 peringatan');
      expect(items[1].riskColor, AppColors.greenPrimary);
      expect(items[1].riskTitle, contains('lebih aman'));
    });

    test('formatSeverity maps damage severity and urgency scores accurately', () {
      expect(RouteRiskEvaluator.formatSeverity(null), 'Sedang');
      expect(RouteRiskEvaluator.formatSeverity(hazardNear), 'Berat');
      expect(RouteRiskEvaluator.formatSeverity(hazardFar), 'Ringan');
    });
  });
}
