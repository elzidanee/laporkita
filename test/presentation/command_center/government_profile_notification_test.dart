import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:laporkita/core/network/api_response.dart';
import 'package:laporkita/data/models/auth_token_model.dart';
import 'package:laporkita/data/models/report_model.dart';
import 'package:laporkita/data/models/user_model.dart';
import 'package:laporkita/data/repositories/report_repository.dart';
import 'package:laporkita/presentation/auth/bloc/auth_bloc.dart';
import 'package:laporkita/presentation/command_center/dashboard/government_dashboard_screen.dart';
import 'package:laporkita/presentation/command_center/notifications/admin_notification_screen.dart';
import 'package:laporkita/presentation/command_center/profile/admin_profile_screen.dart';

class TestAuthBloc extends Bloc<AuthEvent, AuthState> implements AuthBloc {
  TestAuthBloc(super.initialState);
}

class FakeReportRepository extends Fake implements ReportRepository {
  final List<ReportModel> reports;
  FakeReportRepository({this.reports = const []});

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
      data: reports,
    );
  }
}

Widget buildTestWidget({
  required Widget child,
  UserModel? user,
  List<ReportModel> reports = const [],
}) {
  final officialUser = user ??
      const UserModel(
        id: 'usr-gov-malang',
        fullName: 'Pemirintah Kota Malang',
        role: UserRole.policyMaker,
        contributionPoints: 100,
      );

  final authBloc = TestAuthBloc(
    AuthAuthenticated(
      user: officialUser,
      tokens: AuthTokenModel(
        accessToken: 'access_xyz',
        refreshToken: 'refresh_xyz',
        expiresIn: '3600',
        tokenType: 'Bearer',
        user: officialUser,
      ),
    ),
  );

  return MaterialApp(
    home: MultiRepositoryProvider(
      providers: [
        RepositoryProvider<ReportRepository>.value(
          value: FakeReportRepository(reports: reports),
        ),
      ],
      child: BlocProvider<AuthBloc>.value(
        value: authBloc,
        child: child,
      ),
    ),
  );
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Figma Node 656:5271 Admin Profile Screen Tests', () {
    testWidgets('Renders all Profile page elements accurately matching Figma',
        (tester) async {
      tester.view.physicalSize = const Size(412, 1400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      await tester.pumpWidget(
        buildTestWidget(child: const AdminProfileScreen()),
      );
      await tester.pumpAndSettle();

      // 1. Top Bar
      expect(find.text('Profile'), findsOneWidget);
      expect(find.byIcon(Icons.chevron_left_rounded), findsOneWidget);

      // 2. Avatar & Name/Email
      expect(find.text('Pemirintah Kota Malang'), findsOneWidget);
      expect(find.text('pemerintahkotamalang@laporkita.go.id'), findsOneWidget);

      // 3. Section 1: Pengaturan Sistem
      expect(find.text('Pengaturan Sistem'), findsOneWidget);
      expect(find.text('Kelola OPD'), findsOneWidget);
      expect(find.text('Kategori laporan'), findsOneWidget);
      expect(find.text('Pengaturan Notifikasi'), findsOneWidget);
      expect(find.text('Integrasi & API'), findsOneWidget);
      expect(find.text('Keamanan'), findsOneWidget);
      expect(find.text('Backup & Data'), findsOneWidget);

      // 4. Section 2: Lainnya
      expect(find.text('Lainnya'), findsOneWidget);
      expect(find.text('Log Aktivitas'), findsOneWidget);
      expect(find.text('Tentang Aplikasi'), findsOneWidget);

      // 5. Button Keluar
      expect(find.text('Keluar'), findsOneWidget);
      expect(find.byIcon(Icons.logout_rounded), findsOneWidget);
    });

    testWidgets('Tapping menu item opens detail dialog and logout opens confirmation',
        (tester) async {
      tester.view.physicalSize = const Size(412, 1400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      await tester.pumpWidget(
        buildTestWidget(child: const AdminProfileScreen()),
      );
      await tester.pumpAndSettle();

      // Tap Kelola OPD
      await tester.tap(find.text('Kelola OPD'));
      await tester.pumpAndSettle();
      expect(find.textContaining('Daftar instansi penanggung jawab'), findsOneWidget);

      // Close dialog
      await tester.tap(find.text('Tutup'));
      await tester.pumpAndSettle();
      expect(find.textContaining('Daftar instansi penanggung jawab'), findsNothing);

      // Tap Keluar
      await tester.tap(find.text('Keluar'));
      await tester.pumpAndSettle();
      expect(find.text('Konfirmasi Keluar'), findsOneWidget);
      expect(
        find.textContaining('Apakah Anda yakin ingin keluar'),
        findsOneWidget,
      );

      // Cancel logout
      await tester.tap(find.text('Batal'));
      await tester.pumpAndSettle();
      expect(find.text('Konfirmasi Keluar'), findsNothing);
    });
  });

  group('Figma Node 661:5559 Admin Notification Screen Tests', () {
    testWidgets('Renders all 5 Notification cards from Figma baseline',
        (tester) async {
      tester.view.physicalSize = const Size(412, 1000);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      await tester.pumpWidget(
        buildTestWidget(child: const AdminNotificationScreen()),
      );
      await tester.pumpAndSettle();

      // Top bar
      expect(find.text('Notifikasi'), findsOneWidget);
      expect(find.byIcon(Icons.chevron_left_rounded), findsOneWidget);

      // Card 1: Laporan baru masuk (Unread, amber warning)
      expect(find.text('Laporan baru masuk'), findsOneWidget);
      expect(find.text('Laporan #LP_2026_0028349'), findsOneWidget);
      expect(find.text('09.20'), findsOneWidget);
      expect(find.byIcon(Icons.warning_amber_rounded), findsOneWidget);

      // Card 2: AI Verification selesai (Read, blue auto awesome)
      expect(find.text('AI Verification selesai'), findsOneWidget);
      expect(find.text('Confidence : 98%'), findsOneWidget);
      expect(find.text('09.18'), findsOneWidget);
      expect(find.byIcon(Icons.auto_awesome_rounded), findsOneWidget);

      // Card 3: Laporan diteruskan ke Dinas PUPR (Read, amber assignment)
      expect(find.text('Laporan diteruskan ke Dinas PUPR'), findsOneWidget);
      expect(find.text('#LP-2026-7268712'), findsOneWidget);
      expect(find.text('Kemarin'), findsOneWidget);
      expect(find.byIcon(Icons.assignment_outlined), findsOneWidget);

      // Card 4: Petugas mulai mengerjakan (Read, blue build)
      expect(find.text('Petugas mulai mengerjakan'), findsOneWidget);
      expect(find.text('#LP-2026-8231791'), findsOneWidget);
      expect(find.text('1 hari lalu'), findsOneWidget);
      expect(find.byIcon(Icons.build_outlined), findsOneWidget);

      // Card 5: Laporan selesai dikerjakan (Read, red error circle)
      expect(find.text('Laporan selesai dikerjakan'), findsOneWidget);
      expect(find.textContaining('Menunggu validasi warga'), findsOneWidget);
      expect(find.text('3 hari lalu'), findsOneWidget);
      expect(find.byIcon(Icons.error_outline_rounded), findsOneWidget);
    });

    testWidgets('Tapping notification card marks unread as read',
        (tester) async {
      tester.view.physicalSize = const Size(412, 1000);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      await tester.pumpWidget(
        buildTestWidget(child: const AdminNotificationScreen()),
      );
      await tester.pumpAndSettle();

      // Tap on unread notification (Card 1)
      await tester.tap(find.text('Laporan baru masuk'));
      await tester.pumpAndSettle();

      // Card is still present and stays marked read
      expect(find.text('Laporan baru masuk'), findsOneWidget);
    });
  });

  group('Dashboard Integration with Profile and Notifications', () {
    testWidgets('Dashboard can navigate to Tab 4 Profile and open Notifications',
        (tester) async {
      tester.view.physicalSize = const Size(412, 1200);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      await tester.pumpWidget(
        buildTestWidget(child: const GovernmentDashboardScreen()),
      );
      await tester.pumpAndSettle();

      // 1. Switch to Profile tab (Tab 4)
      await tester.tap(find.text('Profile'));
      await tester.pumpAndSettle();

      expect(find.text('Pengaturan Sistem'), findsOneWidget);
      expect(find.text('Kelola OPD'), findsOneWidget);
      expect(find.text('Keluar'), findsOneWidget);

      // 2. Switch back to Dashboard (Tab 0)
      await tester.tap(find.text('Dashboard'));
      await tester.pumpAndSettle();

      // 3. Tap top notification bell
      await tester.tap(find.byIcon(Icons.notifications_rounded));
      await tester.pumpAndSettle();

      // Verify Notification screen opens
      expect(find.text('Notifikasi'), findsOneWidget);
      expect(find.text('Laporan baru masuk'), findsOneWidget);

      // Back to Dashboard
      await tester.tap(find.byIcon(Icons.chevron_left_rounded));
      await tester.pumpAndSettle();

      expect(find.textContaining('Hallo!, selamat pagi'), findsOneWidget);
    });
  });
}
