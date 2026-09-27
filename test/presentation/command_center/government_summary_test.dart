import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:laporkita/presentation/command_center/analytics/government_summary_screen.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  Widget buildSummaryTestWidget({bool isEmbedded = false}) {
    return MaterialApp(
      home: Scaffold(
        body: GovernmentSummaryScreen(isEmbedded: isEmbedded),
      ),
    );
  }

  group('Figma Node 613:3502 Government Summary Screen Tests', () {
    testWidgets('Renders all visual sections standalone', (tester) async {
      tester.view.physicalSize = const Size(412, 1200);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      await tester.pumpWidget(buildSummaryTestWidget(isEmbedded: false));
      await tester.pumpAndSettle();

      // 1. App Bar
      expect(find.text('Ringkasan Kota'), findsOneWidget);

      // 2. Filter Pills
      expect(find.text('Semua OPD'), findsOneWidget);
      expect(find.text('30 Hari Terakhir'), findsOneWidget);

      // 3. Section 1: Line Chart
      expect(find.text('Perkembangan Laporan'), findsWidgets);
      expect(find.textContaining('Grafik Laporan'), findsOneWidget);
      expect(find.textContaining('7 hari terakhir'), findsOneWidget);

      // 4. Section 2: Donut Chart
      expect(find.text('2.458'), findsOneWidget);
      expect(find.text('Total Laporan'), findsOneWidget);
      expect(find.text('Jalan'), findsOneWidget);
      expect(find.text('45%'), findsOneWidget);
      expect(find.text('Lapu Jalan'), findsOneWidget);
      expect(find.text('Trotoar'), findsOneWidget);
      expect(find.text('Taman'), findsOneWidget);
      expect(find.text('Lainya'), findsOneWidget);
      expect(find.text('20%'), findsNWidgets(4));

      // 5. Section 3: Ranked Regions
      expect(find.text('Wilayah dengan Laporan Terbanyak'), findsOneWidget);
      expect(find.text('Klojen'), findsOneWidget);
      expect(find.text('248 Laporan'), findsOneWidget);
      expect(find.text('Lowokwaru'), findsOneWidget);
      expect(find.text('194 Laporan'), findsOneWidget);
      expect(find.text('Blimbing'), findsOneWidget);
      expect(find.text('172 Laporan'), findsOneWidget);
      expect(find.text('Kedung Kandang'), findsOneWidget);
      expect(find.text('156 Laporan'), findsOneWidget);

      // 6. Section 4: Action cards
      expect(find.text('Prediksi kondisi Kota'), findsOneWidget);
      expect(find.text('Lihat Prediksi'), findsOneWidget);
      expect(find.text('Policy Simulator'), findsOneWidget);
      expect(find.text('Buat Simulator'), findsOneWidget);
    });

    testWidgets('Filter pills open popup menu and update selection',
        (tester) async {
      tester.view.physicalSize = const Size(412, 1000);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      await tester.pumpWidget(buildSummaryTestWidget(isEmbedded: true));
      await tester.pumpAndSettle();

      // Tap OPD filter pill
      await tester.tap(find.text('Semua OPD'));
      await tester.pumpAndSettle();

      // Popup menu items appear
      expect(find.text('Dinas PUPR'), findsWidgets);

      // Select Dinas PUPR from popup menu
      await tester.tap(find.text('Dinas PUPR').last);
      await tester.pumpAndSettle();

      // Check updated pill
      expect(find.text('Dinas PUPR'), findsOneWidget);
    });

    testWidgets('Embedded mode does not duplicate app bar', (tester) async {
      tester.view.physicalSize = const Size(412, 1000);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      await tester.pumpWidget(buildSummaryTestWidget(isEmbedded: true));
      await tester.pumpAndSettle();

      // Embedded mode renders header text without Scaffold AppBar
      expect(find.text('Ringkasan Kota'), findsOneWidget);
      expect(find.byType(AppBar), findsNothing);
    });
  });
}
