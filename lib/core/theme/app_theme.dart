import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'app_colors.dart';

class AppTheme {
  // Light Theme Definition
  static ThemeData get lightTheme {
    final baseTextTheme = GoogleFonts.poppinsTextTheme(ThemeData.light().textTheme);

    return ThemeData(
      useMaterial3: true,
      colorScheme: ColorScheme.fromSeed(
        seedColor: AppColors.greenPrimary,
        primary: AppColors.greenPrimary,
        secondary: AppColors.greenLight,
        tertiary: AppColors.greenDark,
        surface: AppColors.white,
        error: AppColors.statusDanger,
        brightness: Brightness.light,
      ),
      scaffoldBackgroundColor: AppColors.neutral100,
      
      // Define typography based on design.md
      textTheme: baseTextTheme.copyWith(
        displayLarge: baseTextTheme.displayLarge?.copyWith(
          fontSize: 28,
          fontWeight: FontWeight.bold,
          color: AppColors.neutral900,
        ),
        headlineLarge: baseTextTheme.headlineLarge?.copyWith(
          fontSize: 22,
          fontWeight: FontWeight.bold,
          color: AppColors.neutral900,
        ),
        headlineMedium: baseTextTheme.headlineMedium?.copyWith(
          fontSize: 18,
          fontWeight: FontWeight.bold,
          color: AppColors.neutral900,
        ),
        bodyLarge: baseTextTheme.bodyLarge?.copyWith(
          fontSize: 14,
          fontWeight: FontWeight.w600, // Body Bold
          color: AppColors.neutral900,
        ),
        bodyMedium: baseTextTheme.bodyMedium?.copyWith(
          fontSize: 14,
          fontWeight: FontWeight.normal, // Body Regular
          color: AppColors.neutral900,
        ),
        bodySmall: baseTextTheme.bodySmall?.copyWith(
          fontSize: 12,
          fontWeight: FontWeight.normal, // Caption
          color: AppColors.neutral500,
        ),
        labelLarge: baseTextTheme.labelLarge?.copyWith(
          fontSize: 14,
          fontWeight: FontWeight.w600, // Button Text
          color: AppColors.white,
        ),
      ),

      // Custom button themes
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.greenPrimary,
          foregroundColor: AppColors.white,
          elevation: 0,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(999), // pill shape
          ),
          textStyle: GoogleFonts.poppins(
            fontSize: 14,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.greenPrimary,
          side: const BorderSide(color: AppColors.greenPrimary, width: 1.5),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(999), // pill shape
          ),
          textStyle: GoogleFonts.poppins(
            fontSize: 14,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),

      // Card theme
      cardTheme: CardThemeData(
        color: AppColors.white,
        elevation: 1,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: const BorderSide(color: AppColors.border, width: 1),
        ),
      ),

      // App bar theme
      appBarTheme: AppBarTheme(
        backgroundColor: AppColors.greenPrimary,
        foregroundColor: AppColors.white,
        elevation: 0,
        centerTitle: true,
        titleTextStyle: GoogleFonts.poppins(
          fontSize: 20,
          fontWeight: FontWeight.bold,
          color: AppColors.white,
        ),
      ),

      // Smooth Page Transitions across all target platforms
      pageTransitionsTheme: const PageTransitionsTheme(
        builders: {
          TargetPlatform.android: CupertinoPageTransitionsBuilder(),
          TargetPlatform.iOS: CupertinoPageTransitionsBuilder(),
          TargetPlatform.windows: CupertinoPageTransitionsBuilder(),
          TargetPlatform.macOS: CupertinoPageTransitionsBuilder(),
          TargetPlatform.linux: CupertinoPageTransitionsBuilder(),
        },
      ),
    );
  }
}
