// STATUS: VERIFIED — envelope dari backend/src/common/interceptors/response.interceptor.ts
// Success: { success: true, data: T, meta: PaginationMeta|null, error: null }
// Error:   { success: false, data: null, error: { code, message, details? } }

class ApiResponse<T> {
  final bool success;
  final T? data;
  final PaginationMeta? meta;
  final ApiError? error;

  const ApiResponse({
    required this.success,
    this.data,
    this.meta,
    this.error,
  });

  factory ApiResponse.fromJson(
    Map<String, dynamic> json,
    T Function(dynamic) fromJsonT,
  ) {
    return ApiResponse(
      success: json['success'] as bool,
      data: json['data'] != null ? fromJsonT(json['data']) : null,
      meta: json['meta'] != null
          ? PaginationMeta.fromJson(json['meta'] as Map<String, dynamic>)
          : null,
      error: json['error'] != null
          ? ApiError.fromJson(json['error'] as Map<String, dynamic>)
          : null,
    );
  }
}

class PaginationMeta {
  final int total;
  final int limit;
  final String? nextCursor;
  final bool hasPrevious;

  const PaginationMeta({
    required this.total,
    required this.limit,
    this.nextCursor,
    required this.hasPrevious,
  });

  factory PaginationMeta.fromJson(Map<String, dynamic> json) {
    return PaginationMeta(
      total: json['total'] as int? ?? 0,
      limit: json['limit'] as int? ?? 20,
      nextCursor: json['nextCursor'] as String?,
      hasPrevious: json['hasPrevious'] as bool? ?? false,
    );
  }
}

// STATUS: VERIFIED — dari backend/src/common/filters/http-exception.filter.ts
// Error codes yang sudah diketahui:
//   PHONE_NOT_VERIFIED, VALIDATION_ERROR, OTP_INVALID, OTP_EXPIRED,
//   OTP_MAX_ATTEMPTS, OTP_ALREADY_USED, OTP_RESEND_COOLDOWN,
//   NOT_FOUND, CONFLICT, UNAUTHORIZED, FORBIDDEN, INTERNAL_ERROR
class ApiError {
  final String code;
  final String message;
  final dynamic details;

  const ApiError({
    required this.code,
    required this.message,
    this.details,
  });

  factory ApiError.fromJson(Map<String, dynamic> json) {
    return ApiError(
      code: json['code'] as String? ?? 'UNKNOWN',
      message: json['message'] as String? ?? 'Terjadi kesalahan.',
      details: json['details'],
    );
  }

  @override
  String toString() => 'ApiError(code: $code, message: $message)';
}
