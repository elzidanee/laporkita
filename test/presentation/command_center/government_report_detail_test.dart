import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:laporkita/core/network/api_response.dart';
import 'package:laporkita/data/models/report_model.dart';
import 'package:laporkita/data/repositories/report_repository.dart';
import 'package:laporkita/presentation/command_center/report_management/admin_report_detail_screen.dart';

class MockReportRepository extends Fake implements ReportRepository {
  bool getReportByIdCalled = false;
  bool getCommentsCalled = false;
  bool addCommentCalled = false;

  @override
  Future<ReportModel> getReportById(String id) async {
    getReportByIdCalled = true;
    return ReportModel(
      id: id,
      reportCode: 'LP_2026_002487',
      reporterId: 'user-1',
      categoryId: 'cat-1',
      status: ReportStatus.inProgress,
      latitude: -6.382728,
      longitude: 107.734682,
      addressText: 'Jl. Ahmad Yani no. 15',
      description:
          'Jalan sudah tidak layak karena banyak retakan dan lubang disepanjang jalan.',
      directPhotoUrl: null,
      supportCount: 14,
      viewCount: 120,
      urgencyScore: 4.5,
      damageSeverity: 0.85,
      rawAiConfidenceScore: 0.98,
      needsManualReview: false,
      createdAt: DateTime(2026, 5, 12, 10, 30),
      updatedAt: DateTime(2026, 5, 12, 10, 30),
      category: const {'id': 'cat-1', 'name': 'Jalan Rusak'},
      reporter: const {'id': 'user-1', 'full_name': 'Budi Santoso'},
      assignedAgency: const {'id': 'agency-1', 'name': 'Dinas PUPR'},
    );
  }

  @override
  Future<ApiResponse<List<Map<String, dynamic>>>> getComments(
    String reportId, {
    int limit = 20,
    String? cursor,
  }) async {
    getCommentsCalled = true;
    return ApiResponse<List<Map<String, dynamic>>>(
      success: true,
      data: [
        {
          'id': 'comment-1',
          'author_name': 'Dinas PUPR',
          'content': 'Tim survei jalan telah diberangkatkan ke lokasi.',
          'created_at': DateTime(2026, 5, 12, 11, 0).toIso8601String(),
        },
      ],
    );
  }

  @override
  Future<Map<String, dynamic>> addComment(
    String reportId,
    String content,
  ) async {
    addCommentCalled = true;
    return {
      'id': 'comment-new',
      'author_name': 'Policy Maker',
      'content': content,
      'created_at': DateTime.now().toIso8601String(),
    };
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  final dummyReport = ReportModel(
    id: 'rep-627-872',
    reportCode: 'LP_2026_002487',
    reporterId: 'user-1',
    categoryId: 'cat-1',
    status: ReportStatus.inProgress,
    latitude: -6.382728,
    longitude: 107.734682,
    addressText: 'Jl. Ahmad Yani no. 15',
    description:
        'Jalan sudah tidak layak karena banyak retakan dan lubang disepanjang jalan.',
    directPhotoUrl: null,
    supportCount: 14,
    viewCount: 120,
    urgencyScore: 4.5,
    damageSeverity: 0.85,
    rawAiConfidenceScore: 0.98,
    needsManualReview: false,
    createdAt: DateTime(2026, 5, 12, 10, 30),
    updatedAt: DateTime(2026, 5, 12, 10, 30),
    category: const {'id': 'cat-1', 'name': 'Jalan Rusak'},
    reporter: const {'id': 'user-1', 'full_name': 'Budi Santoso'},
    assignedAgency: const {'id': 'agency-1', 'name': 'Dinas PUPR'},
  );

  Widget buildDetailWidget(MockReportRepository mockRepo) {
    return MultiRepositoryProvider(
      providers: [
        RepositoryProvider<ReportRepository>.value(value: mockRepo),
      ],
      child: MaterialApp(
        home: AdminReportDetailScreen(report: dummyReport),
      ),
    );
  }

  group('Figma Node 627:872 Detail Laporan Pemerintah Tests', () {
    testWidgets('Renders all Figma 627:872 elements & key attributes',
        (tester) async {
      tester.view.physicalSize = const Size(412, 1400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      final mockRepo = MockReportRepository();
      await tester.pumpWidget(buildDetailWidget(mockRepo));
      await tester.pumpAndSettle();

      // 1. Verify getReportById & getComments were fetched from backend repository
      expect(mockRepo.getReportByIdCalled, isTrue);
      expect(mockRepo.getCommentsCalled, isTrue);

      // 2. Top App Bar
      expect(find.text('Detail Laporan'), findsOneWidget);
      expect(find.byIcon(Icons.chevron_left_rounded), findsOneWidget);
      expect(find.byIcon(Icons.share_outlined), findsOneWidget);

      // 3. Header Info
      expect(find.text('#LP-2026-002487'), findsWidgets);
      expect(find.text('Jalan Rusak'), findsWidgets);
      expect(find.text('Jl. Ahmad Yani no. 15'), findsWidgets);
      expect(find.text('Prioritas Tinggi'), findsOneWidget);

      // 4. Hero Geotag Stamp Box
      expect(find.text('LaporKita'), findsOneWidget);

      // 5. Description Section
      expect(find.text('Deskripsi :'), findsOneWidget);
      expect(
        find.text(
            'Jalan sudah tidak layak karena banyak retakan dan lubang disepanjang jalan.'),
        findsOneWidget,
      );

      // 6. Key-Values Attributes List
      expect(find.text('Laporan dibuat'), findsOneWidget);
      expect(find.text('Pelapor'), findsOneWidget);
      expect(find.text('Budi Santoso'), findsOneWidget);
      expect(find.text('Kategori'), findsOneWidget);
      expect(find.text('Prioritas AI'), findsOneWidget);
      expect(find.text('OPD Tujuan'), findsOneWidget);
      expect(find.text('Dinas PUPR'), findsOneWidget);
      expect(find.text('Koordinat'), findsOneWidget);

      // 7. Action Button "Lihat Pada Peta"
      expect(find.text('Lihat Pada Peta'), findsOneWidget);

      // 8. AI Verification Card
      expect(find.text('AI Verification'), findsOneWidget);
      expect(find.text('Foto Valid'), findsOneWidget);
      expect(find.text('GPS Valid'), findsOneWidget);
      expect(find.text('Timestamp Valid'), findsOneWidget);
      expect(find.text('Metadata lengkap'), findsOneWidget);
      expect(find.text('Confidence Score'), findsOneWidget);
      expect(find.text('98%'), findsOneWidget);

      // 9. Bottom Action Bar Buttons
      expect(find.text('Riwayat'), findsOneWidget);
      expect(find.text('Catatan'), findsOneWidget);
      expect(find.text('Tindak Lanjut'), findsOneWidget);
    });

    testWidgets('Opens Catatan Modal and displays backend comments',
        (tester) async {
      tester.view.physicalSize = const Size(412, 1400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      final mockRepo = MockReportRepository();
      await tester.pumpWidget(buildDetailWidget(mockRepo));
      await tester.pumpAndSettle();

      // Tap Catatan Button
      await tester.tap(find.text('Catatan'));
      await tester.pumpAndSettle();

      // Expect Notes Bottom Sheet Modal
      expect(find.text('Catatan & Komentar'), findsOneWidget);
      expect(
        find.text('Tim survei jalan telah diberangkatkan ke lokasi.'),
        findsOneWidget,
      );
      expect(find.text('Tambah catatan tindak lanjut...'), findsOneWidget);

      // Enter comment & submit
      await tester.enterText(
        find.byType(TextField),
        'Percepatan pengaspalan jalan dijadwalkan minggu depan.',
      );
      await tester.tap(find.byIcon(Icons.send_rounded));
      await tester.pumpAndSettle();

      expect(mockRepo.addCommentCalled, isTrue);
    });

    testWidgets(
        'Priority status in detail matches backend input (Prioritas Tinggi)',
        (tester) async {
      tester.view.physicalSize = const Size(412, 1400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      final highPriorityReport = ReportModel(
        id: 'rep-backend-high',
        reportCode: 'LP_2026_009988',
        reporterId: 'user-1',
        categoryId: 'cat-1',
        status: ReportStatus.inProgress,
        latitude: -7.9540,
        longitude: 112.6200,
        addressText: 'Jl. Soekarno Hatta No. 88',
        description: 'Jalan berlubang parah',
        supportCount: 10,
        viewCount: 50,
        urgencyScore: 2.07, // Real backend score
        damageSeverity: 0.75, // Severe damage from backend
        needsManualReview: false,
        createdAt: DateTime(2026, 5, 12, 10, 30),
        updatedAt: DateTime(2026, 5, 12, 10, 30),
        category: const {'name': 'Jalan Rusak'},
        statusHistory: [
          ReportStatusHistoryModel(
            id: 'h-1',
            reportId: 'rep-backend-high',
            targetStatus: ReportStatus.inProgress,
            note: 'Penugasan (Prioritas: Tinggi)',
            createdAt: DateTime(2026, 5, 12, 10, 30),
          ),
        ],
      );

      final mockRepo = MockReportRepository();
      await tester.pumpWidget(
        MultiRepositoryProvider(
          providers: [
            RepositoryProvider<ReportRepository>.value(value: mockRepo),
          ],
          child: MaterialApp(
            home: AdminReportDetailScreen(report: highPriorityReport),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Priority badge in header MUST be Prioritas Tinggi (NOT Rendah)
      expect(find.text('Prioritas Tinggi'), findsOneWidget);
      expect(find.text('Rendah'), findsNothing);

      // Prioritas AI in attributes table MUST show Tinggi (NOT Rendah)
      expect(find.textContaining('Tinggi'), findsWidgets);
    });
  });
}
