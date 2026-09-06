import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../config/app_config.dart';
import 'api_response.dart';
import 'api_exception.dart';

/// DioClient — singleton Dio instance dengan interceptor:
/// 1. Sisipkan Authorization: Bearer token otomatis
/// 2. Auto-refresh token saat mendapat 401
/// 3. Mapping response error envelope ke ApiException
class DioClient {
  static DioClient? _instance;
  late final Dio _dio;
  final FlutterSecureStorage _storage;
  bool _isRefreshing = false;

  DioClient._internal(this._storage) {
    _dio = Dio(
      BaseOptions(
        baseUrl: AppConfig.baseUrl,
        connectTimeout: const Duration(seconds: 4),
        receiveTimeout: const Duration(seconds: 15),
        sendTimeout: const Duration(seconds: 30),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
      ),
    );
    _setupInterceptors();
  }

  factory DioClient({FlutterSecureStorage? storage}) {
    _instance ??= DioClient._internal(
      storage ?? const FlutterSecureStorage(),
    );
    return _instance!;
  }

  /// Reset instance (berguna untuk testing)
  static void resetInstance() => _instance = null;

  Dio get dio => _dio;

  void _setupInterceptors() {
    _dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: _onRequest,
        onResponse: _onResponse,
        onError: _onError,
      ),
    );
  }

  /// Sisipkan Bearer token ke setiap request yang memerlukan auth
  Future<void> _onRequest(
    RequestOptions options,
    RequestInterceptorHandler handler,
  ) async {
    final token = await _storage.read(key: AppConfig.accessTokenKey);
    if (token != null) {
      options.headers['Authorization'] = 'Bearer $token';
    }
    handler.next(options);
  }

  /// Response sukses — diteruskan biasa
  void _onResponse(Response response, ResponseInterceptorHandler handler) {
    handler.next(response);
  }

  /// Error — handle 401 dengan auto-refresh, lainnya mapping ke ApiException
  Future<void> _onError(
    DioException err,
    ErrorInterceptorHandler handler,
  ) async {
    // Jika bukan HTTP error, lempar NetworkException dengan pesan sesuai tipe timeout
    if (err.type == DioExceptionType.connectionTimeout ||
        err.type == DioExceptionType.sendTimeout ||
        err.type == DioExceptionType.receiveTimeout ||
        err.type == DioExceptionType.connectionError) {
      final isSendTimeout = err.type == DioExceptionType.sendTimeout;
      return handler.reject(
        DioException(
          requestOptions: err.requestOptions,
          error: NetworkException(
            isSendTimeout
                ? 'Upload lambat / koneksi tidak stabil. Coba lagi.'
                : 'Tidak dapat terhubung ke server. Periksa koneksi internet Anda.',
          ),
          type: err.type,
        ),
      );
    }

    final response = err.response;
    if (response == null) {
      return handler.reject(err);
    }

    // Parse error envelope dari backend
    final apiError = _parseErrorResponse(response);

    // Auto-refresh jika 401 DAN bukan endpoint auth itu sendiri
    if (response.statusCode == 401 &&
        !err.requestOptions.path.contains('/auth/') &&
        !_isRefreshing) {
      final retried = await _tryRefreshAndRetry(err, handler, apiError);
      if (retried) return;
    }

    handler.reject(
      DioException(
        requestOptions: err.requestOptions,
        response: response,
        error: ApiException.fromApiError(
          apiError,
          statusCode: response.statusCode,
        ),
        type: DioExceptionType.badResponse,
      ),
    );
  }

  /// Parse envelope error dari response body backend
  ApiError _parseErrorResponse(Response response) {
    try {
      final data = response.data;
      if (data is Map<String, dynamic> && data['error'] != null) {
        return ApiError.fromJson(data['error'] as Map<String, dynamic>);
      }
    } catch (_) {}

    final statusCode = response.statusCode ?? 500;
    String code = 'HTTP_$statusCode';
    String message = 'Terjadi kesalahan ($statusCode).';

    if (statusCode == 502) {
      code = 'BAD_GATEWAY';
      message = 'Server gateway sedang gangguan (502 Bad Gateway). Coba beberapa saat lagi.';
    } else if (statusCode == 503) {
      code = 'SERVICE_UNAVAILABLE';
      message = 'Layanan sedang dalam pemeliharaan (503 Service Unavailable).';
    } else if (statusCode == 504) {
      code = 'GATEWAY_TIMEOUT';
      message = 'Waktu koneksi gateway habis (504 Gateway Timeout). Coba beberapa saat lagi.';
    } else if (statusCode == 500) {
      code = 'INTERNAL_ERROR';
      message = 'Terjadi kesalahan server internal (500). Silakan coba lagi.';
    }

    return ApiError(
      code: code,
      message: message,
    );
  }

  /// Coba refresh token, lalu retry request original
  Future<bool> _tryRefreshAndRetry(
    DioException err,
    ErrorInterceptorHandler handler,
    ApiError originalError,
  ) async {
    _isRefreshing = true;
    try {
      final refreshToken = await _storage.read(key: AppConfig.refreshTokenKey);
      if (refreshToken == null) {
        _isRefreshing = false;
        return false;
      }

      // Panggil refresh endpoint langsung (bypass interceptor) dengan timeout
      final refreshDio = Dio(
        BaseOptions(
          baseUrl: AppConfig.baseUrl,
          connectTimeout: const Duration(seconds: 4),
          receiveTimeout: const Duration(seconds: 10),
          sendTimeout: const Duration(seconds: 10),
          headers: {'Content-Type': 'application/json'},
        ),
      );

      final refreshResp = await refreshDio.post(
        '/auth/refresh',
        data: {'refresh_token': refreshToken},
      );

      // Ambil token baru dari data envelope
      final respData = refreshResp.data;
      final tokenData = respData is Map<String, dynamic>
          ? (respData['data'] as Map<String, dynamic>?)
          : null;

      if (tokenData == null) {
        _isRefreshing = false;
        return false;
      }

      final newAccessToken = tokenData['access_token'] as String?;
      final newRefreshToken = tokenData['refresh_token'] as String?;

      if (newAccessToken == null) {
        _isRefreshing = false;
        return false;
      }

      await _storage.write(key: AppConfig.accessTokenKey, value: newAccessToken);
      if (newRefreshToken != null) {
        await _storage.write(key: AppConfig.refreshTokenKey, value: newRefreshToken);
      }

      // Retry request original dengan token baru
      err.requestOptions.headers['Authorization'] = 'Bearer $newAccessToken';
      final retryResp = await _dio.fetch(err.requestOptions);
      handler.resolve(retryResp);
      _isRefreshing = false;
      return true;
    } catch (_) {
      // Refresh gagal — hapus token (session expired)
      await _storage.delete(key: AppConfig.accessTokenKey);
      await _storage.delete(key: AppConfig.refreshTokenKey);
      _isRefreshing = false;
      return false;
    }
  }

  // ─── Helper methods ────────────────────────────────────────────────────────

  /// Parsing aman untuk response envelope dari backend
  ApiResponse<T> _parseResponse<T>(
    Response resp,
    T Function(dynamic) fromJson,
  ) {
    final data = resp.data;

    if (data == null) {
      throw ApiException(
        code: 'EMPTY_RESPONSE',
        message: 'Respons dari server kosong.',
        statusCode: resp.statusCode,
      );
    }

    if (data is! Map<String, dynamic>) {
      // Menangani raw HTML (502, 503, 504), string error, atau list
      final statusCode = resp.statusCode ?? 200;
      if (statusCode >= 500) {
        String msg = 'Server sedang mengalami gangguan ($statusCode). Silakan coba lagi.';
        String code = 'SERVER_ERROR';
        if (statusCode == 502) {
          code = 'BAD_GATEWAY';
          msg = 'Server gateway sedang gangguan (502 Bad Gateway). Coba beberapa saat lagi.';
        } else if (statusCode == 503) {
          code = 'SERVICE_UNAVAILABLE';
          msg = 'Layanan sedang dalam pemeliharaan (503 Service Unavailable).';
        } else if (statusCode == 504) {
          code = 'GATEWAY_TIMEOUT';
          msg = 'Waktu koneksi gateway habis (504 Gateway Timeout). Coba beberapa saat lagi.';
        }
        throw ApiException(
          code: code,
          message: msg,
          statusCode: statusCode,
        );
      }

      throw ApiException(
        code: 'INVALID_RESPONSE_FORMAT',
        message: 'Format data dari server tidak valid.',
        statusCode: resp.statusCode,
      );
    }

    try {
      return ApiResponse.fromJson(data, fromJson);
    } catch (e) {
      if (e is ApiException) rethrow;
      throw ApiException(
        code: 'PARSING_ERROR',
        message: 'Gagal menguraikan respons data server.',
        details: e.toString(),
        statusCode: resp.statusCode,
      );
    }
  }

  /// Kirim GET request dan parse envelope response
  Future<ApiResponse<T>> get<T>(
    String path, {
    required T Function(dynamic) fromJson,
    Map<String, dynamic>? queryParameters,
  }) async {
    try {
      final resp = await _dio.get(path, queryParameters: queryParameters);
      return _parseResponse(resp, fromJson);
    } on DioException catch (e) {
      throw _extractException(e);
    }
  }

  /// Kirim POST request dan parse envelope response
  Future<ApiResponse<T>> post<T>(
    String path, {
    required T Function(dynamic) fromJson,
    dynamic data,
    FormData? formData,
  }) async {
    try {
      final resp = await _dio.post(path, data: formData ?? data);
      return _parseResponse(resp, fromJson);
    } on DioException catch (e) {
      throw _extractException(e);
    }
  }

  /// Kirim PATCH request
  Future<ApiResponse<T>> patch<T>(
    String path, {
    required T Function(dynamic) fromJson,
    dynamic data,
  }) async {
    try {
      final resp = await _dio.patch(path, data: data);
      return _parseResponse(resp, fromJson);
    } on DioException catch (e) {
      throw _extractException(e);
    }
  }

  /// Kirim DELETE request
  Future<ApiResponse<T>> delete<T>(
    String path, {
    required T Function(dynamic) fromJson,
  }) async {
    try {
      final resp = await _dio.delete(path);
      return _parseResponse(resp, fromJson);
    } on DioException catch (e) {
      throw _extractException(e);
    }
  }

  /// Ekstrak ApiException atau NetworkException dari DioException
  Exception _extractException(DioException e) {
    if (e.error is ApiException) return e.error as ApiException;
    if (e.error is NetworkException) return e.error as NetworkException;
    if (e.type == DioExceptionType.connectionError ||
        e.type == DioExceptionType.connectionTimeout) {
      return const NetworkException(
        'Tidak dapat terhubung. Periksa koneksi internet Anda.',
      );
    }

    final statusCode = e.response?.statusCode;
    if (statusCode != null && statusCode >= 500) {
      String code = 'SERVER_ERROR';
      String msg = 'Terjadi kesalahan server internal ($statusCode).';
      if (statusCode == 502) {
        code = 'BAD_GATEWAY';
        msg = 'Server gateway sedang gangguan (502 Bad Gateway). Coba beberapa saat lagi.';
      } else if (statusCode == 503) {
        code = 'SERVICE_UNAVAILABLE';
        msg = 'Layanan sedang dalam pemeliharaan (503 Service Unavailable).';
      } else if (statusCode == 504) {
        code = 'GATEWAY_TIMEOUT';
        msg = 'Waktu koneksi gateway habis (504 Gateway Timeout). Coba beberapa saat lagi.';
      }
      return ApiException(
        code: code,
        message: msg,
        statusCode: statusCode,
      );
    }

    return ApiException(
      code: 'UNKNOWN',
      message: e.message ?? 'Terjadi kesalahan tak dikenal.',
      statusCode: statusCode,
    );
  }
}
