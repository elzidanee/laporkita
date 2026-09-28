import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:laporkita/core/network/api_response.dart';
import 'package:laporkita/data/models/auth_token_model.dart';
import 'package:laporkita/data/models/report_model.dart';
import 'package:laporkita/data/models/user_model.dart';
import 'package:laporkita/data/repositories/auth_repository.dart';
import 'package:laporkita/data/repositories/notification_repository.dart';
import 'package:laporkita/data/repositories/report_repository.dart';
import 'package:laporkita/presentation/auth/bloc/auth_bloc.dart';
import 'package:laporkita/presentation/command_center/dashboard/operator_dashboard_screen.dart';
import 'package:laporkita/presentation/command_center/dashboard/operator_tugas_screen.dart';
import 'package:laporkita/presentation/command_center/dashboard/operator_report_detail_screen.dart';

class FakeReportRepository extends Fake implements ReportRepository {
  final List<ReportModel> mockReports;

  FakeReportRepository([this.mockReports = const []]);

  @override
  List<ReportModel> get localSubmittedReports => mockReports;

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
      data: mockReports,
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
    final report = mockReports.firstWhere(
      (r) => r.id == reportId,
      orElse: () => existingReport!,
    );
    return report.copyWith(
      status: ReportStatus.fromString(newStatus),
      directPriority: notes?.contains('Prioritas') == true ? 'Prioritas Tinggi' : report.directPriority,
    );
  }
}

class FakeAuthRepository extends Fake implements AuthRepository {
  @override
  Future<UserModel?> getCachedUser() async => const UserModel(
        id: 'op-1',
        fullName: 'Bambang Petugas',
        email: 'bambang@opd.go.id',
        role: UserRole.operator,
        contributionPoints: 100,
      );
}

class FakeNotificationRepository extends Fake implements NotificationRepository {
  @override
  Future<void> addStatusUpdateNotification({
    required String reportCode,
    required ReportStatus newStatus,
    String? note,
    String? reportId,
  }) async {}
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  final testReports = [
    ReportModel(
      id: 'rep-op-1',
      reportCode: 'LP_2026_0024487',
      reporterId: 'user-1',
      categoryId: 'cat-1',
      status: ReportStatus.assigned,
      latitude: -7.982,
      longitude: 112.631,
      addressText: 'Jl. Ahmad Yani no. 15',
      description: 'Jalan sudah tidak layak karena banyak retakan.',
      directPhotoUrl: null,
      supportCount: 20,
      viewCount: 100,
      urgencyScore: 8.5,
      damageSeverity: 0.85,
      rawAiConfidenceScore: 0.85,
      needsManualReview: false,
      createdAt: DateTime(2026, 5, 12, 10, 30),
      updatedAt: DateTime(2026, 5, 12, 10, 30),
      category: const {'id': 'cat-1', 'name': 'Jalan Rusak'},
      reporter: const {'id': 'user-1', 'full_name': 'Budi Santoso'},
      assignedAgency: const {'id': 'agency-1', 'name': 'Dinas PUPR'},
      directPriority: 'Prioritas Tinggi',
    ),
    ReportModel(
      id: 'rep-op-2',
      reportCode: 'LP_2026_0038217',
      reporterId: 'user-2',
      categoryId: 'cat-2',
      status: ReportStatus.inProgress,
      latitude: -7.985,
      longitude: 112.635,
      addressText: 'Jl. soekarno hatta no.20 A',
      description: 'Halte bus rusak dan atap roboh.',
      directPhotoUrl: null,
      supportCount: 15,
      viewCount: 80,
      urgencyScore: 5.5,
      damageSeverity: 0.50,
      rawAiConfidenceScore: 0.80,
      needsManualReview: false,
      createdAt: DateTime(2026, 4, 4, 10, 23),
      updatedAt: DateTime(2026, 4, 4, 10, 23),
      category: const {'id': 'cat-2', 'name': 'Halte rusak'},
      reporter: const {'id': 'user-2', 'full_name': 'Siti Rahma'},
      assignedAgency: const {'id': 'agency-2', 'name': 'Dishub'},
      directPriority: 'Sedang',
    ),
  ];

  Widget createWidgetUnderTest(Widget child) {
    final fakeReportRepo = FakeReportRepository(testReports);
    final fakeAuthRepo = FakeAuthRepository();
    final fakeNotifRepo = FakeNotificationRepository();

    const mockOperator = UserModel(
      id: 'op-1',
      fullName: 'Bambang Petugas',
      email: 'bambang@opd.go.id',
      role: UserRole.operator,
      contributionPoints: 100,
    );

    return MultiRepositoryProvider(
      providers: [
        RepositoryProvider<ReportRepository>.value(value: fakeReportRepo),
        RepositoryProvider<AuthRepository>.value(value: fakeAuthRepo),
        RepositoryProvider<NotificationRepository>.value(value: fakeNotifRepo),
      ],
      child: BlocProvider<AuthBloc>(
        create: (_) => AuthBloc(authRepository: fakeAuthRepo)
          ..emit(const AuthAuthenticated(
            user: mockOperator,
            tokens: AuthTokenModel(
              accessToken: 'mock_access_token',
              refreshToken: 'mock_refresh_token',
              expiresIn: '3600',
              tokenType: 'Bearer',
              user: mockOperator,
            ),
          )),
        child: MaterialApp(
          home: child,
        ),
      ),
    );
  }

  group('Operator Dashboard & Bottom Navigation (Figma 485:7874 & 485:8094)', () {
    testWidgets('renders header, 2x2 stat cards, priority task, and 5 nav items',
        (tester) async {
      tester.view.physicalSize = const Size(412, 1400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      await tester.pumpWidget(createWidgetUnderTest(const OperatorDashboardScreen()));
      await tester.pumpAndSettle();

      // Check header greeting
      expect(find.textContaining('Hallo!'), findsOneWidget);
      expect(find.textContaining('Berikut laporan yang menjadi tanggung jawab anda'), findsOneWidget);

      // Check 2x2 stat cards
      expect(find.text('Tugas Baru'), findsOneWidget);
      expect(find.text('Sedang Dikerjakan'), findsWidgets);
      expect(find.text('Selesai'), findsWidgets);
      expect(find.text('Terlambat'), findsOneWidget);

      // Check priority task card
      expect(find.text('Tugas Prioritas hari ini'), findsOneWidget);
      expect(find.text('Mulai Tugas'), findsOneWidget);

      // Check 3 summary cards
      expect(find.text('Total update'), findsOneWidget);
      expect(find.text('Foto diunggah'), findsOneWidget);
      expect(find.text('Rata-rata Progress'), findsOneWidget);

      // Check 5 Bottom Nav Items
      expect(find.text('Dashboard'), findsOneWidget);
      expect(find.text('Tugas'), findsOneWidget);
      expect(find.text('Laporan'), findsOneWidget);
      expect(find.text('Monitoring'), findsOneWidget);
      expect(find.text('Profile'), findsOneWidget);
    });

    testWidgets('switching tab to Tugas renders OperatorTugasScreen', (tester) async {
      tester.view.physicalSize = const Size(412, 1400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      await tester.pumpWidget(createWidgetUnderTest(const OperatorDashboardScreen()));
      await tester.pumpAndSettle();

      // Tap "Tugas" bottom nav item
      await tester.tap(find.text('Tugas'));
      await tester.pumpAndSettle();

      // Now we should see the Tugas page elements
      expect(find.text('Cari ID, judul, lokasi, atau pelapor...'), findsOneWidget);
      expect(find.text('Semua Prioritas'), findsOneWidget);
      expect(find.text('Lihat Tugas'), findsWidgets);
    });
  });

  group('Operator Page Tugas (Figma 662:5680)', () {
    testWidgets('renders search, filter pills, and task cards with Lihat Tugas',
        (tester) async {
      tester.view.physicalSize = const Size(412, 1400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      await tester.pumpWidget(createWidgetUnderTest(const OperatorTugasScreen()));
      await tester.pumpAndSettle();

      expect(find.text('Tugas'), findsOneWidget);
      expect(find.text('Cari ID, judul, lokasi, atau pelapor...'), findsOneWidget);
      expect(find.text('Filter'), findsOneWidget);
      expect(find.text('Semua Prioritas'), findsOneWidget);

      // Check task cards
      expect(find.text('Jalan Rusak'), findsOneWidget);
      expect(find.text('Jl. Ahmad Yani no. 15'), findsWidgets);
      expect(find.text('#LP_2026_0024487'), findsWidgets);
      expect(find.text('Lihat Tugas'), findsWidgets);
    });
  });

  group('Operator Detail Laporan (Figma 662:6373)', () {
    testWidgets('renders report header, description, status dropdown, metadata table, and action button',
        (tester) async {
      tester.view.physicalSize = const Size(412, 1600);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      await tester.pumpWidget(
        createWidgetUnderTest(
          OperatorReportDetailScreen(report: testReports[0]),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Detail Laporan'), findsOneWidget);
      expect(find.text('#LP_2026_0024487'), findsWidgets);
      expect(find.text('Jalan Rusak'), findsWidgets);
      expect(find.text('Prioritas Tinggi'), findsWidgets);

      // Description
      expect(find.text('Deskripsi :'), findsOneWidget);

      // Status Pengerjaan
      expect(find.text('Status Pengerjaan'), findsOneWidget);

      // Metadata Table
      expect(find.text('Laporan dibuat'), findsOneWidget);
      expect(find.text('Pelapor'), findsOneWidget);
      expect(find.text('Budi Santoso'), findsOneWidget);
      expect(find.text('Kategori'), findsOneWidget);
      expect(find.text('Prioritas AI'), findsOneWidget);
      expect(find.text('OPD Tujuan'), findsOneWidget);
      expect(find.text('Dinas PUPR'), findsOneWidget);
      expect(find.text('Koordinat'), findsOneWidget);

      // Map Button
      expect(find.text('Navigasi ke lokasi'), findsOneWidget);

      // Bottom Action Button
      expect(find.text('Mulai Pengerjaan'), findsOneWidget);
    });
  });
}
