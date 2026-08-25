import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
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
import 'presentation/command_center/dashboard/government_dashboard_screen.dart';
import 'presentation/command_center/dashboard/operator_dashboard_screen.dart';
import 'presentation/command_center/dashboard/admin_dashboard_screen.dart';
import 'presentation/command_center/policy_simulator/policy_simulator_screen.dart';
import 'presentation/citizen/tracking/tracking_progress_screen.dart';
import 'presentation/citizen/tracking/foto_progress_screen.dart';
import 'presentation/citizen/validation/beri_validasi_screen.dart';
import 'presentation/citizen/validation/validation_success_screen.dart';
import 'presentation/auth/bloc/auth_bloc.dart';
import 'presentation/reports/bloc/report_bloc.dart';
import 'data/repositories/auth_repository.dart';
import 'data/repositories/report_repository.dart';
import 'data/repositories/category_repository.dart';
import 'data/repositories/policy_simulator_repository.dart';
import 'data/repositories/prediction_repository.dart';
import 'data/repositories/notification_repository.dart';
import 'data/models/report_model.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiRepositoryProvider(
      providers: [
        RepositoryProvider(create: (_) => AuthRepository()),
        RepositoryProvider(create: (_) => ReportRepository()),
        RepositoryProvider(create: (_) => CategoryRepository()),
        RepositoryProvider(create: (_) => PolicySimulatorRepository()),
        RepositoryProvider(create: (_) => PredictionRepository()),
        RepositoryProvider(create: (_) => NotificationRepository()),
      ],
      child: MultiBlocProvider(
        providers: [
          BlocProvider(
            create: (ctx) => AuthBloc(
              authRepository: ctx.read<AuthRepository>(),
            )..add(const AuthCheckRequested()),
          ),
          BlocProvider(
            create: (ctx) => ReportBloc(
              reportRepository: ctx.read<ReportRepository>(),
            ),
          ),
          BlocProvider(
            create: (ctx) => CategoryBloc(
              categoryRepository: ctx.read<CategoryRepository>(),
            )..add(const CategoryLoadRequested()),
          ),
        ],
        child: MaterialApp(
          title: 'LaporKita',
          debugShowCheckedModeBanner: false,
          theme: AppTheme.lightTheme,
          initialRoute: '/',
          onGenerateRoute: (settings) {
            return _buildSmoothRoute(settings);
          },
        ),
      ),
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
      Map<String, dynamic>? detailData;
      if (settings.arguments is Map<String, dynamic>) {
        detailData = settings.arguments as Map<String, dynamic>;
      } else if (settings.arguments is ReportModel) {
        detailData = {'reportModel': settings.arguments};
      }
      return ReportDetailScreen(reportData: detailData);
    case '/camera':
      return const CameraCaptureScreen();
    case '/similar-reports':
      return const SimilarReportScreen();
    case '/report-confirmation':
      return const ReportConfirmationScreen();
    case '/ai-verification':
      return const AiVerificationScreen();
    case '/report-success':
      Map<String, dynamic>? successData;
      if (settings.arguments is Map<String, dynamic>) {
        successData = settings.arguments as Map<String, dynamic>;
      }
      return ReportSuccessScreen(reportData: successData);
    case '/new-report-form':
      return const NewReportFormScreen();
    case '/command-center':
      return const CommandCenterDashboard();
    case '/government-dashboard':
      return const GovernmentDashboardScreen();
    case '/operator-dashboard':
      return const OperatorDashboardScreen();
    case '/admin-dashboard':
      return const AdminDashboardScreen();
    case '/policy-simulator':
      return const PolicySimulatorScreen();
    case '/tracking-progress':
      Map<String, dynamic>? trackingData;
      if (settings.arguments is Map<String, dynamic>) {
        trackingData = settings.arguments as Map<String, dynamic>;
      } else if (settings.arguments is ReportModel) {
        trackingData = {'reportModel': settings.arguments};
      }
      return TrackingProgressScreen(reportData: trackingData);
    case '/foto-progress':
      Map<String, dynamic>? fotoData;
      if (settings.arguments is Map<String, dynamic>) {
        fotoData = settings.arguments as Map<String, dynamic>;
      }
      return FotoProgressScreen(reportData: fotoData);
    case '/give-validation':
      Map<String, dynamic>? valData;
      if (settings.arguments is Map<String, dynamic>) {
        valData = settings.arguments as Map<String, dynamic>;
      }
      return BeriValidasiScreen(reportData: valData);
    case '/validation-success':
      Map<String, dynamic>? valSuccessData;
      if (settings.arguments is Map<String, dynamic>) {
        valSuccessData = settings.arguments as Map<String, dynamic>;
      }
      return ValidationSuccessScreen(reportData: valSuccessData);
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
