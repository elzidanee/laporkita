import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_svg/flutter_svg.dart';
import '../../../core/theme/app_colors.dart';
import '../../shared_widgets/custom_alert.dart';
import '../../auth/bloc/auth_bloc.dart';
import '../home/get_started_screen.dart'; // Reuse MapBackgroundPainter & TopCurveClipper

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _identifierController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isPasswordObscured = true;

  @override
  void dispose() {
    _identifierController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _handleLogin() {
    if (_formKey.currentState!.validate()) {
      FocusScope.of(context).unfocus();
      context.read<AuthBloc>().add(
            AuthLoginRequested(
              identifier: _identifierController.text.trim(),
              password: _passwordController.text,
            ),
          );
    }
  }

  @override
  Widget build(BuildContext context) {
    // Extract passed role argument from GetStartedScreen
    final argsRole =
        ModalRoute.of(context)?.settings.arguments as String? ?? 'Citizen';

    return BlocConsumer<AuthBloc, AuthState>(
      listener: (context, state) {
        if (state is AuthAuthenticated) {
          if (state.user.role.isCommandCenter || argsRole == 'CommandCenter') {
            Navigator.pushNamedAndRemoveUntil(
                context, '/command-center', (route) => false);
          } else {
            Navigator.pushNamedAndRemoveUntil(
                context, '/citizen', (route) => false);
          }
        } else if (state is AuthPhoneNotVerified) {
          AppAlert.warning(
            context,
            title: 'Verifikasi Diperlukan',
            message: 'Nomor telepon belum diverifikasi. Silakan verifikasi OTP.',
          );
          Navigator.pushNamed(
            context,
            '/otp',
            arguments: {'phoneNumber': state.phoneNumber},
          );
        } else if (state is AuthError) {
          AppAlert.error(
            context,
            title: 'Gagal Masuk',
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
              // 1. Vector Map Top Background Header
              Positioned.fill(
                child: CustomPaint(
                  painter: MapBackgroundPainter(),
                ),
              ),

              // 2. White Curved Container with Form Content
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
                              32,
                              24,
                              24 + MediaQuery.of(context).padding.bottom,
                            ),
                            child: Form(
                              key: _formKey,
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  // Back Arrow Button
                                  Align(
                                    alignment: Alignment.centerLeft,
                                    child: IconButton(
                                      onPressed: () => Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                          builder: (context) =>
                                              const GetStartedScreen(),
                                        ),
                                      ),
                                      icon: const Icon(
                                        Icons.arrow_back_ios_new,
                                        color: AppColors.neutral900,
                                        size: 20,
                                      ),
                                      padding: EdgeInsets.zero,
                                      constraints: const BoxConstraints(),
                                    ),
                                  ),
                                  const SizedBox(height: 20),

                                  // Title & Subtitle
                                  Text(
                                    'Log In',
                                    style: Theme.of(context)
                                        .textTheme
                                        .headlineLarge
                                        ?.copyWith(
                                          fontSize: 32,
                                          fontWeight: FontWeight.bold,
                                          color: AppColors.neutral900,
                                        ),
                                  ),
                                  const SizedBox(height: 6),
                                  Text(
                                    'Selamat datang kembali!',
                                    style: Theme.of(context)
                                        .textTheme
                                        .bodyMedium
                                        ?.copyWith(
                                          color: AppColors.neutral500,
                                          fontSize: 14,
                                        ),
                                  ),
                                  const SizedBox(height: 28),

                                  // Field 1: Email atau No. HP
                                  Text(
                                    'Email atau No. HP',
                                    style: Theme.of(context)
                                        .textTheme
                                        .bodyMedium
                                        ?.copyWith(
                                          fontWeight: FontWeight.w600,
                                          color: AppColors.neutral900,
                                        ),
                                  ),
                                  const SizedBox(height: 8),
                                  TextFormField(
                                    controller: _identifierController,
                                    decoration: InputDecoration(
                                      hintText: 'Masukan email atau nomor HP',
                                      hintStyle: const TextStyle(
                                          color: AppColors.neutral500,
                                          fontSize: 13),
                                      prefixIcon: const Icon(
                                          Icons.mail_outline,
                                          color: AppColors.neutral500,
                                          size: 20),
                                      contentPadding:
                                          const EdgeInsets.symmetric(
                                              horizontal: 16, vertical: 14),
                                      border: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(12),
                                        borderSide: const BorderSide(
                                            color: AppColors.border),
                                      ),
                                      enabledBorder: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(12),
                                        borderSide: const BorderSide(
                                            color: AppColors.border),
                                      ),
                                      focusedBorder: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(12),
                                        borderSide: const BorderSide(
                                            color: AppColors.greenPrimary,
                                            width: 1.5),
                                      ),
                                    ),
                                    validator: (value) {
                                      if (value == null ||
                                          value.trim().isEmpty) {
                                        return 'Email atau No. HP harus diisi';
                                      }
                                      return null;
                                    },
                                  ),
                                  const SizedBox(height: 18),

                                  // Field 2: Kata Sandi
                                  Text(
                                    'Kata Sandi',
                                    style: Theme.of(context)
                                        .textTheme
                                        .bodyMedium
                                        ?.copyWith(
                                          fontWeight: FontWeight.w600,
                                          color: AppColors.neutral900,
                                        ),
                                  ),
                                  const SizedBox(height: 8),
                                  TextFormField(
                                    controller: _passwordController,
                                    obscureText: _isPasswordObscured,
                                    decoration: InputDecoration(
                                      hintText: 'Masukan kata sandi',
                                      hintStyle: const TextStyle(
                                          color: AppColors.neutral500,
                                          fontSize: 13),
                                      prefixIcon: const Icon(
                                          Icons.lock_outline,
                                          color: AppColors.neutral500,
                                          size: 20),
                                      suffixIcon: IconButton(
                                        icon: Icon(
                                          _isPasswordObscured
                                              ? Icons.visibility_off_outlined
                                              : Icons.visibility_outlined,
                                          color: AppColors.neutral500,
                                          size: 20,
                                        ),
                                        onPressed: () {
                                          setState(() {
                                            _isPasswordObscured =
                                                !_isPasswordObscured;
                                          });
                                        },
                                      ),
                                      contentPadding:
                                          const EdgeInsets.symmetric(
                                              horizontal: 16, vertical: 14),
                                      border: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(12),
                                        borderSide: const BorderSide(
                                            color: AppColors.border),
                                      ),
                                      enabledBorder: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(12),
                                        borderSide: const BorderSide(
                                            color: AppColors.border),
                                      ),
                                      focusedBorder: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(12),
                                        borderSide: const BorderSide(
                                            color: AppColors.greenPrimary,
                                            width: 1.5),
                                      ),
                                    ),
                                    validator: (value) {
                                      if (value == null || value.isEmpty) {
                                        return 'Kata sandi harus diisi';
                                      }
                                      if (value.length < 6) {
                                        return 'Kata sandi minimal 6 karakter';
                                      }
                                      return null;
                                    },
                                  ),
                                  const SizedBox(height: 8),

                                  // Forgot Password Link
                                  Align(
                                    alignment: Alignment.centerRight,
                                    child: TextButton(
                                      onPressed: () {
                                        ScaffoldMessenger.of(context)
                                            .showSnackBar(
                                          const SnackBar(
                                              content: Text(
                                                  'Fitur Lupa Kata Sandi')),
                                        );
                                      },
                                      style: TextButton.styleFrom(
                                        padding: EdgeInsets.zero,
                                        minimumSize: Size.zero,
                                        tapTargetSize:
                                            MaterialTapTargetSize.shrinkWrap,
                                      ),
                                      child: const Text(
                                        'Lupa kata sandi ?',
                                        style: TextStyle(
                                          color: AppColors.statusInfo,
                                          fontWeight: FontWeight.bold,
                                          fontSize: 13,
                                        ),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(height: 24),

                                  // Login Primary Button
                                  ElevatedButton(
                                    onPressed: isLoading ? null : _handleLogin,
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: AppColors.greenPrimary,
                                      foregroundColor: AppColors.white,
                                      minimumSize:
                                          const Size.fromHeight(52),
                                      shape: RoundedRectangleBorder(
                                        borderRadius:
                                            BorderRadius.circular(16),
                                      ),
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
                                            'Login',
                                            style: TextStyle(
                                              fontSize: 16,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                  ),
                                  const SizedBox(height: 20),

                                  // Divider Text: "Atau masuk dengan"
                                  const Center(
                                    child: Text(
                                      'Atau masuk dengan',
                                      style: TextStyle(
                                        color: AppColors.neutral500,
                                        fontSize: 13,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(height: 16),

                                  // Social Login: "Masuk dengan google"
                                  OutlinedButton(
                                    onPressed: isLoading ? null : _handleLogin,
                                    style: OutlinedButton.styleFrom(
                                      foregroundColor: AppColors.neutral900,
                                      minimumSize:
                                          const Size.fromHeight(52),
                                      side: const BorderSide(
                                          color: AppColors.border,
                                          width: 1.2),
                                      shape: RoundedRectangleBorder(
                                        borderRadius:
                                            BorderRadius.circular(16),
                                      ),
                                    ),
                                    child: Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      children: [
                                        _buildGoogleGLogo(),
                                        const SizedBox(width: 12),
                                        const Text(
                                          'Masuk dengan google',
                                          style: TextStyle(
                                            fontSize: 14,
                                            fontWeight: FontWeight.w600,
                                            color: AppColors.neutral500,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  const SizedBox(height: 28),

                                  // Footer Link: Belum punya akun? Sign Up
                                  Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.center,
                                    children: [
                                      const Text(
                                        'Belum punya akun? ',
                                        style: TextStyle(
                                            color: AppColors.neutral500,
                                            fontSize: 13),
                                      ),
                                      GestureDetector(
                                        onTap: () {
                                          Navigator.pushReplacementNamed(
                                            context,
                                            '/signup',
                                            arguments: argsRole,
                                          );
                                        },
                                        child: const Text(
                                          'Sign Up',
                                          style: TextStyle(
                                            color: AppColors.statusInfo,
                                            fontWeight: FontWeight.bold,
                                            fontSize: 13,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 20),
                                ],
                              ),
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

  Widget _buildGoogleGLogo() {
    const String googleSvgRaw = '''
<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 48 48" width="22" height="22">
  <path fill="#EA4335" d="M24 9.5c3.54 0 6.71 1.22 9.21 3.6l6.85-6.85C35.9 2.38 30.47 0 24 0 14.62 0 6.51 5.38 2.56 13.22l7.98 6.19C12.43 13.72 17.74 9.5 24 9.5z"/>
  <path fill="#4285F4" d="M46.98 24.55c0-1.57-.15-3.09-.38-4.55H24v9.02h12.94c-.58 2.96-2.26 5.48-4.78 7.18l7.73 6c4.51-4.18 7.09-10.36 7.09-17.65z"/>
  <path fill="#FBBC05" d="M10.53 28.59c-.48-1.45-.76-2.99-.76-4.59s.27-3.14.76-4.59l-7.98-6.19C.92 16.46 0 20.12 0 24c0 3.88.92 7.54 2.56 10.78l7.97-6.19z"/>
  <path fill="#34A853" d="M24 48c6.48 0 11.93-2.13 15.89-5.81l-7.73-6c-2.15 1.45-4.92 2.3-8.16 2.3-6.26 0-11.57-4.22-13.47-9.91l-7.98 6.19C6.51 42.62 14.62 48 24 48z"/>
</svg>
''';

    return SvgPicture.string(
      googleSvgRaw,
      width: 22,
      height: 22,
    );
  }
}
