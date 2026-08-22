import 'user_model.dart';

// STATUS: VERIFIED — dari backend/src/modules/auth/auth.service.ts (AuthTokens interface)
// Response verify-otp & login:
// { access_token, refresh_token, expires_in, token_type: 'Bearer', user: {...} }

class AuthTokenModel {
  final String accessToken;
  final String refreshToken;
  final String expiresIn;
  final String tokenType;
  final UserModel user;

  const AuthTokenModel({
    required this.accessToken,
    required this.refreshToken,
    required this.expiresIn,
    required this.tokenType,
    required this.user,
  });

  factory AuthTokenModel.fromJson(Map<String, dynamic> json) {
    return AuthTokenModel(
      accessToken: json['access_token'] as String,
      refreshToken: json['refresh_token'] as String,
      expiresIn: json['expires_in'] as String? ?? '15m',
      tokenType: json['token_type'] as String? ?? 'Bearer',
      user: UserModel.fromJson(json['user'] as Map<String, dynamic>),
    );
  }

  Map<String, dynamic> toJson() => {
        'access_token': accessToken,
        'refresh_token': refreshToken,
        'expires_in': expiresIn,
        'token_type': tokenType,
        'user': user.toJson(),
      };
}

// STATUS: VERIFIED — dari backend/src/modules/auth/auth.service.ts (RegisterResponse interface)
// Response register: { user_id, phone_number, email, message }
class RegisterResponseModel {
  final String userId;
  final String? phoneNumber;
  final String? email;
  final String message;

  const RegisterResponseModel({
    required this.userId,
    this.phoneNumber,
    this.email,
    required this.message,
  });

  factory RegisterResponseModel.fromJson(Map<String, dynamic> json) {
    return RegisterResponseModel(
      userId: json['user_id'] as String,
      phoneNumber: json['phone_number'] as String?,
      email: json['email'] as String?,
      message: json['message'] as String? ?? 'Registrasi berhasil.',
    );
  }
}
