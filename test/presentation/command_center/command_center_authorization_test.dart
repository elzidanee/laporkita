import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:laporkita/core/network/api_response.dart';
import 'package:laporkita/data/models/auth_token_model.dart';
import 'package:laporkita/data/models/report_model.dart';
import 'package:laporkita/data/models/user_model.dart';
import 'package:laporkita/data/repositories/report_repository.dart';
import 'package:laporkita/presentation/auth/bloc/auth_bloc.dart';
import 'package:laporkita/presentation/command_center/dashboard/dashboard_screen.dart';
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

Widget buildTestWidget({
  required AuthState authState,
  UserRole? initialRole,
}) {
  final authBloc = TestAuthBloc(authState);
  final fakeReportRepo = FakeReportRepository();

  return MaterialApp(
    home: MultiRepositoryProvider(
      providers: [
        RepositoryProvider<ReportRepository>.value(value: fakeReportRepo),
      ],
      child: BlocProvider<AuthBloc>.value(
        value: authBloc,
        child: CommandCenterDashboard(initialRole: initialRole),
      ),
    ),
  );
}

void main() {
  group('P2-01 CommandCenter Authorization & RBAC Tests', () {
    testWidgets(
        'Unauthenticated access is blocked and prompts login without rendering government dashboard',
        (tester) async {
      await tester.pumpWidget(
        buildTestWidget(authState: const AuthUnauthenticated()),
      );
      await tester.pumpAndSettle();

      // Verify authentication requirement is shown
      expect(find.text('Autentikasi Diperlukan'), findsOneWidget);
      expect(find.text('Sesi Belum Terautentikasi'), findsOneWidget);
      expect(find.text('Masuk ke Akun Petugas'), findsOneWidget);

      // Verify privileged Government Dashboard is NOT rendered
      expect(find.byType(GovernmentDashboardScreen), findsNothing);
    });

    testWidgets(
        'Citizen role is blocked with restricted access screen and cannot access government dashboard',
        (tester) async {
      const citizenUser = UserModel(
        id: 'usr-cit-1',
        fullName: 'Warga Biasa',
        role: UserRole.citizen,
        contributionPoints: 10,
      );

      const tokens = AuthTokenModel(
        accessToken: 'access_xyz',
        refreshToken: 'refresh_xyz',
        expiresIn: '3600',
        tokenType: 'Bearer',
        user: citizenUser,
      );

      await tester.pumpWidget(
        buildTestWidget(
          authState: const AuthAuthenticated(
            user: citizenUser,
            tokens: tokens,
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Verify access restriction is displayed
      expect(find.text('Akses Dibatasi'), findsOneWidget);
      expect(find.text('Akses Khusus Aparat & Pemerintah'), findsOneWidget);
      expect(find.text('Kembali ke Beranda Warga'), findsOneWidget);

      // Verify privileged Government Dashboard is NOT rendered
      expect(find.byType(GovernmentDashboardScreen), findsNothing);
    });

    testWidgets(
        'Authorized policy maker role successfully renders GovernmentDashboardScreen',
        (tester) async {
      const officialUser = UserModel(
        id: 'usr-gov-1',
        fullName: 'Pejabat Pembuat Kebijakan',
        role: UserRole.policyMaker,
        contributionPoints: 100,
      );

      const tokens = AuthTokenModel(
        accessToken: 'access_xyz',
        refreshToken: 'refresh_xyz',
        expiresIn: '3600',
        tokenType: 'Bearer',
        user: officialUser,
      );

      await tester.pumpWidget(
        buildTestWidget(
          authState: const AuthAuthenticated(
            user: officialUser,
            tokens: tokens,
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Verify GovernmentDashboardScreen is rendered
      expect(find.byType(GovernmentDashboardScreen), findsOneWidget);
      expect(find.text('Autentikasi Diperlukan'), findsNothing);
      expect(find.text('Akses Dibatasi'), findsNothing);
    });
  });
}
