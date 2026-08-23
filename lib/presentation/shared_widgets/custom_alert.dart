import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';

enum AlertType {
  information,
  success,
  warning,
  error,
}

/// Custom Alert Card widget matching modern soft-glow design
class CustomAlertCard extends StatelessWidget {
  final AlertType type;
  final String title;
  final String message;
  final VoidCallback? onClose;
  final EdgeInsetsGeometry? margin;

  const CustomAlertCard({
    super.key,
    required this.type,
    required this.title,
    required this.message,
    this.onClose,
    this.margin,
  });

  Color get _primaryColor {
    switch (type) {
      case AlertType.information:
        return const Color(0xFF0284C7); // Soft Ocean Blue
      case AlertType.success:
        return const Color(0xFF16A34A); // Vibrant Green
      case AlertType.warning:
        return const Color(0xFFD97706); // Amber / Warm Orange
      case AlertType.error:
        return const Color(0xFFDC2626); // Crimson Red
    }
  }

  Color get _glowColor {
    switch (type) {
      case AlertType.information:
        return const Color(0xFFE0F2FE); // Very light cyan blue
      case AlertType.success:
        return const Color(0xFFDCFCE7); // Very light mint green
      case AlertType.warning:
        return const Color(0xFFFEF3C7); // Very light warm amber
      case AlertType.error:
        return const Color(0xFFFEE2E2); // Very light soft red
    }
  }

  IconData get _icon {
    switch (type) {
      case AlertType.information:
        return Icons.info_outline_rounded;
      case AlertType.success:
        return Icons.check_circle_outline_rounded;
      case AlertType.warning:
        return Icons.warning_amber_rounded;
      case AlertType.error:
        return Icons.error_outline_rounded;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: margin ?? const EdgeInsets.symmetric(vertical: 6),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 16,
            spreadRadius: 0,
            offset: const Offset(0, 4),
          ),
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 4,
            spreadRadius: 0,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(18),
        child: Stack(
          children: [
            // Left Soft Ambient Glow Effect
            Positioned(
              left: -20,
              top: -20,
              child: Container(
                width: 120,
                height: 120,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(
                    colors: [
                      _glowColor.withValues(alpha: 0.95),
                      _glowColor.withValues(alpha: 0.4),
                      AppColors.white.withValues(alpha: 0.0),
                    ],
                    stops: const [0.0, 0.55, 1.0],
                  ),
                ),
              ),
            ),

            // Card Main Content Layout
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  // Icon Box
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: AppColors.white,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                        color: _glowColor.withValues(alpha: 0.8),
                        width: 1.2,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: _primaryColor.withValues(alpha: 0.08),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Center(
                      child: Icon(
                        _icon,
                        color: _primaryColor,
                        size: 22,
                      ),
                    ),
                  ),
                  const SizedBox(width: 14),

                  // Title & Description Column
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          title,
                          style: const TextStyle(
                            color: AppColors.neutral900,
                            fontSize: 15,
                            fontWeight: FontWeight.w700,
                            letterSpacing: -0.2,
                          ),
                        ),
                        const SizedBox(height: 3),
                        Text(
                          message,
                          style: TextStyle(
                            color: AppColors.neutral500.withValues(alpha: 0.9),
                            fontSize: 13,
                            fontWeight: FontWeight.w400,
                            height: 1.35,
                          ),
                        ),
                      ],
                    ),
                  ),

                  // Close Button (if onClose provided)
                  if (onClose != null) ...[
                    const SizedBox(width: 8),
                    InkWell(
                      onTap: onClose,
                      borderRadius: BorderRadius.circular(20),
                      child: Padding(
                        padding: const EdgeInsets.all(4.0),
                        child: Icon(
                          Icons.close_rounded,
                          color: AppColors.neutral500.withValues(alpha: 0.5),
                          size: 18,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Utility helper class to trigger modern design alerts easily via SnackBar or Dialog
class AppAlert {
  AppAlert._();

  /// Shows custom alert SnackBar floating on top/bottom of screen
  static void showSnackBar(
    BuildContext context, {
    required AlertType type,
    required String title,
    required String message,
    Duration duration = const Duration(seconds: 4),
  }) {
    ScaffoldMessenger.of(context).clearSnackBars();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        elevation: 0,
        backgroundColor: Colors.transparent,
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        padding: EdgeInsets.zero,
        duration: duration,
        content: CustomAlertCard(
          type: type,
          title: title,
          message: message,
          onClose: () {
            ScaffoldMessenger.of(context).hideCurrentSnackBar();
          },
        ),
      ),
    );
  }

  /// Helper methods for quick invocation
  static void info(BuildContext context, {required String title, required String message}) {
    showSnackBar(context, type: AlertType.information, title: title, message: message);
  }

  static void success(BuildContext context, {required String title, required String message}) {
    showSnackBar(context, type: AlertType.success, title: title, message: message);
  }

  static void warning(BuildContext context, {required String title, required String message}) {
    showSnackBar(context, type: AlertType.warning, title: title, message: message);
  }

  static void error(BuildContext context, {required String title, required String message}) {
    showSnackBar(context, type: AlertType.error, title: title, message: message);
  }
}
