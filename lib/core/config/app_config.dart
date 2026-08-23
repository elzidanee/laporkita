// STATUS: VERIFIED — base URL dari intruksi.md §1
// Ganti value saat flutter run:
//   flutter run --dart-define=API_BASE_URL=https://your-tunnel.trycloudflare.com/api/v1
//   flutter run --dart-define=AI_SERVICE_URL=http://192.168.x.x:8000
class AppConfig {
  AppConfig._();

  static const String baseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'https://passage-chancellor-isle-leslie.trycloudflare.com/api/v1',
  );

  /// URL AI Microservice (FastAPI). Untuk device fisik gunakan IP LAN laptop.
  /// Contoh: flutter run --dart-define=AI_SERVICE_URL=http://192.168.1.5:8000
  static const String aiServiceUrl = String.fromEnvironment(
    'AI_SERVICE_URL',
    defaultValue: 'http://192.168.1.100:8000',
  );

  // Token storage keys
  static const String accessTokenKey = 'access_token';
  static const String refreshTokenKey = 'refresh_token';
  static const String userIdKey = 'user_id';
  static const String userRoleKey = 'user_role';
}
