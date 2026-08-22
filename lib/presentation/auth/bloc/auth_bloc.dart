export 'auth_event.dart';

import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../data/repositories/auth_repository.dart';
import '../../../data/models/auth_token_model.dart';
import '../../../core/network/api_exception.dart';
import 'auth_event.dart';

class AuthBloc extends Bloc<AuthEvent, AuthState> {
  final AuthRepository _authRepository;

  AuthBloc({AuthRepository? authRepository})
      : _authRepository = authRepository ?? AuthRepository(),
        super(const AuthInitial()) {
    on<AuthCheckRequested>(_onCheckRequested);
    on<AuthRegisterRequested>(_onRegisterRequested);
    on<AuthVerifyOtpRequested>(_onVerifyOtpRequested);
    on<AuthResendOtpRequested>(_onResendOtpRequested);
    on<AuthLoginRequested>(_onLoginRequested);
    on<AuthLogoutRequested>(_onLogoutRequested);
  }

  /// Cek token saat splash screen — auto-login jika token ada & valid
  Future<void> _onCheckRequested(
    AuthCheckRequested event,
    Emitter<AuthState> emit,
  ) async {
    emit(const AuthLoading());
    try {
      final isLoggedIn = await _authRepository.isLoggedIn();
      if (isLoggedIn) {
        // Verifikasi token masih valid dengan ambil profil user
        final user = await _authRepository.getMe();
        final accessToken = await _authRepository.getAccessToken() ?? '';
        emit(AuthAuthenticated(
          user: user,
          tokens: AuthTokenModel(
            accessToken: accessToken,
            refreshToken: '',
            expiresIn: '15m',
            tokenType: 'Bearer',
            user: user,
          ),
        ));
      } else {
        emit(const AuthUnauthenticated());
      }
    } catch (_) {
      // Token expired / invalid — paksa logout
      await _authRepository.logout();
      emit(const AuthUnauthenticated());
    }
  }

  /// Register citizen baru
  Future<void> _onRegisterRequested(
    AuthRegisterRequested event,
    Emitter<AuthState> emit,
  ) async {
    emit(const AuthLoading());
    try {
      final result = await _authRepository.register(
        fullName: event.fullName,
        email: event.email,
        phoneNumber: event.phoneNumber,
        password: event.password,
      );
      emit(AuthRegistered(
        userId: result.userId,
        phoneNumber: result.phoneNumber ?? event.phoneNumber,
        email: result.email ?? event.email,
        message: result.message,
      ));
    } on ApiException catch (e) {
      emit(AuthError(code: e.code, message: e.userMessage));
    } on NetworkException catch (e) {
      emit(AuthError(code: 'NETWORK_ERROR', message: e.message));
    } catch (e) {
      emit(AuthError(code: 'UNKNOWN', message: e.toString()));
    }
  }

  /// Verifikasi OTP — CONFIRMED mengembalikan token langsung (auto-login setelah verify)
  Future<void> _onVerifyOtpRequested(
    AuthVerifyOtpRequested event,
    Emitter<AuthState> emit,
  ) async {
    emit(const AuthLoading());
    try {
      final tokens = await _authRepository.verifyOtp(
        userId: event.userId,
        phoneNumber: event.phoneNumber,
        otpCode: event.otpCode,
      );
      emit(AuthAuthenticated(user: tokens.user, tokens: tokens));
    } on ApiException catch (e) {
      emit(AuthError(code: e.code, message: e.userMessage));
    } on NetworkException catch (e) {
      emit(AuthError(code: 'NETWORK_ERROR', message: e.message));
    } catch (e) {
      emit(AuthError(code: 'UNKNOWN', message: e.toString()));
    }
  }

  /// Kirim ulang OTP
  Future<void> _onResendOtpRequested(
    AuthResendOtpRequested event,
    Emitter<AuthState> emit,
  ) async {
    emit(const AuthLoading());
    try {
      final result = await _authRepository.resendOtp(
        userId: event.userId,
        phoneNumber: event.phoneNumber,
      );
      emit(AuthOtpResent(
        cooldownSeconds: result['cooldown_seconds'] as int? ?? 45,
        message: result['message'] as String? ?? 'OTP baru telah dikirim.',
      ));
    } on ApiException catch (e) {
      emit(AuthError(code: e.code, message: e.userMessage));
    } on NetworkException catch (e) {
      emit(AuthError(code: 'NETWORK_ERROR', message: e.message));
    } catch (e) {
      emit(AuthError(code: 'UNKNOWN', message: e.toString()));
    }
  }

  /// Login — handle PHONE_NOT_VERIFIED sebagai kasus khusus (sesuai intruksi.md §3.3)
  Future<void> _onLoginRequested(
    AuthLoginRequested event,
    Emitter<AuthState> emit,
  ) async {
    emit(const AuthLoading());
    try {
      final tokens = await _authRepository.login(
        identifier: event.identifier,
        password: event.password,
      );
      emit(AuthAuthenticated(user: tokens.user, tokens: tokens));
    } on ApiException catch (e) {
      // KASUS KHUSUS: redirect ke OTP screen dengan nomor yang dipakai
      if (e.isPhoneNotVerified) {
        emit(AuthPhoneNotVerified(phoneNumber: event.identifier));
      } else {
        emit(AuthError(code: e.code, message: e.userMessage));
      }
    } on NetworkException catch (e) {
      emit(AuthError(code: 'NETWORK_ERROR', message: e.message));
    } catch (e) {
      emit(AuthError(code: 'UNKNOWN', message: e.toString()));
    }
  }

  Future<void> _onLogoutRequested(
    AuthLogoutRequested event,
    Emitter<AuthState> emit,
  ) async {
    await _authRepository.logout();
    emit(const AuthUnauthenticated());
  }
}
