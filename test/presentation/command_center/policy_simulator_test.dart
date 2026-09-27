import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:laporkita/data/models/policy_simulation_model.dart';
import 'package:laporkita/data/models/risk_prediction_model.dart';
import 'package:laporkita/data/repositories/policy_simulator_repository.dart';
import 'package:laporkita/data/repositories/prediction_repository.dart';
import 'package:laporkita/presentation/command_center/policy_simulator/policy_simulator_screen.dart';

class FakePolicySimulatorRepository extends Fake implements PolicySimulatorRepository {
  @override
  Future<PolicySimulationModel> createSimulation({
    required String promptText,
    String? zoneId,
  }) async {
    return const PolicySimulationModel(
      id: 'sim-test-1',
      promptText: 'Simulasi alokasi anggaran tambahan',
      simulatedRiskScore: 2.5,
      riskReductionPct: 35.0,
      estimatedBudgetBro: 500000000,
      impactAnalysis:
          'Kebijakan ini diprediksi sangat efektif untuk meningkatkan kecepatan pengerjaan.',
      recommendedActions: [
        'Prioritaskan perbaikan jalan protokol',
        'Tambah personel dinas'
      ],
    );
  }
}

class FakePredictionRepository extends Fake implements PredictionRepository {
  @override
  Future<List<ZoneMetricsModel>> getZones() async {
    return [
      const ZoneMetricsModel(
        id: 'zone-klojen',
        name: 'Kec. Klojen',
        code: 'KLJ',
        reportDensity: 248,
        trafficDensity: 0.7,
        floodRiskProbability: 0.3,
        stressLevel: 'Sedang',
        weatherCondition: 'Cerah',
        rainfallMm: 0.0,
      ),
    ];
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  Widget buildPolicySimulatorTestWidget({VoidCallback? onBack}) {
    final fakeSimRepo = FakePolicySimulatorRepository();
    final fakePredRepo = FakePredictionRepository();

    return MultiRepositoryProvider(
      providers: [
        RepositoryProvider<PolicySimulatorRepository>.value(value: fakeSimRepo),
        RepositoryProvider<PredictionRepository>.value(value: fakePredRepo),
      ],
      child: MaterialApp(
        home: Scaffold(
          body: PolicySimulatorScreen(onBack: onBack),
        ),
      ),
    );
  }

  group('Figma Node 648:4092 Policy Simulator Tests', () {
    testWidgets('Renders all visual baseline components from Figma', (tester) async {
      tester.view.physicalSize = const Size(412, 1200);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      await tester.pumpWidget(buildPolicySimulatorTestWidget());
      await tester.pumpAndSettle();

      // 1. App Bar
      expect(find.text('Policy Simulator'), findsOneWidget);
      expect(find.byIcon(Icons.chevron_left_rounded), findsOneWidget);
      expect(find.byIcon(Icons.share_outlined), findsOneWidget);

      // 2. Kategori Laporan Dropdown Pill
      expect(find.text('Kategori Laporan'), findsOneWidget);
      expect(find.byIcon(Icons.assignment_outlined), findsOneWidget);
      expect(
        find.byWidgetPredicate((w) =>
            w is RichText &&
            w.text.toPlainText().contains('Peningkatan Anggaran') &&
            w.text.toPlainText().contains('PUPR')),
        findsOneWidget,
      );

      // 3. Terapkan diwilayah Dropdown Pill
      expect(find.text('Terapkan diwilayah'), findsOneWidget);
      expect(find.byIcon(Icons.location_city_rounded), findsOneWidget);
      expect(find.text('Kota Malang'), findsOneWidget);

      // 4. Proyeksi Dampak Card
      expect(
        find.byWidgetPredicate((w) =>
            w is RichText &&
            w.text.toPlainText().contains('Proyeksi Dampak') &&
            w.text.toPlainText().contains('(30 hari)')),
        findsOneWidget,
      );
      expect(find.text('Penurunan laporan tertunda'), findsOneWidget);
      expect(find.text('+32%'), findsOneWidget);
      expect(find.text('Waktu penyelesaian rata-rata'), findsOneWidget);
      expect(find.text('-3,1 hari'), findsOneWidget);
      expect(find.text('Laporan yang dapat diselesaikan'), findsOneWidget);
      expect(find.text('+ 486 laporan'), findsOneWidget);

      // 5. Rekomendasi Card
      expect(find.text('Rekomendasi'), findsOneWidget);
      expect(find.byIcon(Icons.verified_user_rounded), findsOneWidget);
      expect(
        find.textContaining('Kebijakan ini diperkirakan paling efektif'),
        findsOneWidget,
      );

      // 6. Action Button
      expect(find.text('Setujui & Teruskan'), findsOneWidget);
    });

    testWidgets('Tapping Kategori Laporan opens modal and triggers AI simulation',
        (tester) async {
      tester.view.physicalSize = const Size(412, 1200);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      await tester.pumpWidget(buildPolicySimulatorTestWidget());
      await tester.pumpAndSettle();

      // Tap on the Kategori Laporan pill
      final categoryPill = find.byIcon(Icons.assignment_outlined);
      await tester.tap(categoryPill);
      await tester.pumpAndSettle();

      // Verify modal is displayed
      expect(find.text('Pilih Skenario Kebijakan'), findsOneWidget);
      expect(find.text('Penambahan Armada Kebersihan DLH'), findsOneWidget);

      // Tap another scenario
      await tester.tap(find.text('Penambahan Armada Kebersihan DLH'));
      await tester.pumpAndSettle();

      // Verify selected policy updated
      expect(
        find.byWidgetPredicate((w) =>
            w is RichText &&
            w.text.toPlainText().contains('Penambahan Armada') &&
            w.text.toPlainText().contains('DLH')),
        findsOneWidget,
      );
    });

    testWidgets('Tapping Terapkan diwilayah opens region modal and triggers AI',
        (tester) async {
      tester.view.physicalSize = const Size(412, 1200);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      await tester.pumpWidget(buildPolicySimulatorTestWidget());
      await tester.pumpAndSettle();

      // Tap region selector pill
      final regionPill = find.byIcon(Icons.location_city_rounded);
      await tester.tap(regionPill);
      await tester.pumpAndSettle();

      // Verify modal
      expect(find.text('Terapkan di Wilayah'), findsOneWidget);
      expect(find.text('Kec. Klojen'), findsOneWidget);

      // Select Kec. Klojen
      await tester.tap(find.text('Kec. Klojen'));
      await tester.pumpAndSettle();

      expect(find.text('Kec. Klojen'), findsOneWidget);
    });

    testWidgets('Tapping Setujui & Teruskan opens confirmation dialog',
        (tester) async {
      tester.view.physicalSize = const Size(412, 1200);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      await tester.pumpWidget(buildPolicySimulatorTestWidget());
      await tester.pumpAndSettle();

      final approveBtn = find.text('Setujui & Teruskan');
      await tester.tap(approveBtn);
      await tester.pumpAndSettle();

      expect(find.text('Kebijakan Berhasil Disetujui'), findsOneWidget);
      expect(find.text('Kembali ke Monitoring'), findsOneWidget);
    });

    testWidgets('Tapping back button invokes onBack callback', (tester) async {
      tester.view.physicalSize = const Size(412, 1200);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      bool backCalled = false;
      await tester.pumpWidget(buildPolicySimulatorTestWidget(
        onBack: () => backCalled = true,
      ));
      await tester.pumpAndSettle();

      final backBtn = find.byIcon(Icons.chevron_left_rounded);
      await tester.tap(backBtn);
      await tester.pumpAndSettle();

      expect(backCalled, isTrue);
    });
  });
}
