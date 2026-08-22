// STATUS: VERIFIED — base URL dari intruksi.md §1
// Ganti value saat flutter run:
//   flutter run --dart-define=API_BASE_URL=https://your-tunnel.trycloudflare.com/api/v1
class AppConfig {
  AppConfig._();

  static const String baseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'https://passage-chancellor-isle-leslie.trycloudflare.com/api/v1',
  );

  // Token storage keys
  static const String accessTokenKey = 'access_token';
  static const String refreshTokenKey = 'refresh_token';
  static const String userIdKey = 'user_id';
  static const String userRoleKey = 'user_role';
}
