import 'package:equatable/equatable.dart';
import '../../../data/models/user_model.dart';
import '../../../data/models/auth_token_model.dart';

// ─── Events ───────────────────────────────────────────────────────────────────

abstract class AuthEvent extends Equatable {
  const AuthEvent();
  @override
  List<Object?> get props => [];
}

class AuthCheckRequested extends AuthEvent {
  const AuthCheckRequested();
}

class AuthRegisterRequested extends AuthEvent {
  final String fullName;
  final String email;
  final String phoneNumber;
  final String password;

  const AuthRegisterRequested({
    required this.fullName,
    required this.email,
    required this.phoneNumber,
    required this.password,
  });

  @override
  List<Object?> get props => [fullName, email, phoneNumber, password];
}

class AuthVerifyOtpRequested extends AuthEvent {
  final String otpCode;
  final String? userId;
  final String? phoneNumber;

  const AuthVerifyOtpRequested({
    required this.otpCode,
    this.userId,
    this.phoneNumber,
  });

  @override
  List<Object?> get props => [otpCode, userId, phoneNumber];
}

class AuthResendOtpRequested extends AuthEvent {
  final String? userId;
  final String? phoneNumber;

  const AuthResendOtpRequested({this.userId, this.phoneNumber});

  @override
  List<Object?> get props => [userId, phoneNumber];
}

class AuthLoginRequested extends AuthEvent {
  final String identifier; // email atau nomor HP
  final String password;

  const AuthLoginRequested({
    required this.identifier,
    required this.password,
  });

  @override
  List<Object?> get props => [identifier, password];
}

class AuthLogoutRequested extends AuthEvent {
  const AuthLogoutRequested();
}

// ─── States ───────────────────────────────────────────────────────────────────

abstract class AuthState extends Equatable {
  const AuthState();
  @override
  List<Object?> get props => [];
}

class AuthInitial extends AuthState {
  const AuthInitial();
}

class AuthLoading extends AuthState {
  const AuthLoading();
}

/// Auth berhasil (login / verify-otp)
class AuthAuthenticated extends AuthState {
  final UserModel user;
  final AuthTokenModel tokens;

  const AuthAuthenticated({required this.user, required this.tokens});

  @override
  List<Object?> get props => [user, tokens];
}

/// User belum login
class AuthUnauthenticated extends AuthState {
  const AuthUnauthenticated();
}

/// Register berhasil — perlu OTP
class AuthRegistered extends AuthState {
  final String userId;
  final String phoneNumber;
  final String email;
  final String message;

  const AuthRegistered({
    required this.userId,
    required this.phoneNumber,
    required this.email,
    required this.message,
  });

  @override
  List<Object?> get props => [userId, phoneNumber, email];
}

/// Error login dengan PHONE_NOT_VERIFIED — redirect ke OTP screen
class AuthPhoneNotVerified extends AuthState {
  final String phoneNumber;

  const AuthPhoneNotVerified({required this.phoneNumber});

  @override
  List<Object?> get props => [phoneNumber];
}

/// OTP resend berhasil
class AuthOtpResent extends AuthState {
  final int cooldownSeconds;
  final String message;

  const AuthOtpResent({required this.cooldownSeconds, required this.message});

  @override
  List<Object?> get props => [cooldownSeconds];
}

/// Error umum
class AuthError extends AuthState {
  final String code;
  final String message;

  const AuthError({required this.code, required this.message});

  @override
  List<Object?> get props => [code, message];
}
