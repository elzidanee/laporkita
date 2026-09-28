import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:laporkita/core/network/api_response.dart';
import 'package:laporkita/data/models/report_model.dart';
import 'package:laporkita/data/repositories/report_repository.dart';
import 'package:laporkita/presentation/command_center/report_management/government_reports_screen.dart';

class FakeReportRepository extends Fake implements ReportRepository {
  @override
  Future<ApiResponse<List<ReportModel>>> getReports({
    int limit = 20,
    String? cursor,
    String? status,
    String? categoryId,
    String? reporterId,
    String sortBy = 'newest',
  }) async {
    return const ApiResponse<List<ReportModel>>(
      success: true,
      data: [],
    );
  }

  @override
  void cacheReports(Iterable<ReportModel> list) {}

  @override
  void cacheReport(ReportModel report) {}
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  Widget buildReportsTestWidget({bool isEmbedded = false}) {
    final fakeRepo = FakeReportRepository();

    return MultiRepositoryProvider(
      providers: [
        RepositoryProvider<ReportRepository>.value(value: fakeRepo),
      ],
      child: MaterialApp(
        home: Scaffold(
          body: GovernmentReportsScreen(isEmbedded: isEmbedded),
        ),
      ),
    );
  }

  group('Figma Node 622:219 Government Reports Screen Tests', () {
    testWidgets('Renders Top Bar, Search, Two Filter Rows & Report Cards',
        (tester) async {
      tester.view.physicalSize = const Size(412, 1200);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      await tester.pumpWidget(buildReportsTestWidget(isEmbedded: false));
      await tester.pumpAndSettle();

      // 1. App Bar
      expect(find.text('Laporan'), findsOneWidget);

      // 2. Search Field
      expect(
          find.text('Cari ID, judul, lokasi, atau pelapor...'), findsOneWidget);

      // 3. Filter Row 1 (Blue)
      expect(find.text('Filter'), findsOneWidget);
      expect(find.text('Semua Status'), findsOneWidget);
      expect(find.text('Semua OPD'), findsOneWidget);
      expect(find.byIcon(Icons.tune_rounded), findsOneWidget);

      // 4. Filter Row 2 (Gray)
      expect(find.text('Semua Kategori'), findsOneWidget);
      expect(find.text('OPD'), findsOneWidget);
      expect(find.text('Prioritas'), findsOneWidget);

      // 5. Report Cards from Figma 622:219
      expect(find.text('Jalan Rusak'), findsWidgets);
      expect(find.text('Jl. Ahmad Yani no. 15'), findsWidgets);
      expect(find.text('#LP_2026_0024487'), findsWidgets);
      expect(find.text('Prioritas Tinggi'), findsWidgets);
      expect(find.text('Dinas PUPR'), findsWidgets);

      expect(find.text('Halte rusak'), findsWidgets);
      expect(find.text('Jl. soekarno hatta no.20 A'), findsWidgets);
      expect(find.text('#LP_2026_0038217'), findsWidgets);
      expect(find.text('Sedang'), findsWidgets);
      expect(find.text('Dinas Perhubungan'), findsWidgets);
    });

    testWidgets('Real-time search filters report list', (tester) async {
      tester.view.physicalSize = const Size(412, 1200);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      await tester.pumpWidget(buildReportsTestWidget(isEmbedded: false));
      await tester.pumpAndSettle();

      // Initially shows Jalan Rusak and Halte rusak
      expect(find.text('Jalan Rusak'), findsWidgets);
      expect(find.text('Halte rusak'), findsWidgets);

      // Enter search query "Halte"
      await tester.enterText(find.byType(TextField), 'Halte');
      await tester.pumpAndSettle();

      // Only halte reports remain
      expect(find.text('Halte rusak'), findsWidgets);
      expect(find.text('Jalan Rusak'), findsNothing);

      // Clear search query
      await tester.enterText(find.byType(TextField), '');
      await tester.pumpAndSettle();
      expect(find.text('Jalan Rusak'), findsWidgets);
    });

    testWidgets('Status dropdown filter changes selection and updates list',
        (tester) async {
      tester.view.physicalSize = const Size(412, 1200);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      await tester.pumpWidget(buildReportsTestWidget(isEmbedded: true));
      await tester.pumpAndSettle();

      // Open status filter popup
      await tester.tap(find.text('Semua Status'));
      await tester.pumpAndSettle();

      // Select 'Sedang Diproses'
      expect(find.text('Sedang Diproses'), findsWidgets);
      await tester.tap(find.text('Sedang Diproses').last);
      await tester.pumpAndSettle();

      // Verify pill updated
      expect(find.text('Sedang Diproses'), findsOneWidget);
    });

    testWidgets(
        'Backend priority status is correctly parsed from statusHistory note, damageSeverity, and urgencyScore',
        (tester) async {
      tester.view.physicalSize = const Size(412, 1200);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      final customRepo = FakeBackendReportRepository(reports: [
        ReportModel(
          id: 'rep-real-1',
          reportCode: 'LP_2026_000005',
          reporterId: 'usr-real',
          categoryId: 'cat-1',
          status: ReportStatus.assigned,
          latitude: -7.97813,
          longitude: 112.656992,
          addressText: 'Jl. Danau Ranau II No.20, Sawojajar, Kota Malang',
          description: 'Jalan berlubang besar',
          supportCount: 1,
          viewCount: 10,
          rawAiConfidenceScore: 0.88,
          damageSeverity: 0.75,
          urgencyScore: 2.07,
          needsManualReview: false,
          createdAt: DateTime.now().subtract(const Duration(hours: 3)),
          updatedAt: DateTime.now(),
          category: const {'name': 'Jalan Berlubang'},
          assignedAgency: const {
            'name':
                'Dinas Pekerjaan Umum, Penataan Ruang, Perumahan dan Kawasan Permukiman (DPUPRPKP) Kota Malang',
            'type': 'dpupr',
          },
          statusHistory: [
            ReportStatusHistoryModel(
              id: 'hist-1',
              reportId: 'rep-real-1',
              targetStatus: ReportStatus.assigned,
              note:
                  'Penugasan laporan ke Dinas PUPR (DPUPR) (Prioritas: Tinggi | Petugas: Andi Pratama)',
              createdAt: DateTime.now(),
            ),
          ],
        ),
        ReportModel(
          id: 'rep-real-2',
          reportCode: 'LP_2026_000006',
          reporterId: 'usr-real',
          categoryId: 'cat-2',
          status: ReportStatus.pendingVerification,
          latitude: -7.98,
          longitude: 112.63,
          addressText: 'Jl. Ijen No. 12, Klojen, Kota Malang',
          description: 'Trotoar amblas',
          supportCount: 2,
          viewCount: 12,
          damageSeverity: 0.45,
          urgencyScore: 3.5,
          needsManualReview: true,
          createdAt: DateTime.now().subtract(const Duration(hours: 1)),
          updatedAt: DateTime.now(),
          category: const {'name': 'Trotoar Rusak'},
          assignedAgency: const {
            'name': 'Dinas Pekerjaan Umum Kota Malang',
            'type': 'dpupr',
          },
        ),
      ]);

      await tester.pumpWidget(
        MultiRepositoryProvider(
          providers: [
            RepositoryProvider<ReportRepository>.value(value: customRepo),
          ],
          child: const MaterialApp(
            home: Scaffold(
              body: GovernmentReportsScreen(isEmbedded: false),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Verify real backend report values (appears in both thumbnail geotag and card body)
      expect(find.text('#LP_2026_000005'), findsWidgets);
      expect(find.text('Jalan Berlubang'), findsWidgets);
      // Priority badge parsed from note & damage_severity (0.75)
      expect(find.text('Prioritas Tinggi'), findsOneWidget);
      // Mapped short OPD name from DPUPRPKP
      expect(find.text('Dinas PUPR'), findsNWidgets(2));

      // Second report with needsManualReview: true -> 'Perlu Penanganan'
      expect(find.text('#LP_2026_000006'), findsWidgets);
      expect(find.text('Perlu Penanganan'), findsOneWidget);

      // Test Priority filter dropdown: select 'Prioritas Tinggi'
      await tester.tap(find.text('Prioritas'));
      await tester.pumpAndSettle();

      expect(find.text('Prioritas Tinggi'), findsWidgets);
      await tester.tap(find.text('Prioritas Tinggi').last);
      await tester.pumpAndSettle();

      // Now only the high-priority report is visible
      expect(find.text('#LP_2026_000005'), findsWidgets);
      expect(find.text('#LP_2026_000006'), findsNothing);
    });
  });
}

class FakeBackendReportRepository extends Fake implements ReportRepository {
  final List<ReportModel> reports;
  FakeBackendReportRepository({required this.reports});

  @override
  Future<ApiResponse<List<ReportModel>>> getReports({
    int limit = 20,
    String? cursor,
    String? status,
    String? categoryId,
    String? reporterId,
    String sortBy = 'newest',
  }) async {
    return ApiResponse<List<ReportModel>>(
      success: true,
      data: reports,
    );
  }

  @override
  void cacheReports(Iterable<ReportModel> list) {}

  @override
  void cacheReport(ReportModel report) {}
}

