import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../core/theme/app_colors.dart';
import '../../auth/bloc/auth_bloc.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  bool _animationCompleted = false;

  // Phase 1: Logo LK Entrance (Fade in & gentle scale settle)
  late Animation<double> _logoOpacity;
  late Animation<double> _logoScale;

  // Phase 2: Smooth Expand & Reveal of Brand Text (No layout jump)
  late Animation<double> _expandWidth;
  late Animation<double> _textOpacity;
  late Animation<double> _textSlide;

  // Phase 3: Tagline Entrance (Fade in & subtle upward glide)
  late Animation<double> _taglineOpacity;
  late Animation<double> _taglineSlide;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2800),
    );

    // 1. Logo LK Fade In & Gentle Scale Settle (0.00 -> 0.35)
    _logoOpacity = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.00, 0.28, curve: Curves.easeOut),
      ),
    );
    _logoScale = Tween<double>(begin: 1.25, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.00, 0.35, curve: Curves.easeOutCubic),
      ),
    );

    // 2. Expand Width Factor (Smoothly slides Logo to the left and unrolls Text area) (0.35 -> 0.68)
    _expandWidth = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.35, 0.68, curve: Curves.easeInOutCubic),
      ),
    );

    // 3. Text Fade In & Slide out from behind the logo (0.38 -> 0.68)
    _textOpacity = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.40, 0.65, curve: Curves.easeOut),
      ),
    );
    _textSlide = Tween<double>(begin: -24.0, end: 0.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.35, 0.68, curve: Curves.easeOutCubic),
      ),
    );

    // 4. Tagline Fade In & Upward Slide (0.68 -> 0.88)
    _taglineOpacity = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.68, 0.86, curve: Curves.easeOut),
      ),
    );
    _taglineSlide = Tween<double>(begin: 16.0, end: 0.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.68, 0.88, curve: Curves.easeOutCubic),
      ),
    );
    // Start animation sequence and navigate based on auth state when complete
    _controller.forward().then((_) {
      if (mounted) {
        setState(() => _animationCompleted = true);
        _performNavigation(context.read<AuthBloc>().state);
      }
    });
  }

  void _performNavigation(AuthState state) {
    if (!mounted || !_animationCompleted) return;

    if (state is AuthAuthenticated) {
      if (state.user.role.isCommandCenter) {
        Navigator.of(context).pushReplacementNamed('/command-center');
      } else {
        Navigator.of(context).pushReplacementNamed('/citizen');
      }
    } else if (state is AuthUnauthenticated || state is AuthError || state is AuthPhoneNotVerified) {
      Navigator.of(context).pushReplacementNamed('/get-started');
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<AuthBloc, AuthState>(
      listener: (context, state) {
        _performNavigation(state);
      },
      child: Scaffold(
        body: Container(
          decoration: const BoxDecoration(
            gradient: RadialGradient(
              center: Alignment(0.0, -0.05),
              radius: 1.15,
              colors: [
                Color(0xFF23A859), // subtle luminous center highlight
                AppColors.greenPrimary, // pure brand green
                Color(0xFF168041), // elegant vignette at edges
              ],
              stops: [0.0, 0.65, 1.0],
            ),
          ),
          child: Stack(
            children: [
              // Center Brand Lockup Animation
              Center(
                child: AnimatedBuilder(
                  animation: _controller,
                  builder: (context, child) {
                    return Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        // 1. logoLK.png (Enters centered, then naturally glides left as row expands)
                        Opacity(
                          opacity: _logoOpacity.value.clamp(0.0, 1.0),
                          child: Transform.scale(
                            scale: _logoScale.value,
                            child: Image.asset(
                              'assets/images/logoLK.png',
                              width: 76,
                              height: 76,
                              fit: BoxFit.contain,
                              errorBuilder: (context, error, stackTrace) => Container(
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: AppColors.white,
                                  borderRadius: BorderRadius.circular(16),
                                ),
                                child: const Text(
                                  'LK',
                                  style: TextStyle(
                                    color: AppColors.greenPrimary,
                                    fontSize: 28,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),

                        // 2. LaporKita text (Smoothly unrolls/reveals from the logo with zero layout jump)
                        ClipRect(
                          child: Align(
                            alignment: Alignment.centerLeft,
                            widthFactor: _expandWidth.value.clamp(0.0, 1.0),
                            child: Padding(
                              padding: const EdgeInsets.only(left: 12.0),
                              child: Opacity(
                                opacity: _textOpacity.value.clamp(0.0, 1.0),
                                child: Transform.translate(
                                  offset: Offset(_textSlide.value, 0.0),
                                  child: Image.asset(
                                    'assets/images/LaporKita.png',
                                    height: 38,
                                    fit: BoxFit.contain,
                                    errorBuilder: (context, error, stackTrace) =>
                                        const Text(
                                      'LaporKita',
                                      style: TextStyle(
                                        color: AppColors.white,
                                        fontSize: 32,
                                        fontWeight: FontWeight.bold,
                                        letterSpacing: -0.5,
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    );
                  },
                ),
              ),

              // Bottom Tagline Animation
              Align(
                alignment: Alignment.bottomCenter,
                child: Padding(
                  padding: const EdgeInsets.only(bottom: 48.0),
                  child: AnimatedBuilder(
                    animation: _controller,
                    builder: (context, child) {
                      return Opacity(
                        opacity: _taglineOpacity.value.clamp(0.0, 1.0),
                        child: Transform.translate(
                          offset: Offset(0.0, _taglineSlide.value),
                          child: const Text(
                            'Suaramu untuk kota yang lebih baik.',
                            style: TextStyle(
                              color: AppColors.white,
                              fontSize: 14,
                              fontWeight: FontWeight.w400,
                              letterSpacing: 0.6,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
