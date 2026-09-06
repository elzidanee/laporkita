import 'package:flutter_test/flutter_test.dart';
import 'package:laporkita/core/network/api_exception.dart';
import 'package:laporkita/data/models/user_model.dart';
import 'package:laporkita/data/repositories/auth_repository.dart';
import 'package:laporkita/presentation/auth/bloc/auth_bloc.dart';

class FakeAuthRepository extends Fake implements AuthRepository {
  bool hasToken = true;
  String? token = 'valid_jwt_token_xyz';
  UserModel? currentUser;
  UserModel? cachedUser;
  bool logoutCalled = false;
  Exception? getMeException;

  FakeAuthRepository({
    this.hasToken = true,
    this.token = 'valid_jwt_token_xyz',
    this.currentUser,
    this.cachedUser,
    this.getMeException,
  }) {
    currentUser ??= UserModel(
      id: 'usr-100',
      fullName: 'Budi Prakoso',
      email: 'budi@laporkita.id',
      phoneNumber: '081234567890',
      role: UserRole.citizen,
      contributionPoints: 25,
    );
    cachedUser ??= currentUser;
  }

  @override
  Future<bool> isLoggedIn() async => hasToken;

  @override
  Future<String?> getAccessToken() async => token;

  @override
  Future<UserModel> getMe() async {
    if (getMeException != null) throw getMeException!;
    return currentUser!;
  }

  @override
  Future<UserModel?> getCachedUser() async => cachedUser;

  @override
  Future<void> logout() async {
    logoutCalled = true;
    hasToken = false;
    token = null;
    cachedUser = null;
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('AuthBloc P0-03 Offline Session Wipe & Auth Lifecycle Tests', () {
    test('ONLINE: Valid token and server reachable emits AuthAuthenticated and keeps session', () async {
      final repo = FakeAuthRepository();
      final bloc = AuthBloc(authRepository: repo);

      final states = <AuthState>[];
      bloc.stream.listen(states.add);

      bloc.add(const AuthCheckRequested());
      await Future.delayed(const Duration(milliseconds: 50));

      expect(repo.logoutCalled, isFalse);
      expect(states.length, equals(2));
      expect(states[0], isA<AuthLoading>());
      expect(states[1], isA<AuthAuthenticated>());

      final authState = states[1] as AuthAuthenticated;
      expect(authState.user.fullName, equals('Budi Prakoso'));
      expect(authState.tokens.accessToken, equals('valid_jwt_token_xyz'));

      await bloc.close();
    });

    test('E. OFFLINE STARTUP: NetworkException preserves token and emits AuthAuthenticated from cache', () async {
      final repo = FakeAuthRepository(
        getMeException: const NetworkException(
          'Tidak dapat terhubung ke server. Periksa koneksi internet Anda.',
        ),
      );
      final bloc = AuthBloc(authRepository: repo);

      final states = <AuthState>[];
      bloc.stream.listen(states.add);

      bloc.add(const AuthCheckRequested());
      await Future.delayed(const Duration(milliseconds: 50));

      // CRITICAL CHECK: Token must NOT be wiped!
      expect(repo.logoutCalled, isFalse);
      expect(states.length, equals(2));
      expect(states[0], isA<AuthLoading>());
      expect(states[1], isA<AuthAuthenticated>());

      final authState = states[1] as AuthAuthenticated;
      expect(authState.user.fullName, equals('Budi Prakoso'));
      expect(authState.tokens.accessToken, equals('valid_jwt_token_xyz'));

      await bloc.close();
    });

    test('F. TIMEOUT STARTUP: Network timeout does NOT wipe token, keeps offline session', () async {
      final repo = FakeAuthRepository(
        getMeException: const NetworkException('Waktu koneksi habis. Coba lagi.'),
      );
      final bloc = AuthBloc(authRepository: repo);

      final states = <AuthState>[];
      bloc.stream.listen(states.add);

      bloc.add(const AuthCheckRequested());
      await Future.delayed(const Duration(milliseconds: 50));

      // Token must NOT be wiped!
      expect(repo.logoutCalled, isFalse);
      expect(states.length, equals(2));
      expect(states[0], isA<AuthLoading>());
      expect(states[1], isA<AuthAuthenticated>());

      await bloc.close();
    });

    test('G. SERVER UNAVAILABLE: 500/502/503/504 errors do NOT wipe token, session stays intact', () async {
      for (final statusCode in [500, 502, 503, 504]) {
        final repo = FakeAuthRepository(
          getMeException: ApiException(
            code: statusCode == 502
                ? 'BAD_GATEWAY'
                : statusCode == 503
                    ? 'SERVICE_UNAVAILABLE'
                    : statusCode == 504
                        ? 'GATEWAY_TIMEOUT'
                        : 'INTERNAL_ERROR',
            message: 'Server error $statusCode',
            statusCode: statusCode,
          ),
        );
        final bloc = AuthBloc(authRepository: repo);

        final states = <AuthState>[];
        bloc.stream.listen(states.add);

        bloc.add(const AuthCheckRequested());
        await Future.delayed(const Duration(milliseconds: 50));

        // Token must NOT be wiped on server error!
        expect(repo.logoutCalled, isFalse, reason: 'Failed on status $statusCode');
        expect(states.last, isA<AuthAuthenticated>(), reason: 'Failed on status $statusCode');

        await bloc.close();
      }
    });

    test('H. INVALID TOKEN: Explicit 401 / unauthorized from server WIPES token and logs out', () async {
      final repo = FakeAuthRepository(
        getMeException: const ApiException(
          code: 'UNAUTHORIZED',
          message: 'Token kedaluwarsa atau tidak valid.',
          statusCode: 401,
        ),
      );
      final bloc = AuthBloc(authRepository: repo);

      final states = <AuthState>[];
      bloc.stream.listen(states.add);

      bloc.add(const AuthCheckRequested());
      await Future.delayed(const Duration(milliseconds: 50));

      // Token MUST be wiped when confirmed invalid!
      expect(repo.logoutCalled, isTrue);
      expect(states.length, equals(2));
      expect(states[0], isA<AuthLoading>());
      expect(states[1], isA<AuthUnauthenticated>());

      await bloc.close();
    });

    test('I. EXPLICIT LOGOUT: AuthLogoutRequested clears storage and emits AuthUnauthenticated', () async {
      final repo = FakeAuthRepository();
      final bloc = AuthBloc(authRepository: repo);

      final states = <AuthState>[];
      bloc.stream.listen(states.add);

      bloc.add(const AuthLogoutRequested());
      await Future.delayed(const Duration(milliseconds: 50));

      // Token MUST be wiped on explicit user logout!
      expect(repo.logoutCalled, isTrue);
      expect(states.length, equals(1));
      expect(states[0], isA<AuthUnauthenticated>());

      await bloc.close();
    });
  });
}
