import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  // Phase 1: logoLK.png Zoom Out & Fade In (0.0 -> 0.35)
  late Animation<double> _lkScale;
  late Animation<double> _lkOpacity;

  // Phase 2: logoLK.png Slide Left (0.35 -> 0.60)
  late Animation<Offset> _lkSlideLeft;

  // Phase 3: LaporKita.png Fade In & Slide In (0.55 -> 0.80)
  late Animation<double> _laporKitaOpacity;
  late Animation<Offset> _laporKitaSlide;

  // Phase 4: Tagline Fade In & Slide Up (0.70 -> 0.95)
  late Animation<double> _taglineOpacity;
  late Animation<double> _taglineSlide;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 3400),
    );

    // 1. logoLK.png Zoom Out (scales down from 2.2 to 1.0) & Fades In
    _lkOpacity = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.0, 0.25, curve: Curves.easeIn),
      ),
    );
    _lkScale = Tween<double>(begin: 2.2, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.0, 0.38, curve: Curves.easeOutBack),
      ),
    );

    // 2. logoLK.png Slides to the Left
    _lkSlideLeft =
        Tween<Offset>(begin: Offset.zero, end: const Offset(-0.25, 0.0)).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.38, 0.60, curve: Curves.easeInOutCubic),
      ),
    );

    // 3. LaporKita.png Appears (Fades in & Slides right beside logoLK)
    _laporKitaOpacity = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.55, 0.80, curve: Curves.easeIn),
      ),
    );
    _laporKitaSlide =
        Tween<Offset>(begin: const Offset(0.2, 0.0), end: Offset.zero).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.55, 0.80, curve: Curves.easeOutCubic),
      ),
    );

    // 4. Tagline Fades In & Slides Up
    _taglineOpacity = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.70, 0.92, curve: Curves.easeIn),
      ),
    );
    _taglineSlide = Tween<double>(begin: 20.0, end: 0.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.70, 0.92, curve: Curves.easeOutCubic),
      ),
    );

    // Start animation sequence and navigate to Get Started screen
    _controller.forward().then((_) {
      _navigateToHome();
    });
  }

  void _navigateToHome() {
    if (mounted) {
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
    return Scaffold(
      backgroundColor: AppColors.greenPrimary,
      body: Stack(
        children: [
          // Center Animation Area
          Center(
            child: AnimatedBuilder(
              animation: _controller,
              builder: (context, child) {
                return Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // 1. logoLK.png (Zoom out then slide left)
                    FractionalTranslation(
                      translation: _lkSlideLeft.value,
                      child: Opacity(
                        opacity: _lkOpacity.value,
                        child: Transform.scale(
                          scale: _lkScale.value,
                          child: Image.asset(
                            'assets/images/logoLK.png',
                            width: 80,
                            height: 80,
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
                    ),

                    // 2. LaporKita.png (Appears next to logoLK)
                    if (_laporKitaOpacity.value > 0.0) ...[
                      const SizedBox(width: 8),
                      FractionalTranslation(
                        translation: _laporKitaSlide.value,
                        child: Opacity(
                          opacity: _laporKitaOpacity.value,
                          child: Image.asset(
                            'assets/images/LaporKita.png',
                            height: 40,
                            fit: BoxFit.contain,
                            errorBuilder: (context, error, stackTrace) =>
                                const Text(
                              'LaporKita',
                              style: TextStyle(
                                color: AppColors.white,
                                fontSize: 32,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
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
                    opacity: _taglineOpacity.value,
                    child: Transform.translate(
                      offset: Offset(0.0, _taglineSlide.value),
                      child: const Text(
                        'Suaramu untuk kota yang lebih baik.',
                        style: TextStyle(
                          color: AppColors.white,
                          fontSize: 14,
                          fontWeight: FontWeight.w400,
                          letterSpacing: 0.5,
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
    );
  }
}
