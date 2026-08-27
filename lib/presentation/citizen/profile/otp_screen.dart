import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../core/theme/app_colors.dart';
import '../../shared_widgets/custom_alert.dart';
import '../../auth/bloc/auth_bloc.dart';
import '../home/get_started_screen.dart'; // Reuse MapBackgroundPainter & TopCurveClipper

class OtpScreen extends StatefulWidget {
  const OtpScreen({super.key});

  @override
  State<OtpScreen> createState() => _OtpScreenState();
}

class _OtpScreenState extends State<OtpScreen> {
  final List<TextEditingController> _controllers =
      List.generate(4, (_) => TextEditingController());
  final List<FocusNode> _focusNodes = List.generate(4, (_) => FocusNode());

  Timer? _timer;
  int _secondsRemaining = 45;
  bool _canResend = false;

  @override
  void initState() {
    super.initState();
    _startTimer(45);
  }

  void _startTimer(int seconds) {
    setState(() {
      _secondsRemaining = seconds;
      _canResend = false;
    });
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_secondsRemaining > 0) {
        setState(() {
          _secondsRemaining--;
        });
      } else {
        setState(() {
          _canResend = true;
        });
        timer.cancel();
      }
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    for (var controller in _controllers) {
      controller.dispose();
    }
    for (var focusNode in _focusNodes) {
      focusNode.dispose();
    }
    super.dispose();
  }

  String get _otpCode => _controllers.map((c) => c.text).join();

  void _handleVerify(String? userId, String? phone) {
    if (_otpCode.length < 4) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Silakan masukkan 4 digit kode OTP'),
          backgroundColor: AppColors.statusDanger,
        ),
      );
      return;
    }

    FocusScope.of(context).unfocus();
    context.read<AuthBloc>().add(
          AuthVerifyOtpRequested(
            otpCode: _otpCode,
            userId: userId,
            phoneNumber: phone,
          ),
        );
  }

  void _handleResend(String? userId, String? phone) {
    context.read<AuthBloc>().add(
          AuthResendOtpRequested(
            userId: userId,
            phoneNumber: phone,
          ),
        );
  }

  @override
  Widget build(BuildContext context) {
    final args =
        ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;
    final role = args?['role'] as String? ?? 'Citizen';
    final userId = args?['userId'] as String?;
    final phone = args?['phone'] as String? ?? '+62 812 4633 4803';

    return BlocConsumer<AuthBloc, AuthState>(
      listener: (context, state) {
        if (state is AuthAuthenticated) {
          if (state.user.role.isCommandCenter || role == 'CommandCenter') {
            Navigator.pushNamedAndRemoveUntil(
              context,
              '/command-center',
              (route) => false,
            );
          } else {
            Navigator.pushNamedAndRemoveUntil(
              context,
              '/citizen',
              (route) => false,
            );
          }
        } else if (state is AuthOtpResent) {
          AppAlert.info(
            context,
            title: 'OTP Dikirim Ulang',
            message: state.message,
          );
          _startTimer(state.cooldownSeconds);
        } else if (state is AuthError) {
          AppAlert.error(
            context,
            title: 'Verifikasi Gagal',
            message: state.message,
          );
        }
      },
      builder: (context, state) {
        final isLoading = state is AuthLoading;

        return Scaffold(
          backgroundColor: AppColors.greenPrimary,
          body: Stack(
            children: [
              Positioned.fill(
                  child: CustomPaint(painter: MapBackgroundPainter())),
              SafeArea(
                bottom: false,
                child: Column(
                  children: [
                    const SizedBox(height: 20),
                    Expanded(
                      child: ClipPath(
                        clipper: TopCurveClipper(),
                        child: Container(
                          color: AppColors.white,
                          width: double.infinity,
                          child: SingleChildScrollView(
                            padding: EdgeInsets.fromLTRB(
                              24,
                              20,
                              24,
                              24 + MediaQuery.of(context).padding.bottom,
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.center,
                              children: [
                                // Back Arrow Button
                                Align(
                                  alignment: Alignment.centerLeft,
                                  child: IconButton(
                                    onPressed: () => Navigator.pop(context),
                                    icon: const Icon(
                                      Icons.arrow_back,
                                      color: AppColors.neutral900,
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 8),

                                // Illustration Image
                                Image.asset(
                                  'assets/images/ilustrasiOTP.png',
                                  height: 180,
                                  fit: BoxFit.contain,
                                  errorBuilder: (context, error, stackTrace) =>
                                      Container(
                                    height: 160,
                                    width: 160,
                                    decoration: BoxDecoration(
                                      color: AppColors.greenPrimary
                                          .withValues(alpha: 0.1),
                                      shape: BoxShape.circle,
                                    ),
                                    child: const Icon(
                                      Icons.mark_email_read_outlined,
                                      size: 64,
                                      color: AppColors.greenPrimary,
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 20),

                                // Title: Verifikasi Nomor
                                Text(
                                  'Verifikasi Nomor',
                                  style: Theme.of(context)
                                      .textTheme
                                      .headlineMedium
                                      ?.copyWith(
                                        fontSize: 24,
                                        fontWeight: FontWeight.bold,
                                        color: AppColors.neutral900,
                                      ),
                                  textAlign: TextAlign.center,
                                ),
                                const SizedBox(height: 8),

                                // Subtitle with Phone Number
                                Padding(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 16),
                                  child: Text(
                                    'Masukan kode 4 digit yang telah kami kirim ke $phone',
                                    style: Theme.of(context)
                                        .textTheme
                                        .bodyMedium
                                        ?.copyWith(
                                          fontSize: 14,
                                          color: AppColors.neutral500,
                                          height: 1.4,
                                        ),
                                    textAlign: TextAlign.center,
                                  ),
                                ),
                                const SizedBox(height: 32),

                                // 4-Digit OTP Input Fields Row
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: List.generate(4, (index) {
                                    return Container(
                                      margin: const EdgeInsets.symmetric(
                                          horizontal: 6),
                                      width: 56,
                                      height: 56,
                                      decoration: BoxDecoration(
                                        color: _focusNodes[index].hasFocus
                                            ? AppColors.white
                                            : AppColors.neutral100,
                                        borderRadius: BorderRadius.circular(12),
                                        border: Border.all(
                                          color: _controllers[index]
                                                  .text
                                                  .isNotEmpty
                                              ? AppColors.greenPrimary
                                              : (_focusNodes[index].hasFocus
                                                  ? AppColors.greenPrimary
                                                  : AppColors.border),
                                          width: _focusNodes[index].hasFocus ||
                                                  _controllers[index]
                                                      .text
                                                      .isNotEmpty
                                              ? 1.5
                                              : 1.0,
                                        ),
                                      ),
                                      child: Center(
                                        child: TextField(
                                          controller: _controllers[index],
                                          focusNode: _focusNodes[index],
                                          keyboardType: TextInputType.number,
                                          textAlign: TextAlign.center,
                                          maxLength: 1,
                                          style: const TextStyle(
                                            fontSize: 22,
                                            fontWeight: FontWeight.bold,
                                            color: AppColors.neutral900,
                                          ),
                                          inputFormatters: [
                                            FilteringTextInputFormatter
                                                .digitsOnly,
                                          ],
                                          decoration: const InputDecoration(
                                            counterText: '',
                                            border: InputBorder.none,
                                            contentPadding: EdgeInsets.zero,
                                          ),
                                          onChanged: (value) {
                                            setState(() {});
                                            if (value.isNotEmpty && index < 3) {
                                              _focusNodes[index + 1]
                                                  .requestFocus();
                                            } else if (value.isEmpty &&
                                                index > 0) {
                                              _focusNodes[index - 1]
                                                  .requestFocus();
                                            }
                                            if (_otpCode.length == 4) {
                                              FocusScope.of(context).unfocus();
                                            }
                                          },
                                        ),
                                      ),
                                    );
                                  }),
                                ),
                                const SizedBox(height: 32),

                                // Countdown Resend Timer
                                if (!_canResend)
                                  Text(
                                    'Kirim ulang kode 00.${_secondsRemaining.toString().padLeft(2, '0')}',
                                    style: const TextStyle(
                                      color: AppColors.greenPrimary,
                                      fontWeight: FontWeight.w600,
                                      fontSize: 14,
                                    ),
                                  )
                                else
                                  GestureDetector(
                                    onTap: isLoading
                                        ? null
                                        : () => _handleResend(userId, phone),
                                    child: const Text(
                                      'Kirim Ulang Kode',
                                      style: TextStyle(
                                        color: AppColors.greenPrimary,
                                        fontWeight: FontWeight.bold,
                                        fontSize: 14,
                                        decoration: TextDecoration.underline,
                                      ),
                                    ),
                                  ),
                                const SizedBox(height: 36),

                                // Primary Action Button: Verifikasi
                                ElevatedButton(
                                  onPressed: isLoading
                                      ? null
                                      : () => _handleVerify(userId, phone),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: AppColors.greenPrimary,
                                    foregroundColor: AppColors.white,
                                    minimumSize: const Size.fromHeight(52),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(16),
                                    ),
                                    elevation: 0,
                                  ),
                                  child: isLoading
                                      ? const SizedBox(
                                          height: 20,
                                          width: 20,
                                          child: CircularProgressIndicator(
                                            color: AppColors.white,
                                            strokeWidth: 2,
                                          ),
                                        )
                                      : const Text(
                                          'Verifikasi',
                                          style: TextStyle(
                                            fontSize: 16,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                ),
                                const SizedBox(height: 16),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
