import 'package:flutter_test/flutter_test.dart';
import 'package:latlong2/latlong.dart';
import 'package:laporkita/data/models/report_model.dart';

void main() {
  group('Road Hazard Backend Integration Tests', () {
    test('ReportModel parses road damage report attributes correctly from JSON', () {
      final json = {
        'id': 'rep-road-1',
        'report_code': 'LK-2026-001',
        'reporter_id': 'user-123',
        'category_id': 'cat-1',
        'description': 'Lubang diameter 40cm kedalaman 10cm di lajur kiri',
        'latitude': -7.9525,
        'longitude': 112.6145,
        'address_text': 'Jl. Soekarno Hatta No. 45, Malang',
        'status': 'in_progress',
        'urgency_score': 85.0,
        'damage_severity': 0.85,
        'support_count': 12,
        'view_count': 150,
        'needs_manual_review': false,
        'category': {
          'id': 'cat-1',
          'name': 'Jalan Berlubang',
        },
        'created_at': '2026-09-05T08:00:00Z',
        'updated_at': '2026-09-05T08:30:00Z',
      };

      final report = ReportModel.fromJson(json);

      expect(report.id, 'rep-road-1');
      expect(report.categoryName, 'Jalan Berlubang');
      expect(report.latitude, -7.9525);
      expect(report.longitude, 112.6145);
      expect(report.addressText, 'Jl. Soekarno Hatta No. 45, Malang');
      expect(report.status, ReportStatus.inProgress);
      expect(report.damageSeverity, 0.85);
      expect(report.urgencyScore, 85.0);
    });

    test('Filter logic identifies active road damage and excludes resolved/non-road reports', () {
      final reports = [
        ReportModel(
          id: '1',
          reportCode: 'LK-1',
          reporterId: 'usr-1',
          categoryId: 'cat-1',
          latitude: -7.9525,
          longitude: 112.6145,
          status: ReportStatus.verified,
          description: 'Lubang Aspal Menganga',
          category: const {'id': '1', 'name': 'Jalan Berlubang'},
          supportCount: 0,
          viewCount: 0,
          needsManualReview: false,
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        ),
        ReportModel(
          id: '2',
          reportCode: 'LK-2',
          reporterId: 'usr-1',
          categoryId: 'cat-2',
          latitude: -7.9600,
          longitude: 112.6200,
          status: ReportStatus.verified,
          description: 'Sampah Menumpuk',
          category: const {'id': '2', 'name': 'Kebersihan & Sampah'},
          supportCount: 0,
          viewCount: 0,
          needsManualReview: false,
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        ),
        ReportModel(
          id: '3',
          reportCode: 'LK-3',
          reporterId: 'usr-1',
          categoryId: 'cat-1',
          latitude: -7.9700,
          longitude: 112.6300,
          status: ReportStatus.completed, // Inactive/resolved
          description: 'Jalan Rusak Sudah Diperbaiki',
          category: const {'id': '1', 'name': 'Jalan Berlubang'},
          supportCount: 0,
          viewCount: 0,
          needsManualReview: false,
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        ),
        ReportModel(
          id: '4',
          reportCode: 'LK-4',
          reporterId: 'usr-1',
          categoryId: 'cat-3',
          latitude: -7.9400,
          longitude: 112.6100,
          status: ReportStatus.inProgress,
          description: 'Aspal Retak Parah',
          category: const {'id': '3', 'name': 'Kerusakan Jalan'},
          supportCount: 0,
          viewCount: 0,
          needsManualReview: false,
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        ),
      ];

      // Filtering criteria matching route_picker_screen.dart:
      final roadHazards = reports.where((r) {
        if (r.status == ReportStatus.completed ||
            r.status == ReportStatus.resolved ||
            r.status == ReportStatus.rejected) {
          return false;
        }
        if (r.latitude == 0.0 && r.longitude == 0.0) return false;

        final cat = r.categoryName.toLowerCase();
        final desc = (r.description ?? '').toLowerCase();
        return cat.contains('jalan') ||
            cat.contains('lubang') ||
            cat.contains('aspal') ||
            cat.contains('rusak') ||
            desc.contains('lubang') ||
            desc.contains('jalan rusak');
      }).toList();

      expect(roadHazards.length, 2);
      expect(roadHazards.map((r) => r.id).toList(), ['1', '4']);
    });

    test('Distance calculation correctly identifies proximity threshold (<= 50m)', () {
      const distanceCalc = Distance();
      const userPosition = LatLng(-7.952500, 112.614500);
      const hazardNear = LatLng(-7.952600, 112.614500); // ~11m
      const hazardFar = LatLng(-7.960000, 112.620000);  // ~1000m

      final distNear = distanceCalc.as(LengthUnit.Meter, userPosition, hazardNear);
      final distFar = distanceCalc.as(LengthUnit.Meter, userPosition, hazardFar);

      expect(distNear, lessThanOrEqualTo(50));
      expect(distFar, greaterThan(50));
    });

    test('Severity label formatting accurately maps backend severity & urgency', () {
      String formatSeverity(ReportModel? report) {
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

      final heavyReport = ReportModel(
        id: 'h1',
        reportCode: 'LK-H1',
        reporterId: 'u1',
        categoryId: 'c1',
        status: ReportStatus.verified,
        latitude: -7.95,
        longitude: 112.61,
        damageSeverity: 0.85,
        supportCount: 0,
        viewCount: 0,
        needsManualReview: false,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );
      final mediumReport = ReportModel(
        id: 'm1',
        reportCode: 'LK-M1',
        reporterId: 'u1',
        categoryId: 'c1',
        status: ReportStatus.verified,
        latitude: -7.95,
        longitude: 112.61,
        damageSeverity: 0.5,
        supportCount: 0,
        viewCount: 0,
        needsManualReview: false,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );
      final lightReport = ReportModel(
        id: 'l1',
        reportCode: 'LK-L1',
        reporterId: 'u1',
        categoryId: 'c1',
        status: ReportStatus.verified,
        latitude: -7.95,
        longitude: 112.61,
        damageSeverity: 0.2,
        supportCount: 0,
        viewCount: 0,
        needsManualReview: false,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      expect(formatSeverity(heavyReport), 'Berat');
      expect(formatSeverity(mediumReport), 'Sedang');
      expect(formatSeverity(lightReport), 'Ringan');
    });
  });
}
