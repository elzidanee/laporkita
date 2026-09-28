import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:laporkita/core/network/api_response.dart';
import 'package:laporkita/data/models/report_model.dart';
import 'package:laporkita/data/repositories/report_repository.dart';
import 'package:laporkita/presentation/command_center/report_management/admin_verification_action_screen.dart';

class MockReportRepository extends Fake implements ReportRepository {
  bool getReportsCalled = false;
  bool updateReportStatusCalled = false;
  String? updatedStatus;
  String? updatedNotes;

  @override
  Future<ApiResponse<List<ReportModel>>> getReports({
    int limit = 20,
    String? cursor,
    String? status,
    String? categoryId,
    String? reporterId,
    String sortBy = 'newest',
  }) async {
    getReportsCalled = true;
    return ApiResponse<List<ReportModel>>(
      success: true,
      data: [],
    );
  }

  @override
  Future<ReportModel> updateReportStatus(
    String reportId,
    String newStatus, {
    String? notes,
    String? assignedAgencyId,
    ReportModel? existingReport,
  }) async {
    updateReportStatusCalled = true;
    updatedStatus = newStatus;
    updatedNotes = notes;
    return (existingReport ?? dummyReport).copyWith(
      id: reportId,
      status: ReportStatus.rejected,
    );
  }
}

final dummyReport = ReportModel(
  id: 'rep-627-1029',
  reportCode: 'LP-2026-002487',
  reporterId: 'user-1',
  categoryId: 'cat-1',
  status: ReportStatus.inProgress,
  latitude: -6.208728,
  longitude: 107.734562,
  addressText: 'Jl. Ahmad Yani no. 15',
  description: 'Jalan sudah tidak layak karena banyak retakan.',
  directPhotoUrl: null,
  supportCount: 14,
  viewCount: 120,
  urgencyScore: 8.5, // 85% high urgency
  damageSeverity: 0.85,
  rawAiConfidenceScore: 0.98,
  needsManualReview: false,
  createdAt: DateTime(2026, 5, 12, 10, 30),
  updatedAt: DateTime(2026, 5, 12, 10, 30),
  category: const {'id': 'cat-1', 'name': 'Jalan Rusak'},
  reporter: const {'id': 'user-1', 'full_name': 'Budi Santoso'},
  assignedAgency: const {'id': 'agency-1', 'name': 'Dinas PUPR'},
);

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  Widget buildVerificationWidget(
    MockReportRepository mockRepo, {
    int initialTabIndex = 0,
  }) {
    return MultiRepositoryProvider(
      providers: [
        RepositoryProvider<ReportRepository>.value(value: mockRepo),
      ],
      child: MaterialApp(
        home: AdminVerificationActionScreen(
          report: dummyReport,
          initialTabIndex: initialTabIndex,
        ),
      ),
    );
  }

  group('Figma Node 627:1029 & 627:1160 Tindak Lanjut Verifikasi Tests', () {
    testWidgets(
        'Renders AI Verification page (Figma Node 627:1029) directly by default',
        (tester) async {
      tester.view.physicalSize = const Size(412, 1400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      final mockRepo = MockReportRepository();
      await tester.pumpWidget(buildVerificationWidget(mockRepo));
      await tester.pumpAndSettle();

      // 1. Top bar: Chevron back button & share icon
      expect(find.byIcon(Icons.chevron_left_rounded), findsOneWidget);
      expect(find.byIcon(Icons.share_outlined), findsOneWidget);

      // 2. Tab Bar: Both tabs visible, AI Verification active
      expect(find.text('AI Verification'), findsOneWidget);
      expect(find.text('Manual Review'), findsOneWidget);

      // 3. Header: Code, Category, Address, Prioritas Tinggi badge
      expect(find.text('#LP-2026-002487'), findsWidgets);
      expect(find.text('Jalan Rusak'), findsWidgets);
      expect(find.text('Jl. Ahmad Yani no. 15'), findsWidgets);
      expect(find.text('Prioritas Tinggi'), findsOneWidget);

      // 4. Hero Telemetry Photo Stamp
      expect(find.text('LaporKita'), findsOneWidget);

      // 5. Card 1: Hasil AI Verification
      expect(find.text('Hasil AI Verification'), findsOneWidget);
      expect(find.text('Foto Valid'), findsOneWidget);
      expect(find.text('GPS Valid'), findsOneWidget);
      expect(find.text('Timestamp Valid'), findsOneWidget);
      expect(find.text('Metadata lengkap'), findsOneWidget);
      expect(find.text('Confidence Score'), findsOneWidget);
      expect(find.text('98%'), findsOneWidget);

      // 6. Card 2: Analisis AI
      expect(find.text('Analisis AI'), findsOneWidget);
      expect(find.text('Model : YOLOv11 + Gemini 2.5 Flash'), findsOneWidget);
      expect(find.text('Waktu Proses : 4.21 detik'), findsOneWidget);
      expect(find.text('Rekomendasi Prioritas'), findsOneWidget);
      expect(find.text('Lihat detail Analisis'), findsOneWidget);

      // 7. Action Buttons (Figma 627:1119)
      expect(find.text('Setujui & Teruskan'), findsOneWidget);
      expect(find.text('Tolak Laporan'), findsOneWidget);
      expect(find.text('Meminta Revisi'), findsOneWidget);
    });

    testWidgets(
        'Switches to Manual Review tab (Figma Node 627:1160) and displays all elements',
        (tester) async {
      tester.view.physicalSize = const Size(412, 1400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      final mockRepo = MockReportRepository();
      await tester.pumpWidget(buildVerificationWidget(mockRepo));
      await tester.pumpAndSettle();

      // Tap on Manual Review tab
      await tester.tap(find.text('Manual Review'));
      await tester.pumpAndSettle();

      // 1. Card 1: Hasil Pemeriksaan Manual (Figma 627:1192)
      expect(find.text('Hasil Pemeriksaan Manual'), findsOneWidget);
      expect(find.text('Foto sesuai laporan'), findsOneWidget);
      expect(find.text('Lokasi sesuai'), findsOneWidget);
      expect(find.text('Laporan duplikat'), findsOneWidget);

      // 2. Section 2: Kategori Laporan (Figma 627:1216)
      expect(find.text('Kategori Laporan'), findsOneWidget);
      expect(find.byIcon(Icons.keyboard_arrow_down_rounded), findsOneWidget);

      // 3. Section 3: Prioritas pills (Figma 627:1227)
      expect(find.text('Prioritas'), findsOneWidget);
      expect(find.text('Rendah'), findsOneWidget);
      expect(find.text('Sedang'), findsOneWidget);
      expect(find.text('Tinggi'), findsOneWidget);

      // 4. Section 4: Catatan *opsional (Figma 627:1252)
      expect(find.text('Catatan'), findsOneWidget);
      expect(find.text('*opsional'), findsOneWidget);
      expect(find.text('0/200'), findsOneWidget);
      expect(find.byIcon(Icons.assignment_outlined), findsOneWidget);

      // 5. Action Buttons are also present
      expect(find.text('Setujui & Teruskan'), findsOneWidget);
      expect(find.text('Tolak Laporan'), findsOneWidget);
      expect(find.text('Meminta Revisi'), findsOneWidget);
    });

    testWidgets(
        'Manual Review category dropdown only shows Jalan Rusak, Trotoar Rusak, Drainase, Lampu Jalan, Rambu Lalu Lintas',
        (tester) async {
      tester.view.physicalSize = const Size(412, 1400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      final mockRepo = MockReportRepository();
      await tester.pumpWidget(buildVerificationWidget(mockRepo));
      await tester.pumpAndSettle();

      // Tap on Manual Review tab
      await tester.tap(find.text('Manual Review'));
      await tester.pumpAndSettle();

      // Tap on Category dropdown
      await tester.tap(find.byIcon(Icons.keyboard_arrow_down_rounded));
      await tester.pumpAndSettle();

      expect(find.text('Pilih Kategori Laporan'), findsOneWidget);
      expect(find.text('Jalan Rusak'), findsWidgets);
      expect(find.text('Trotoar Rusak'), findsOneWidget);
      expect(find.text('Drainase'), findsOneWidget);
      expect(find.text('Lampu Jalan'), findsOneWidget);
      expect(find.text('Rambu Lalu Lintas'), findsOneWidget);

      // Excluded categories must not exist
      expect(find.text('Sampah & Kebersihan'), findsNothing);
      expect(find.text('Fasilitas Umum'), findsNothing);
      expect(find.text('Lainnya'), findsNothing);

      // Selecting Drainase updates the dropdown value
      await tester.tap(find.widgetWithText(ListTile, 'Drainase'));
      await tester.pumpAndSettle();

      expect(find.text('Drainase'), findsWidgets);
    });

    testWidgets('Tapping Tolak Laporan opens reject dialog and triggers backend',
        (tester) async {
      tester.view.physicalSize = const Size(412, 1400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      final mockRepo = MockReportRepository();
      await tester.pumpWidget(buildVerificationWidget(mockRepo));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Tolak Laporan'));
      await tester.pumpAndSettle();

      expect(find.text('Masukkan alasan penolakan laporan ini:'), findsOneWidget);
      expect(find.text('Tolak'), findsOneWidget);

      await tester.enterText(
        find.byType(TextField),
        'Foto tidak jelas dan tidak ada bukti kerusakan jalan.',
      );
      await tester.tap(find.text('Tolak'));
      await tester.pumpAndSettle();

      expect(mockRepo.updateReportStatusCalled, isTrue);
      expect(mockRepo.updatedStatus, 'rejected');
      expect(
        mockRepo.updatedNotes,
        'Foto tidak jelas dan tidak ada bukti kerusakan jalan.',
      );
    });

    testWidgets('Tapping Meminta Revisi opens revision dialog', (tester) async {
      tester.view.physicalSize = const Size(412, 1400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      final mockRepo = MockReportRepository();
      await tester.pumpWidget(buildVerificationWidget(mockRepo));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Meminta Revisi'));
      await tester.pumpAndSettle();

      expect(find.text('Meminta Revisi Laporan'), findsOneWidget);
      expect(
        find.text('Instruksi perbaikan untuk warga pelapor:'),
        findsOneWidget,
      );
      expect(find.text('Kirim Revisi'), findsOneWidget);
    });

    testWidgets('Tapping Lihat detail Analisis opens AI detail bottom sheet',
        (tester) async {
      tester.view.physicalSize = const Size(412, 1400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      final mockRepo = MockReportRepository();
      await tester.pumpWidget(buildVerificationWidget(mockRepo));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Lihat detail Analisis'));
      await tester.pumpAndSettle();

      expect(
        find.text('Detail Analisis AI Vision & Telemetri'),
        findsOneWidget,
      );
      expect(find.text('Tutup'), findsOneWidget);
    });
  });
}
