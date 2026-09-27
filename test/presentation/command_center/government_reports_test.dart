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
  });
}
