import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:laporkita/core/network/api_response.dart';
import 'package:laporkita/data/models/auth_token_model.dart';
import 'package:laporkita/data/models/report_model.dart';
import 'package:laporkita/data/models/user_model.dart';
import 'package:laporkita/data/repositories/report_repository.dart';
import 'package:laporkita/presentation/auth/bloc/auth_bloc.dart';
import 'package:laporkita/presentation/command_center/dashboard/government_dashboard_screen.dart';

class TestAuthBloc extends Bloc<AuthEvent, AuthState> implements AuthBloc {
  TestAuthBloc(super.initialState);
}

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

Widget buildGovernmentTestWidget({
  UserModel? user,
}) {
  final officialUser = user ??
      const UserModel(
        id: 'usr-gov-1',
        fullName: 'Nabil',
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
  final fakeReportRepo = FakeReportRepository();

  return MaterialApp(
    home: MultiRepositoryProvider(
      providers: [
        RepositoryProvider<ReportRepository>.value(value: fakeReportRepo),
      ],
      child: BlocProvider<AuthBloc>.value(
        value: authBloc,
        child: const GovernmentDashboardScreen(),
      ),
    ),
  );
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Figma Node 475:5338 & 484:7833 Government Dashboard Tests', () {
    testWidgets('Renders Header, Stat Cards, Kondisi Hari Ini, OPD & Mini Map',
        (tester) async {
      tester.view.physicalSize = const Size(412, 1200);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      await tester.pumpWidget(buildGovernmentTestWidget());
      await tester.pumpAndSettle();

      // 1. Header elements
      expect(find.textContaining('Hallo!, selamat pagi'), findsOneWidget);
      expect(find.textContaining('Pantau kinerja penanganan laporan hari ini'),
          findsOneWidget);
      expect(find.byIcon(Icons.notifications_rounded), findsOneWidget);

      // 2. 2x2 Stat Cards
      expect(find.text('Total Laporan'), findsOneWidget);
      expect(find.text('2.458'), findsOneWidget);
      expect(find.text('Sedang Diproses'), findsOneWidget);
      expect(find.text('1.286'), findsOneWidget);
      expect(find.text('Selesai'), findsWidgets);
      expect(find.text('1.072'), findsOneWidget);
      expect(find.text('Rata- rata respon'), findsOneWidget);
      expect(find.text('2,4 jam'), findsOneWidget);

      // 3. Kondisi Hari Ini section
      expect(find.text('Kondisi Hari Ini'), findsOneWidget);
      expect(find.text('Proses'), findsOneWidget);
      expect(find.text('Prioritas'), findsOneWidget);

      // 4. Kinerja per OPD section
      expect(find.text('Kinerja per OPD'), findsOneWidget);
      expect(find.text('Lihat semua'), findsOneWidget);
      expect(find.text('Dinas PUPR'), findsOneWidget);
      expect(find.text('Dinas Perhubungan'), findsOneWidget);
      expect(find.text('Dinas PU SDA'), findsOneWidget);
      expect(find.text('Dinas Lingkungan'), findsOneWidget);
      expect(find.text('Dinas Pertamanan'), findsOneWidget);

      // 5. Peta sebaran laporan section (Real interactive FlutterMap)
      expect(find.text('Peta sebaran laporan'), findsOneWidget);
      expect(find.text('Lihat peta lengkap'), findsOneWidget);
      expect(find.byType(FlutterMap), findsOneWidget);

      // 6. AI Policy Intelligence Tools removed from dashboard
      expect(find.text('AI Policy Intelligence Tools'), findsNothing);
      expect(find.text('Policy Simulator'), findsNothing);
    });

    testWidgets('Renders 5-item Bottom Navigation Bar matching Figma 484:7833',
        (tester) async {
      tester.view.physicalSize = const Size(412, 1000);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      await tester.pumpWidget(buildGovernmentTestWidget());
      await tester.pumpAndSettle();

      // Verify all 5 navbar labels exist
      expect(find.text('Dashboard'), findsOneWidget);
      expect(find.text('Ringkasan'), findsOneWidget);
      expect(find.text('Laporan'), findsOneWidget);
      expect(find.text('Monitoring'), findsOneWidget);
      expect(find.text('Profile'), findsOneWidget);

      // Tap on Ringkasan tab
      await tester.tap(find.text('Ringkasan'));
      await tester.pumpAndSettle();

      // Tap on Monitoring tab
      await tester.tap(find.text('Monitoring'));
      await tester.pumpAndSettle();

      // Tap on Dashboard tab
      await tester.tap(find.text('Dashboard'));
      await tester.pumpAndSettle();
      expect(find.text('Total Laporan'), findsOneWidget);
    });

    testWidgets('Quick navigation from OPD and Map works', (tester) async {
      tester.view.physicalSize = const Size(412, 1200);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      await tester.pumpWidget(buildGovernmentTestWidget());
      await tester.pumpAndSettle();

      // Scroll to and tap 'Lihat peta lengkap' to switch to Monitoring
      await tester.scrollUntilVisible(
        find.text('Lihat peta lengkap'),
        200,
        scrollable: find.byType(Scrollable).first,
      );
      await tester.tap(find.text('Lihat peta lengkap'), warnIfMissed: false);
      await tester.pumpAndSettle();

      // Return to Dashboard tab
      await tester.tap(find.text('Dashboard'));
      await tester.pumpAndSettle();

      // Scroll to and tap 'Lihat semua' to switch to Ringkasan
      await tester.scrollUntilVisible(
        find.text('Lihat semua'),
        200,
        scrollable: find.byType(Scrollable).first,
      );
      await tester.tap(find.text('Lihat semua'), warnIfMissed: false);
      await tester.pumpAndSettle();
    });
  });
}
