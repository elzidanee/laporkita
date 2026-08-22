import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:laporkita/core/network/dio_client.dart';
import 'package:laporkita/core/config/app_config.dart';
import 'package:laporkita/data/models/auth_token_model.dart';
import 'package:laporkita/data/models/user_model.dart';

/// Auth Remote Datasource — semua panggilan API ke modul /auth
/// STATUS: VERIFIED — endpoint dari backend/src/modules/auth/auth.controller.ts
class AuthRemoteDatasource {
  final DioClient _dioClient;
  final FlutterSecureStorage _storage;

  AuthRemoteDatasource({
    DioClient? dioClient,
    FlutterSecureStorage? storage,
  })  : _dioClient = dioClient ?? DioClient(),
        _storage = storage ?? const FlutterSecureStorage();

  // ── Register ───────────────────────────────────────────────────────────────
  // STATUS: VERIFIED — POST /auth/register
  Future<RegisterResponseModel> register({
    required String fullName,
    required String email,
    required String phoneNumber,
    required String password,
  }) async {
    final response = await _dioClient.post<RegisterResponseModel>(
      '/auth/register',
      fromJson: (json) =>
          RegisterResponseModel.fromJson(json as Map<String, dynamic>),
      data: {
        'full_name': fullName,
        'email': email,
        'phone_number': phoneNumber,
        'password': password,
      },
    );
    return response.data!;
  }

  // ── Verify OTP ─────────────────────────────────────────────────────────────
  // STATUS: VERIFIED — POST /auth/verify-otp
  Future<AuthTokenModel> verifyOtp({
    String? userId,
    String? phoneNumber,
    required String otpCode,
  }) async {
    final response = await _dioClient.post<AuthTokenModel>(
      '/auth/verify-otp',
      fromJson: (json) =>
          AuthTokenModel.fromJson(json as Map<String, dynamic>),
      data: {
        if (userId case final u?) 'user_id': u,
        if (phoneNumber case final p?) 'phone_number': p,
        'otp_code': otpCode,
      },
    );
    return response.data!;
  }

  // ── Resend OTP ─────────────────────────────────────────────────────────────
  // STATUS: VERIFIED — POST /auth/resend-otp
  Future<Map<String, dynamic>> resendOtp({
    String? userId,
    String? phoneNumber,
  }) async {
    final response = await _dioClient.post<Map<String, dynamic>>(
      '/auth/resend-otp',
      fromJson: (json) => json as Map<String, dynamic>,
      data: {
        if (userId case final u?) 'user_id': u,
        if (phoneNumber case final p?) 'phone_number': p,
      },
    );
    return response.data!;
  }

  // ── Login ──────────────────────────────────────────────────────────────────
  // STATUS: VERIFIED — POST /auth/login
  Future<AuthTokenModel> login({
    required String identifier,
    required String password,
  }) async {
    final response = await _dioClient.post<AuthTokenModel>(
      '/auth/login',
      fromJson: (json) =>
          AuthTokenModel.fromJson(json as Map<String, dynamic>),
      data: {
        'identifier': identifier,
        'password': password,
      },
    );
    return response.data!;
  }

  // ── Refresh Token ──────────────────────────────────────────────────────────
  // STATUS: VERIFIED — POST /auth/refresh
  Future<AuthTokenModel> refreshToken(String refreshToken) async {
    final response = await _dioClient.post<AuthTokenModel>(
      '/auth/refresh',
      fromJson: (json) =>
          AuthTokenModel.fromJson(json as Map<String, dynamic>),
      data: {'refresh_token': refreshToken},
    );
    return response.data!;
  }

  // ── Get Current User Profile ───────────────────────────────────────────────
  // STATUS: VERIFIED — GET /users/me
  Future<UserModel> getMe() async {
    final response = await _dioClient.get<UserModel>(
      '/users/me',
      fromJson: (json) => UserModel.fromJson(json as Map<String, dynamic>),
    );
    return response.data!;
  }

  // ── Token Storage Helpers ─────────────────────────────────────────────────

  Future<void> saveTokens(AuthTokenModel tokens) async {
    await Future.wait([
      _storage.write(
          key: AppConfig.accessTokenKey, value: tokens.accessToken),
      _storage.write(
          key: AppConfig.refreshTokenKey, value: tokens.refreshToken),
      _storage.write(key: AppConfig.userIdKey, value: tokens.user.id),
      _storage.write(
          key: AppConfig.userRoleKey, value: tokens.user.role.name),
    ]);
  }

  Future<void> clearTokens() async {
    await Future.wait([
      _storage.delete(key: AppConfig.accessTokenKey),
      _storage.delete(key: AppConfig.refreshTokenKey),
      _storage.delete(key: AppConfig.userIdKey),
      _storage.delete(key: AppConfig.userRoleKey),
    ]);
  }

  Future<String?> getAccessToken() =>
      _storage.read(key: AppConfig.accessTokenKey);

  Future<String?> getRefreshToken() =>
      _storage.read(key: AppConfig.refreshTokenKey);

  Future<bool> hasValidToken() async {
    final token = await getAccessToken();
    return token != null && token.isNotEmpty;
  }
}
