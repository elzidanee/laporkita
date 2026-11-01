import 'package:flutter_test/flutter_test.dart';
import 'package:laporkita/data/models/report_model.dart';
import 'package:laporkita/data/repositories/report_repository.dart';
import 'package:laporkita/data/datasources/remote/report_remote_datasource.dart';
import 'package:laporkita/data/models/agency_model.dart';
import 'package:laporkita/presentation/command_center/report_management/admin_assign_report_screen.dart';
import 'package:laporkita/presentation/citizen/camera/new_report_form_screen.dart';
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

    test('ReportModel.fromJson extracts real photo from media when photo_url is null', () {
      final json = {
        'id': 'real-db-1',
        'report_code': '#LP-2026-000002',
        'status': 'in_progress',
        'photo_url': null,
        'media': [
          {
            'id': 'm-1',
            'report_id': 'real-db-1',
            'type': 'initial_photo',
            'url': 'https://yfiuannpkwwutbasxgxb.supabase.co/storage/v1/object/public/laporkita-reports/reports/123.jpg',
            'created_at': '2026-09-05T08:18:08.807Z',
          }
        ],
      };

      final model = ReportModel.fromJson(json);
      expect(model.directPhotoUrl, equals('https://yfiuannpkwwutbasxgxb.supabase.co/storage/v1/object/public/laporkita-reports/reports/123.jpg'));
      expect(model.photoUrl, equals('https://yfiuannpkwwutbasxgxb.supabase.co/storage/v1/object/public/laporkita-reports/reports/123.jpg'));
    });

    test('ReportStatusHistoryModel.fromJson parses backend status and changed_by fields', () {
      final json = {
        'id': 'hist-1',
        'report_id': 'real-db-1',
        'status': 'verified',
        'note': 'Foto & GPS valid',
        'changed_by': 'admin-uuid-1',
        'created_at': '2026-09-05T08:18:08.807Z',
        'changer': {
          'full_name': 'Admin LaporKita Kota Malang',
        }
      };

      final history = ReportStatusHistoryModel.fromJson(json);
      expect(history.targetStatus, equals(ReportStatus.verified));
      expect(history.note, equals('Foto & GPS valid'));
      expect(history.actorId, equals('admin-uuid-1'));
      expect(history.actorName, equals('Admin LaporKita Kota Malang'));
    });

    test('MM-05: AdminAssignReportScreen resolves OPD name to UUID and ReportRemoteDatasource includes assigned_agency_id in payload', () {
      final agencies = [
        const AgencyModel(
          id: 'a2000000-0000-4000-8000-000000000002',
          name: 'Dinas Perhubungan (Dishub) Kota Malang',
          type: 'dishub',
        ),
      ];
      final resolvedUuid = AdminAssignReportScreen.resolveAgencyId(
        'Dinas Perhubungan (Dishub) Kota Malang',
        agencies,
      );
      expect(resolvedUuid, equals('a2000000-0000-4000-8000-000000000002'));

      final fallbackUuid = AdminAssignReportScreen.resolveAgencyId(
        'Dinas PUPR (DPUPR)',
        const [],
      );
      expect(fallbackUuid, equals('a1000000-0000-4000-8000-000000000001'));

      final payload = ReportRemoteDatasource.buildStatusTransitionPayload(
        'assigned',
        notes: 'Penugasan ke Dishub',
        assignedAgencyId: resolvedUuid,
      );
      expect(payload['status'], equals('assigned'));
      expect(payload['note'], equals('Penugasan ke Dishub'));
      expect(payload['assigned_agency_id'], equals('a2000000-0000-4000-8000-000000000002'));
    });

    test('MM-07: NewReportFormScreen.defaultCategories contains only the 5 canonical seed category UUIDs', () {
      final cats = NewReportFormScreen.defaultCategories;
      expect(cats, hasLength(5));
      final uuidRegex = RegExp(
        r'^[0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{12}$',
      );
      for (final c in cats) {
        expect(uuidRegex.hasMatch(c.id), isTrue, reason: 'Invalid category UUID: ${c.id}');
      }
      expect(
        cats.map((c) => c.name).toList(),
        equals(const [
          'Jalan Berlubang',
          'Lampu Jalan',
          'Rambu Lalu Lintas',
          'Trotoar',
          'Drainase',
        ]),
      );
    });
  });
}
