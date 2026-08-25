// STATUS: VERIFIED — Production URLs
// Backend  : https://api.canadev.my.id  (NestJS, port 3000)
// AI Service: https://ai.canadev.my.id  (FastAPI, port 8000)
//
// Override via dart-define jika perlu:
//   flutter run --dart-define=API_BASE_URL=https://api.canadev.my.id/api/v1
//   flutter run --dart-define=AI_SERVICE_URL=https://ai.canadev.my.id
//   flutter run --dart-define=AI_API_KEY=your_internal_key
class AppConfig {
  AppConfig._();

  static const String baseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'https://api.canadev.my.id/api/v1',
  );

  /// URL AI Microservice (FastAPI) — production
  static const String aiServiceUrl = String.fromEnvironment(
    'AI_SERVICE_URL',
    defaultValue: 'https://ai.canadev.my.id',
  );

  /// Internal API Key untuk autentikasi service-to-service ke FastAPI AI.
  /// Bisa di-override via --dart-define=AI_API_KEY=... saat build/run.
  static const String aiApiKey = String.fromEnvironment(
    'AI_API_KEY',
    defaultValue: 'laporkita-a0de63d362f6bb7e9b7fa125a0452196',
  );

  // Token storage keys
  static const String accessTokenKey = 'access_token';
  static const String refreshTokenKey = 'refresh_token';
  static const String userIdKey = 'user_id';
  static const String userRoleKey = 'user_role';
}
