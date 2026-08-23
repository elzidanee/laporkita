import '../datasources/remote/auth_remote_datasource.dart';
import '../models/auth_token_model.dart';
import '../models/user_model.dart';

/// Auth Repository — layer antara datasource dan domain/BLoC
/// Mengelola token storage dan meneruskan panggilan ke datasource
class AuthRepository {
  final AuthRemoteDatasource _datasource;

  AuthRepository({AuthRemoteDatasource? datasource})
      : _datasource = datasource ?? AuthRemoteDatasource();

  Future<RegisterResponseModel> register({
    required String fullName,
    required String email,
    required String phoneNumber,
    required String password,
  }) {
    return _datasource.register(
      fullName: fullName,
      email: email,
      phoneNumber: phoneNumber,
      password: password,
    );
  }

  Future<AuthTokenModel> verifyOtp({
    String? userId,
    String? phoneNumber,
    required String otpCode,
  }) async {
    final tokens = await _datasource.verifyOtp(
      userId: userId,
      phoneNumber: phoneNumber,
      otpCode: otpCode,
    );
    await _datasource.saveTokens(tokens);
    return tokens;
  }

  Future<Map<String, dynamic>> resendOtp({
    String? userId,
    String? phoneNumber,
  }) {
    return _datasource.resendOtp(
      userId: userId,
      phoneNumber: phoneNumber,
    );
  }

  Future<AuthTokenModel> login({
    required String identifier,
    required String password,
  }) async {
    final tokens = await _datasource.login(
      identifier: identifier,
      password: password,
    );
    await _datasource.saveTokens(tokens);
    return tokens;
  }

  Future<AuthTokenModel> refreshToken(String refreshToken) async {
    final tokens = await _datasource.refreshToken(refreshToken);
    await _datasource.saveTokens(tokens);
    return tokens;
  }

  Future<UserModel> getMe() => _datasource.getMe();

  Future<List<Map<String, dynamic>>> getMyPoints({int limit = 20}) =>
      _datasource.getMyPoints(limit: limit);

  Future<void> logout() => _datasource.clearTokens();

  Future<bool> isLoggedIn() => _datasource.hasValidToken();

  Future<String?> getAccessToken() => _datasource.getAccessToken();
}
