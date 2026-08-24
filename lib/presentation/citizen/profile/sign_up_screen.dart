import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:laporkita/presentation/citizen/profile/login_screen.dart';
import '../../../core/theme/app_colors.dart';
import '../../shared_widgets/custom_alert.dart';
import '../../auth/bloc/auth_bloc.dart';
import '../home/get_started_screen.dart'; // Reuse MapBackgroundPainter & TopCurveClipper

class SignUpScreen extends StatefulWidget {
  const SignUpScreen({super.key});

  @override
  State<SignUpScreen> createState() => _SignUpScreenState();
}

class _SignUpScreenState extends State<SignUpScreen> {
  final _formKey = GlobalKey<FormState>();
  final _fullNameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  bool _isPasswordObscured = true;
  bool _isConfirmPasswordObscured = true;

  @override
  void dispose() {
    _fullNameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  void _handleSignUp() {
    if (_formKey.currentState!.validate()) {
      FocusScope.of(context).unfocus();
      final rawPhone = _phoneController.text.trim();
      final formattedPhone = rawPhone.startsWith('+')
          ? rawPhone
          : (rawPhone.startsWith('0')
              ? '+62${rawPhone.substring(1)}'
              : '+62$rawPhone');

      context.read<AuthBloc>().add(
            AuthRegisterRequested(
              fullName: _fullNameController.text.trim(),
              email: _emailController.text.trim(),
              phoneNumber: formattedPhone,
              password: _passwordController.text,
            ),
          );
    }
  }

  @override
  Widget build(BuildContext context) {
    final argsRole =
        ModalRoute.of(context)?.settings.arguments as String? ?? 'Citizen';

    return BlocConsumer<AuthBloc, AuthState>(
      listener: (context, state) {
        if (state is AuthRegistered) {
          AppAlert.success(
            context,
            title: 'Pendaftaran Berhasil',
            message: state.message,
          );
          Navigator.pushNamed(
            context,
            '/otp',
            arguments: {
              'role': argsRole,
              'userId': state.userId,
              'phone': state.phoneNumber,
            },
          );
        } else if (state is AuthError) {
          AppAlert.error(
            context,
            title: 'Pendaftaran Gagal',
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
                                              const LoginScreen(),
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
                                  const SizedBox(height: 16),

                                  // Title & Subtitle
                                  Text(
                                    'Sign Up',
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
                                    'Buat akun untuk mulai melaporkan\ndan berkontribusi',
                                    style: Theme.of(context)
                                        .textTheme
                                        .bodyMedium
                                        ?.copyWith(
                                          color: AppColors.neutral500,
                                          fontSize: 14,
                                        ),
                                  ),
                                  const SizedBox(height: 24),

                                  // Field 1: Nama lengkap
                                  _buildLabel('Nama lengkap'),
                                  const SizedBox(height: 8),
                                  TextFormField(
                                    controller: _fullNameController,
                                    decoration: _buildInputDecoration(
                                      hintText: 'Masukan nama lengkap',
                                      prefixIcon: Icons.person_outline,
                                    ),
                                    validator: (value) {
                                      if (value == null ||
                                          value.trim().isEmpty) {
                                        return 'Nama lengkap harus diisi';
                                      }
                                      return null;
                                    },
                                  ),
                                  const SizedBox(height: 16),

                                  // Field 2: Email
                                  _buildLabel('Email'),
                                  const SizedBox(height: 8),
                                  TextFormField(
                                    controller: _emailController,
                                    keyboardType: TextInputType.emailAddress,
                                    decoration: _buildInputDecoration(
                                      hintText: 'Masukan email',
                                      prefixIcon: Icons.mail_outline,
                                    ),
                                    validator: (value) {
                                      if (value == null ||
                                          value.trim().isEmpty) {
                                        return 'Email harus diisi';
                                      }
                                      if (!value.contains('@')) {
                                        return 'Format email tidak valid';
                                      }
                                      return null;
                                    },
                                  ),
                                  const SizedBox(height: 16),

                                  // Field 3: No. HP
                                  _buildLabel('No. HP'),
                                  const SizedBox(height: 8),
                                  TextFormField(
                                    controller: _phoneController,
                                    keyboardType: TextInputType.phone,
                                    decoration: _buildInputDecoration(
                                      hintText: 'Masukan nomor HP (misal: 08123456789)',
                                      prefixIcon: Icons.phone_outlined,
                                    ),
                                    validator: (value) {
                                      if (value == null ||
                                          value.trim().isEmpty) {
                                        return 'Nomor HP harus diisi';
                                      }
                                      return null;
                                    },
                                  ),
                                  const SizedBox(height: 16),

                                  // Field 4: Kata Sandi
                                  _buildLabel('Kata Sandi'),
                                  const SizedBox(height: 8),
                                  TextFormField(
                                    controller: _passwordController,
                                    obscureText: _isPasswordObscured,
                                    decoration: _buildInputDecoration(
                                      hintText:
                                          'Buat kata sandi (min. 8 karakter, huruf & angka)',
                                      prefixIcon: Icons.lock_outline,
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
                                    ),
                                    validator: (value) {
                                      if (value == null || value.isEmpty) {
                                        return 'Kata sandi harus diisi';
                                      }
                                      if (value.length < 8) {
                                        return 'Kata sandi minimal 8 karakter';
                                      }
                                      if (!RegExp(r'^(?=.*[A-Za-z])(?=.*\d).+$')
                                          .hasMatch(value)) {
                                        return 'Kata sandi harus kombinasi huruf dan angka';
                                      }
                                      return null;
                                    },
                                  ),
                                  const SizedBox(height: 16),

                                  // Field 5: Konfirmasi Kata Sandi
                                  _buildLabel('Konfirmasi Kata Sandi'),
                                  const SizedBox(height: 8),
                                  TextFormField(
                                    controller: _confirmPasswordController,
                                    obscureText: _isConfirmPasswordObscured,
                                    decoration: _buildInputDecoration(
                                      hintText: 'Ulangi kata sandi',
                                      prefixIcon: Icons.lock_outline,
                                      suffixIcon: IconButton(
                                        icon: Icon(
                                          _isConfirmPasswordObscured
                                              ? Icons.visibility_off_outlined
                                              : Icons.visibility_outlined,
                                          color: AppColors.neutral500,
                                          size: 20,
                                        ),
                                        onPressed: () {
                                          setState(() {
                                            _isConfirmPasswordObscured =
                                                !_isConfirmPasswordObscured;
                                          });
                                        },
                                      ),
                                    ),
                                    validator: (value) {
                                      if (value == null || value.isEmpty) {
                                        return 'Konfirmasi kata sandi harus diisi';
                                      }
                                      if (value != _passwordController.text) {
                                        return 'Konfirmasi kata sandi tidak cocok';
                                      }
                                      return null;
                                    },
                                  ),
                                  const SizedBox(height: 28),

                                  // Sign Up Primary Button
                                  ElevatedButton(
                                    onPressed: isLoading ? null : _handleSignUp,
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
                                            'Sign Up',
                                            style: TextStyle(
                                              fontSize: 16,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                  ),
                                  const SizedBox(height: 24),

                                  // Footer Link: Sudah punya akun? Login
                                  Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.center,
                                    children: [
                                      const Text(
                                        'Sudah punya akun? ',
                                        style: TextStyle(
                                          color: AppColors.neutral500,
                                          fontSize: 13,
                                        ),
                                      ),
                                      GestureDetector(
                                        onTap: () {
                                          Navigator.pushReplacementNamed(
                                            context,
                                            '/login',
                                            arguments: argsRole,
                                          );
                                        },
                                        child: const Text(
                                          'Login',
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

  Widget _buildLabel(String text) {
    return Text(
      text,
      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
            fontWeight: FontWeight.w600,
            color: AppColors.neutral900,
          ),
    );
  }

  InputDecoration _buildInputDecoration({
    required String hintText,
    required IconData prefixIcon,
    Widget? suffixIcon,
  }) {
    return InputDecoration(
      hintText: hintText,
      hintStyle: const TextStyle(color: AppColors.neutral500, fontSize: 13),
      prefixIcon: Icon(prefixIcon, color: AppColors.neutral500, size: 20),
      suffixIcon: suffixIcon,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: AppColors.border),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: AppColors.border),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide:
            const BorderSide(color: AppColors.greenPrimary, width: 1.5),
      ),
    );
  }
}
