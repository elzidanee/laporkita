import 'package:flutter/material.dart';
import 'core/theme/app_theme.dart';
import 'presentation/citizen/home/splash_screen.dart';
import 'presentation/citizen/home/get_started_screen.dart';
import 'presentation/citizen/profile/login_screen.dart';
import 'presentation/citizen/profile/sign_up_screen.dart';
import 'presentation/citizen/profile/otp_screen.dart';
import 'presentation/citizen/home/citizen_home_screen.dart';
import 'presentation/citizen/report_detail/report_detail_screen.dart';
import 'presentation/citizen/camera/camera_capture_screen.dart';
import 'presentation/citizen/camera/similar_report_screen.dart';
import 'presentation/citizen/camera/report_confirmation_screen.dart';
import 'presentation/citizen/camera/ai_verification_screen.dart';
import 'presentation/citizen/camera/report_success_screen.dart';
import 'presentation/citizen/camera/new_report_form_screen.dart';
import 'presentation/command_center/dashboard/dashboard_screen.dart';
import 'presentation/citizen/tracking/tracking_progress_screen.dart';
import 'presentation/citizen/tracking/foto_progress_screen.dart';
void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'LaporKita',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,

      // Initial route starts with Splash Screen
      initialRoute: '/',

      // Use onGenerateRoute for custom smooth transitions on every named route
      onGenerateRoute: (settings) {
        return _buildSmoothRoute(settings);
      },
    );
  }
}

/// Maps route name to Widget, including passing route arguments
Widget? _resolveScreen(RouteSettings settings) {
  switch (settings.name) {
    case '/':
      return const SplashScreen();
    case '/get-started':
      return const GetStartedScreen();
    case '/login':
      return const LoginScreen();
    case '/signup':
      return const SignUpScreen();
    case '/otp':
      return const OtpScreen();
    case '/citizen':
      return const CitizenHomeScreen();
    case '/report-detail':
      return const ReportDetailScreen();
    case '/camera':
      return const CameraCaptureScreen();
    case '/similar-reports':
      return const SimilarReportScreen();
    case '/report-confirmation':
      return const ReportConfirmationScreen();
    case '/ai-verification':
      return const AiVerificationScreen();
    case '/report-success':
      return const ReportSuccessScreen();
    case '/new-report-form':
      return const NewReportFormScreen();
    case '/command-center':
      return const CommandCenterDashboard();
    case '/tracking-progress':
      return const TrackingProgressScreen();
    case '/foto-progress':
      return const FotoProgressScreen();
    default:
      return null;
  }
}

/// Builds a custom [PageRouteBuilder] with smooth slide + fade transition
PageRouteBuilder _buildSmoothRoute(RouteSettings settings) {
  final screen = _resolveScreen(settings) ?? const SplashScreen();

  // Auth screens (login/signup/otp) slide up from bottom — feels like a modal
  final isAuthScreen = settings.name == '/login' ||
      settings.name == '/signup' ||
      settings.name == '/otp';

  return PageRouteBuilder(
    settings: settings,
    pageBuilder: (context, animation, secondaryAnimation) => screen,
    transitionDuration: const Duration(milliseconds: 420),
    reverseTransitionDuration: const Duration(milliseconds: 320),
    transitionsBuilder: (context, animation, secondaryAnimation, child) {
      // Slide direction: auth screens slide up, others slide from right
      final beginOffset =
          isAuthScreen ? const Offset(0.0, 0.08) : const Offset(0.06, 0.0);

      final slideAnimation = Tween<Offset>(
        begin: beginOffset,
        end: Offset.zero,
      ).animate(CurvedAnimation(
        parent: animation,
        curve: Curves.easeOutCubic,
      ));

      final fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
        CurvedAnimation(
          parent: animation,
          curve: const Interval(0.0, 0.75, curve: Curves.easeIn),
        ),
      );

      // Outgoing page fades out slightly
      final outFadeAnimation = Tween<double>(begin: 1.0, end: 0.92).animate(
        CurvedAnimation(
          parent: secondaryAnimation,
          curve: Curves.easeIn,
        ),
      );

      return FadeTransition(
        opacity: outFadeAnimation,
        child: SlideTransition(
          position: slideAnimation,
          child: FadeTransition(
            opacity: fadeAnimation,
            child: child,
          ),
        ),
      );
    },
  );
}
