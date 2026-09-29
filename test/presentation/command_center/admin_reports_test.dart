import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:laporkita/core/network/api_response.dart';
import 'package:laporkita/data/models/category_model.dart';
import 'package:laporkita/data/models/report_model.dart';
import 'package:laporkita/data/repositories/category_repository.dart';
import 'package:laporkita/data/repositories/report_repository.dart';
import 'package:laporkita/presentation/command_center/report_management/admin_reports_screen.dart';

class FakeReportRepository extends Fake implements ReportRepository {
  final List<ReportModel> mockReports;

  FakeReportRepository([this.mockReports = const []]);

  @override
  Future<ApiResponse<List<ReportModel>>> getReports({
    int limit = 20,
    String? cursor,
    String? status,
    String? categoryId,
    String? reporterId,
    bool? needsManualReview,
    String sortBy = 'newest',
  }) async {
    return ApiResponse<List<ReportModel>>(
      success: true,
      data: mockReports,
    );
  }

  @override
  void cacheReports(Iterable<ReportModel> list) {}

  @override
  void cacheReport(ReportModel report) {}
}

class FakeCategoryRepository extends Fake implements CategoryRepository {
  @override
  Future<List<CategoryModel>> getCategories() async => [];
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  final List<ReportModel> testReports = [
    ReportModel(
      id: 'rep-admin-1',
      reportCode: 'LP_2026_001001',
      reporterId: 'user-1',
      categoryId: 'cat-1',
      status: ReportStatus.pendingVerification,
      latitude: -7.982,
      longitude: 112.631,
      addressText: 'Jl. Ijen No. 12',
      description: 'Aspal berlubang besar',
      supportCount: 25,
      viewCount: 150,
      urgencyScore: 8.5,
      damageSeverity: 0.85,
      rawAiConfidenceScore: 0.95,
      needsManualReview: false,
      createdAt: DateTime(2026, 6, 1, 10, 0),
      updatedAt: DateTime(2026, 6, 1, 10, 0),
      category: const {'id': 'cat-1', 'name': 'Jalan Rusak'},
      assignedAgency: const {'id': 'agency-1', 'name': 'Dinas PUPR'},
    ),
    ReportModel(
      id: 'rep-admin-2',
      reportCode: 'LP_2026_001002',
      reporterId: 'user-2',
      categoryId: 'cat-2',
      status: ReportStatus.verified,
      latitude: -7.985,
      longitude: 112.628,
      addressText: 'Jl. Soekarno Hatta',
      description: 'Lampu PJU mati total di malam hari',
      supportCount: 10,
      viewCount: 80,
      urgencyScore: 5.0,
      damageSeverity: 0.50,
      rawAiConfidenceScore: 0.90,
      needsManualReview: false,
      createdAt: DateTime(2026, 6, 2, 14, 0),
      updatedAt: DateTime(2026, 6, 2, 14, 0),
      category: const {'id': 'cat-2', 'name': 'Lampu Jalan'},
      assignedAgency: const {'id': 'agency-2', 'name': 'Dinas Perhubungan'},
    ),
    ReportModel(
      id: 'rep-admin-3',
      reportCode: 'LP_2026_001003',
      reporterId: 'user-3',
      categoryId: 'cat-3',
      status: ReportStatus.completed,
      latitude: -7.990,
      longitude: 112.620,
      addressText: 'Jl. Veteran No. 5',
      description: 'Trotoar paving terangkat',
      supportCount: 3,
      viewCount: 40,
      urgencyScore: 2.0,
      damageSeverity: 0.20,
      rawAiConfidenceScore: 0.88,
      needsManualReview: false,
      createdAt: DateTime(2026, 6, 3, 9, 30),
      updatedAt: DateTime(2026, 6, 3, 11, 0),
      category: const {'id': 'cat-3', 'name': 'Trotoar Rusak'},
      assignedAgency: const {'id': 'agency-1', 'name': 'Dinas PUPR'},
    ),
  ];

  Widget buildAdminReportsTestWidget({
    String? initialStatusFilter,
    String? initialOpdFilter,
  }) {
    final fakeReportRepo = FakeReportRepository(testReports);
    final fakeCatRepo = FakeCategoryRepository();

    return MultiRepositoryProvider(
      providers: [
        RepositoryProvider<ReportRepository>.value(value: fakeReportRepo),
        RepositoryProvider<CategoryRepository>.value(value: fakeCatRepo),
      ],
      child: MaterialApp(
        home: Scaffold(
          body: AdminReportsScreen(
            initialStatusFilter: initialStatusFilter,
            initialOpdFilter: initialOpdFilter,
          ),
        ),
      ),
    );
  }

  group('AdminReportsScreen Filter Tests', () {
    testWidgets('Renders all filter chips (Row 1 & Row 2) and reset button',
        (tester) async {
      tester.view.physicalSize = const Size(412, 1200);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      await tester.pumpWidget(buildAdminReportsTestWidget());
      await tester.pumpAndSettle();

      // Header title
      expect(find.text('Laporan'), findsWidgets);

      // Row 1 Filter chips (Blue pills)
      expect(find.text('Filter'), findsOneWidget);
      expect(find.text('Semua Status'), findsOneWidget);
      expect(find.text('Semua OPD'), findsOneWidget);

      // Row 2 Filter chips (Gray pills)
      expect(find.text('Semua Kategori'), findsOneWidget);
      expect(find.text('Semua Prioritas'), findsOneWidget);

      // Reset Filter button
      expect(find.byIcon(Icons.restart_alt_rounded), findsOneWidget);

      // Initial reports rendered
      expect(find.text('Jalan Rusak'), findsWidgets);
      expect(find.text('Lampu Jalan'), findsWidgets);
      expect(find.text('Trotoar Rusak'), findsWidgets);
    });

    testWidgets('Filters by status: Menunggu Verifikasi', (tester) async {
      tester.view.physicalSize = const Size(412, 1200);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      await tester.pumpWidget(buildAdminReportsTestWidget());
      await tester.pumpAndSettle();

      // Open status filter bottom sheet
      await tester.tap(find.text('Semua Status'));
      await tester.pumpAndSettle();

      // Tap 'Menunggu Verifikasi' option in bottom sheet
      expect(find.text('Filter Status Laporan'), findsOneWidget);
      await tester.tap(find.text('Menunggu Verifikasi').last);
      await tester.pumpAndSettle();

      // Only 'Jalan Rusak' (pending verification) should be displayed
      expect(find.text('Jalan Rusak'), findsWidgets);
      expect(find.text('Lampu Jalan'), findsNothing);
      expect(find.text('Trotoar Rusak'), findsNothing);
    });

    testWidgets('Filters by category and resets filters cleanly',
        (tester) async {
      tester.view.physicalSize = const Size(412, 1200);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      await tester.pumpWidget(buildAdminReportsTestWidget());
      await tester.pumpAndSettle();

      // Open category filter bottom sheet
      await tester.tap(find.text('Semua Kategori'));
      await tester.pumpAndSettle();

      expect(find.text('Filter Berdasarkan Kategori'), findsOneWidget);
      await tester.tap(find.text('Lampu Jalan').last);
      await tester.pumpAndSettle();

      // Only 'Lampu Jalan' matches
      expect(find.text('Lampu Jalan'), findsWidgets);
      expect(find.text('Jalan Rusak'), findsNothing);
      expect(find.text('Trotoar Rusak'), findsNothing);

      // Now tap reset button to restore all filters
      await tester.tap(find.byIcon(Icons.restart_alt_rounded));
      await tester.pumpAndSettle();

      // All reports should be back
      expect(find.text('Jalan Rusak'), findsWidgets);
      expect(find.text('Lampu Jalan'), findsWidgets);
      expect(find.text('Trotoar Rusak'), findsWidgets);
    });

    testWidgets('Real-time search filters by report code and address',
        (tester) async {
      tester.view.physicalSize = const Size(412, 1200);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      await tester.pumpWidget(buildAdminReportsTestWidget());
      await tester.pumpAndSettle();

      // Enter search text
      await tester.enterText(
          find.byType(TextField), '001003');
      await tester.pumpAndSettle();

      // Only report 3 should appear
      expect(find.text('Trotoar Rusak'), findsWidgets);
      expect(find.text('Jalan Rusak'), findsNothing);
      expect(find.text('Lampu Jalan'), findsNothing);
    });
  });
}
