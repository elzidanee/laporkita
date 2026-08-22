import 'api_response.dart';

/// Exception yang dilempar ketika backend mengembalikan error envelope
/// { success: false, data: null, error: { code, message } }
class ApiException implements Exception {
  final String code;
  final String message;
  final dynamic details;
  final int? statusCode;

  const ApiException({
    required this.code,
    required this.message,
    this.details,
    this.statusCode,
  });

  factory ApiException.fromApiError(ApiError error, {int? statusCode}) {
    return ApiException(
      code: error.code,
      message: error.message,
      details: error.details,
      statusCode: statusCode,
    );
  }

  /// Apakah error ini adalah PHONE_NOT_VERIFIED (perlu redirect ke OTP)
  bool get isPhoneNotVerified => code == 'PHONE_NOT_VERIFIED';

  /// Apakah error ini adalah token invalid (perlu logout)
  bool get isTokenInvalid =>
      code == 'UNAUTHORIZED' || code == 'REFRESH_TOKEN_INVALID';

  /// Apakah error ini adalah OTP sudah kadaluarsa
  bool get isOtpExpired => code == 'OTP_EXPIRED';

  /// Apakah error ini adalah OTP salah
  bool get isOtpInvalid => code == 'OTP_INVALID';

  /// Apakah error ini adalah resend OTP masih cooldown
  bool get isOtpResendCooldown => code == 'OTP_RESEND_COOLDOWN';

  /// User-friendly message untuk ditampilkan di UI
  String get userMessage {
    switch (code) {
      case 'PHONE_NOT_VERIFIED':
        return 'Nomor telepon belum diverifikasi. Silakan cek SMS Anda.';
      case 'VALIDATION_ERROR':
        if (details is List && (details as List).isNotEmpty) {
          return (details as List).first.toString();
        }
        return message;
      case 'OTP_EXPIRED':
        return 'Kode OTP sudah kadaluarsa. Silakan minta kode baru.';
      case 'OTP_INVALID':
        return 'Kode OTP yang Anda masukkan salah.';
      case 'OTP_MAX_ATTEMPTS':
        return 'Batas percobaan OTP terlampaui. Silakan minta kode baru.';
      case 'OTP_ALREADY_USED':
        return 'Kode OTP sudah digunakan. Silakan minta kode baru.';
      case 'OTP_RESEND_COOLDOWN':
        return message; // sudah ada info detik dari backend
      case 'CONFLICT':
        return message;
      case 'NOT_FOUND':
        return 'Data tidak ditemukan.';
      case 'UNAUTHORIZED':
        return 'Sesi telah berakhir. Silakan login ulang.';
      case 'INTERNAL_ERROR':
        return 'Terjadi kesalahan server. Silakan coba lagi.';
      default:
        return message;
    }
  }

  @override
  String toString() => 'ApiException(code: $code, message: $message)';
}

/// Exception jaringan (no internet, timeout, dll)
class NetworkException implements Exception {
  final String message;

  const NetworkException(this.message);

  @override
  String toString() => 'NetworkException: $message';
}
