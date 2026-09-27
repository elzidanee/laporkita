import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:laporkita/core/network/api_response.dart';
import 'package:laporkita/data/models/report_model.dart';
import 'package:laporkita/data/repositories/report_repository.dart';
import 'package:laporkita/data/models/policy_simulation_model.dart';
import 'package:laporkita/data/repositories/policy_simulator_repository.dart';
import 'package:laporkita/presentation/command_center/monitoring/admin_monitoring_screen.dart';
import 'package:laporkita/presentation/command_center/policy_simulator/policy_simulator_screen.dart';
import 'package:laporkita/presentation/command_center/report_management/admin_report_detail_screen.dart';

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

class FakePolicySimulatorRepository extends Fake implements PolicySimulatorRepository {
  @override
  Future<PolicySimulationModel> createSimulation({
    required String promptText,
    String? zoneId,
  }) async {
    return const PolicySimulationModel(
      id: 'sim-1',
      promptText: 'Test',
      simulatedRiskScore: 3.2,
      riskReductionPct: 32.0,
      estimatedBudgetBro: 500000000,
      impactAnalysis:
          'Kebijakan ini diperkirakan paling efektif untuk kategori jalan dan trotoar.',
      recommendedActions: ['Fokus perbaikan jalan'],
    );
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  Widget buildMonitoringTestWidget({
    bool isEmbedded = false,
    VoidCallback? onBack,
    int initialTabIndex = 0,
  }) {
    final fakeRepo = FakeReportRepository();
    final fakeSimRepo = FakePolicySimulatorRepository();

    return MultiRepositoryProvider(
      providers: [
        RepositoryProvider<ReportRepository>.value(value: fakeRepo),
        RepositoryProvider<PolicySimulatorRepository>.value(value: fakeSimRepo),
      ],
      child: MaterialApp(
        home: Scaffold(
          body: AdminMonitoringScreen(
            isEmbedded: isEmbedded,
            onBack: onBack,
            initialTabIndex: initialTabIndex,
          ),
        ),
      ),
    );
  }

  group('Figma Node 631:1382 & 638:1864 Government Monitoring Tests', () {
    testWidgets('Progress Tab (Figma 631:1382) renders all baseline visual components',
        (tester) async {
      tester.view.physicalSize = const Size(412, 1600);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      await tester.pumpWidget(buildMonitoringTestWidget());
      await tester.pumpAndSettle();

      // 1. App Bar
      expect(find.text('Monitoring'), findsOneWidget);

      // 2. Tab Bar
      expect(find.text('Progress'), findsOneWidget);
      expect(find.text('Peta Sebaran'), findsOneWidget);

      // 3. Stat Cards
      expect(find.text('Total Laporan'), findsOneWidget);
      expect(find.text('2.458'), findsOneWidget);
      expect(find.text('Sedang Diproses'), findsOneWidget);
      expect(find.text('1.286'), findsOneWidget);
      expect(find.text('Selesai'), findsOneWidget);
      expect(find.text('1.072'), findsOneWidget);
      expect(find.text('Terlambat'), findsOneWidget);
      expect(find.text('100'), findsOneWidget);

      // 4. Progress Penanganan
      expect(find.text('Progress Penanganan'), findsOneWidget);
      expect(
        find.byWidgetPredicate((w) =>
            w is RichText &&
            w.text.toPlainText().contains('1.072') &&
            w.text.toPlainText().contains('2.458')),
        findsOneWidget,
      );

      // 5. Grafik Laporan
      expect(
        find.byWidgetPredicate((w) =>
            w is RichText &&
            w.text.toPlainText().contains('Grafik Laporan') &&
            w.text.toPlainText().contains('7 hari terakhir')),
        findsOneWidget,
      );

      // 6. Kategori Laporan
      expect(find.text('Kategori Laporan'), findsOneWidget);
      expect(find.text('Jalan'), findsWidgets);
      expect(find.text('1.023 (41%)'), findsOneWidget);
      expect(find.text('Penerangan'), findsOneWidget);
      expect(find.text('Drainase'), findsWidgets);
      expect(find.text('Trotoar'), findsWidgets);

      // 7. Analisis & Kebijakan Banner
      expect(find.text('Analisis & Kebijakan'), findsOneWidget);
      expect(find.text('Buka Policy Simulator'), findsOneWidget);

      // 8. Laporan Terlambat List
      expect(find.text('Laporan Terlambat'), findsOneWidget);
      expect(find.text('Dinas PUPR'), findsWidgets);
    });

    testWidgets('Switching to Peta Sebaran Tab (Figma 638:1864) displays map and location ranking',
        (tester) async {
      tester.view.physicalSize = const Size(412, 1600);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      await tester.pumpWidget(buildMonitoringTestWidget());
      await tester.pumpAndSettle();

      // Switch to Peta Sebaran tab
      await tester.tap(find.text('Peta Sebaran'));
      await tester.pumpAndSettle();

      // 1. Floating Map Controls
      expect(find.text('Kota Malang'), findsOneWidget);
      expect(find.text('Tinggi (>=10)'), findsOneWidget);
      expect(find.text('Sedang (5-9)'), findsOneWidget);
      expect(find.text('Rendah (1-4)'), findsOneWidget);

      // 2. Ringkasan Lokasi Card
      expect(find.text('Ringkasan Lokasi'), findsOneWidget);
      expect(find.text('Klojen'), findsOneWidget);
      expect(find.text('248 Laporan'), findsOneWidget);
      expect(find.text('Lowokwaru'), findsOneWidget);
      expect(find.text('194 Laporan'), findsOneWidget);
      expect(find.text('Blimbing'), findsOneWidget);
      expect(find.text('172 Laporan'), findsOneWidget);
      expect(find.text('Kedung Kandang'), findsOneWidget);
      expect(find.text('156 Laporan'), findsOneWidget);

      // 3. Banner & Overdue reports in Peta Sebaran
      expect(find.text('Analisis & Kebijakan'), findsOneWidget);
      expect(find.text('Buka Policy Simulator'), findsOneWidget);
      expect(find.text('Laporan Terlambat'), findsOneWidget);
    });

    testWidgets('Tapping Buka Policy Simulator navigates to PolicySimulatorScreen',
        (tester) async {
      tester.view.physicalSize = const Size(412, 1600);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      await tester.pumpWidget(buildMonitoringTestWidget());
      await tester.pumpAndSettle();

      final simulatorBtn = find.text('Buka Policy Simulator');
      await tester.ensureVisible(simulatorBtn);
      await tester.tap(simulatorBtn);
      await tester.pumpAndSettle();

      expect(find.byType(PolicySimulatorScreen), findsOneWidget);
    });

    testWidgets('Tapping an overdue report card navigates to AdminReportDetailScreen',
        (tester) async {
      tester.view.physicalSize = const Size(412, 1600);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      await tester.pumpWidget(buildMonitoringTestWidget());
      await tester.pumpAndSettle();

      // Find first overdue card
      final firstCard = find.text('Jalan Rusak').last;
      await tester.ensureVisible(firstCard);
      await tester.tap(firstCard);
      await tester.pumpAndSettle();

      expect(find.byType(AdminReportDetailScreen), findsOneWidget);
    });

    testWidgets('Top back button invokes onBack callback when embedded',
        (tester) async {
      tester.view.physicalSize = const Size(412, 1200);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      bool backCalled = false;
      await tester.pumpWidget(buildMonitoringTestWidget(
        isEmbedded: true,
        onBack: () => backCalled = true,
      ));
      await tester.pumpAndSettle();

      final backBtn = find.byIcon(Icons.chevron_left_rounded);
      expect(backBtn, findsOneWidget);
      await tester.tap(backBtn);
      await tester.pumpAndSettle();

      expect(backCalled, isTrue);
    });
  });
}
