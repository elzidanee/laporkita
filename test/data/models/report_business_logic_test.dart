import 'package:flutter_test/flutter_test.dart';
import 'package:laporkita/data/models/report_model.dart';
import 'package:laporkita/data/repositories/report_repository.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  group('Report Business Logic & State Consistency Tests', () {
    test('ReportModel.copyWith successfully modifies target fields while preserving unmodified ones', () {
      final initial = ReportModel(
        id: 'rep-101',
        reportCode: 'LP_2026_00101',
        reporterId: 'user-1',
        categoryId: 'cat-roads',
        status: ReportStatus.inProgress,
        latitude: -7.9827,
        longitude: 112.6304,
        supportCount: 5,
        viewCount: 20,
        needsManualReview: false,
        createdAt: DateTime(2026, 3, 1),
        updatedAt: DateTime(2026, 3, 2),
      );

      final modified = initial.copyWith(
        supportCount: 6,
        status: ReportStatus.completed,
      );

      expect(modified.id, equals('rep-101'));
      expect(modified.reportCode, equals('LP_2026_00101'));
      expect(modified.supportCount, equals(6));
      expect(modified.status, equals(ReportStatus.completed));
      expect(modified.viewCount, equals(20));
      expect(modified.latitude, equals(-7.9827));
      expect(modified.longitude, equals(112.6304));
    });

    test('ReportStatus fromString supports all state machine values including resolved & disputed', () {
      expect(ReportStatus.fromString('pending_verification'), equals(ReportStatus.pendingVerification));
      expect(ReportStatus.fromString('in_progress'), equals(ReportStatus.inProgress));
      expect(ReportStatus.fromString('completed'), equals(ReportStatus.completed));
      expect(ReportStatus.fromString('resolved'), equals(ReportStatus.resolved));
      expect(ReportStatus.fromString('disputed'), equals(ReportStatus.disputed));
      expect(ReportStatus.fromString('rejected'), equals(ReportStatus.rejected));
    });

    test('validateReport correctly sets status to resolved when isApproved is true', () async {
      final repository = ReportRepository();
      await repository.validateReport('mock-1', isApproved: true, feedback: 'Selesai rapi');

      final report = await repository.getReportById('mock-1');
      expect(report.status, equals(ReportStatus.resolved));
      expect(report.statusHistory.any((h) => h.note?.contains('selesai') == true), isTrue);
    });

    test('validateReport correctly sets status to disputed when isApproved is false', () async {
      final repository = ReportRepository();
      await repository.validateReport('mock-2', isApproved: false, feedback: 'Aspal masih berlubang');

      final report = await repository.getReportById('mock-2');
      expect(report.status, equals(ReportStatus.disputed));
      expect(report.statusHistory.any((h) => h.note?.contains('belum sesuai') == true), isTrue);
    });
  });
}
