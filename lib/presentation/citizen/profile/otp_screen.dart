import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../core/theme/app_colors.dart';
import '../home/get_started_screen.dart'; // Reuse MapBackgroundPainter & TopCurveClipper

class OtpScreen extends StatefulWidget {
  const OtpScreen({super.key});

  @override
  State<OtpScreen> createState() => _OtpScreenState();
}

class _OtpScreenState extends State<OtpScreen> {
  // 4 Controllers & FocusNodes for 4-digit OTP input
  final List<TextEditingController> _controllers =
      List.generate(4, (_) => TextEditingController());
  final List<FocusNode> _focusNodes = List.generate(4, (_) => FocusNode());

  // Countdown timer state
  Timer? _timer;
  int _secondsRemaining = 45;
  bool _canResend = false;

  @override
  void initState() {
    super.initState();
    _startTimer();
  }

  void _startTimer() {
    setState(() {
      _secondsRemaining = 45;
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

  void _handleVerify(String role) {
    if (_otpCode.length < 4) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Silakan masukkan 4 digit kode OTP'),
          backgroundColor: AppColors.statusDanger,
        ),
      );
      return;
    }

    // Success feedback & Navigate to target home/dashboard based on role
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Verifikasi OTP berhasil!'),
        backgroundColor: AppColors.greenPrimary,
      ),
    );

    if (role == 'CommandCenter') {
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
  }

  @override
  Widget build(BuildContext context) {
    // Extract route arguments if passed (e.g. {'role': 'Citizen', 'phone': '+62 812 4633 4803'})
    final args =
        ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;
    final role = args?['role'] as String? ?? 'Citizen';
    final phone = args?['phone'] as String? ?? '+62 812 4633 4803';

    return Scaffold(
      backgroundColor: AppColors.greenPrimary,
      body: Stack(
        children: [
          // 1. Vector Map Pattern Background
          Positioned.fill(child: CustomPaint(painter: MapBackgroundPainter())),

          // 2. White Curved Container with OTP Content
          SafeArea(
            bottom: false, // Allow container to bleed behind bottom nav gesture bar
            child: Column(
              children: [
                const SizedBox(height: 20), // Top margin showing map background
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
                                  color: AppColors.greenPrimary.withValues(alpha: 0.1),
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
                              padding:
                                  const EdgeInsets.symmetric(horizontal: 16),
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
                                      color: _controllers[index].text.isNotEmpty
                                          ? AppColors.greenPrimary
                                          : (_focusNodes[index].hasFocus
                                              ? AppColors.greenPrimary
                                              : AppColors.border),
                                      width: _focusNodes[index].hasFocus ||
                                              _controllers[index].text.isNotEmpty
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
                                        FilteringTextInputFormatter.digitsOnly,
                                      ],
                                      decoration: const InputDecoration(
                                        counterText: '',
                                        border: InputBorder.none,
                                        contentPadding: EdgeInsets.zero,
                                      ),
                                      onChanged: (value) {
                                        setState(() {});
                                        if (value.isNotEmpty && index < 3) {
                                          _focusNodes[index + 1].requestFocus();
                                        } else if (value.isEmpty && index > 0) {
                                          _focusNodes[index - 1].requestFocus();
                                        }
                                        if (_otpCode.length == 4) {
                                          // Auto focus dismiss or auto verify if preferred
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
                                onTap: _startTimer,
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
                              onPressed: () => _handleVerify(role),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppColors.greenPrimary,
                                foregroundColor: AppColors.white,
                                minimumSize: const Size.fromHeight(52),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(16),
                                ),
                                elevation: 0,
                              ),
                              child: const Text(
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
  }
}
