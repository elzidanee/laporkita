import 'package:dio/dio.dart';
import 'package:laporkita/core/config/app_config.dart';
import 'package:laporkita/core/utils/image_utils.dart';
import 'package:laporkita/data/models/ai_verification_model.dart';
import 'package:laporkita/data/models/risk_prediction_model.dart';

/// Datasource untuk AI Microservice (FastAPI — berjalan di :8000).
/// Menggunakan Dio instance terpisah karena:
///   1. Base URL berbeda dari backend NestJS
///   2. Autentikasi via X-API-Key (bukan Bearer token user)
///   3. Timeout lebih panjang (inference bisa 5-10 detik, cold-start hingga 15s)
class AiServiceDatasource {
  static AiServiceDatasource? _instance;
  late final Dio _dio;

  AiServiceDatasource._internal() {
    _dio = Dio(
      BaseOptions(
        baseUrl: AppConfig.aiServiceUrl,
        connectTimeout: const Duration(seconds: 4),
        receiveTimeout: const Duration(seconds: 25),
        sendTimeout: const Duration(seconds: 30),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
          'User-Agent': 'LaporKita-MobileApp/1.0 (Flutter)',
          if (AppConfig.aiApiKey.isNotEmpty) 'X-API-Key': AppConfig.aiApiKey,
        },
      ),
    );
  }

  factory AiServiceDatasource() {
    _instance ??= AiServiceDatasource._internal();
    return _instance!;
  }

  Future<bool> isHealthy() async {
    try {
      final response = await _dio.get('/health');
      return response.statusCode == 200;
    } catch (_) {
      return false;
    }
  }

  /// Verifikasi laporan menggunakan YOLOv11-cls.
  /// [imagePath] dikompres & di-encode base64 di isolate agar tidak freeze UI.
  Future<AiVerificationResult> verifyReport({
    String? imagePath,
    String? imageUrl,
    String? claimedCategory,
    required double latitude,
    required double longitude,
    DateTime? timestamp,
    String? deviceHintCategory,
    double? deviceHintConfidence,
  }) async {
    String? imageBase64;
    if (imagePath != null &&
        imagePath.isNotEmpty &&
        !imagePath.startsWith('http')) {
      // Encode di isolate — mencegah jank 200-800ms di main thread
      imageBase64 = await ImageUtils.fileToBase64Isolate(imagePath);
    }

    final payload = <String, dynamic>{
      'latitude': latitude,
      'longitude': longitude,
      if (imageBase64 != null) 'image_base64': imageBase64,
      if (imageUrl != null && imageUrl.isNotEmpty) 'image_url': imageUrl,
      if (claimedCategory != null) 'claimed_category': claimedCategory,
      if (timestamp != null) 'timestamp': timestamp.toIso8601String(),
      if (deviceHintCategory != null) 'device_hint_category': deviceHintCategory,
      if (deviceHintConfidence != null)
        'device_hint_confidence': deviceHintConfidence,
    };

    final response = await _dio.post('/v1/verify', data: payload);
    return AiVerificationResult.fromJson(
      response.data as Map<String, dynamic>,
    );
  }

  Future<RiskPredictionResult> predictRisk({
    String? zoneId,
    required int reportDensity,
    double rainfallMm = 0.0,
    double temperatureC = 27.0,
    String weatherCondition = 'Berawan',
    double drainageIssueRatio = 0.2,
    double trafficDensity = 0.5,
  }) async {
    final payload = <String, dynamic>{
      if (zoneId != null) 'zone_id': zoneId,
      'report_density': reportDensity,
      'traffic_density': trafficDensity,
      'weather_context': WeatherContextRequest(
        rainfallMm: rainfallMm,
        temperatureC: temperatureC,
        condition: weatherCondition,
        drainageIssueRatio: drainageIssueRatio,
      ).toJson(),
    };

    final response = await _dio.post('/v1/predict-risk', data: payload);
    final data = response.data as Map<String, dynamic>;
    if (data['data'] is Map<String, dynamic>) {
      (data['data'] as Map<String, dynamic>)['report_density'] = reportDensity;
    } else {
      data['report_density'] = reportDensity;
    }
    return RiskPredictionResult.fromJson(data);
  }
}
