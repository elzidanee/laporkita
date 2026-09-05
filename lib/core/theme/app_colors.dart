import 'package:flutter/material.dart';

class AppColors {
  // ── Brand Colors ────────────────────────────────────────────────────────────
  static const Color white        = Color(0xFFFFFFFF);
  static const Color greenDark    = Color(0xFF206C57);
  static const Color greenPrimary = Color(0xFF1D9C51);
  static const Color greenLight   = Color(0xFFB9D19E);

  // ── Semantic / Status Colors ───────────────────────────────────────────
  static const Color statusPending = Color(0xFFF5A623); // Amber
  static const Color statusDanger  = Color(0xFFE53935); // Red (standardised)
  static const Color statusSuccess = Color(0xFF1D9C51); // = greenPrimary
  static const Color statusInfo    = Color(0xFF2B82C4); // Blue (standardised)
  static const Color statusWarning = Color(0xFFE68A00); // Deep amber

  // ── Light Status Backgrounds (surface tints) ─────────────────────────
  static const Color surfaceDanger  = Color(0xFFFFEBEB);
  static const Color surfaceWarning = Color(0xFFFFF8E6);
  static const Color surfaceSuccess = Color(0xFFE6F7ED);
  static const Color surfaceInfo    = Color(0xFFE8F3FF);

  // ── Neutral / Grey Scale ───────────────────────────────────────────────
  static const Color neutral900 = Color(0xFF1A1A1A);
  static const Color neutral700 = Color(0xFF565657);
  static const Color neutral500 = Color(0xFF6B6B6B);
  static const Color neutral400 = Color(0xFF8F8F8F);
  static const Color neutral300 = Color(0xFFBDBDBD);
  static const Color neutral200 = Color(0xFFE0DFDF);
  static const Color neutral100 = Color(0xFFF2F4F3);
  static const Color neutral50  = Color(0xFFF0F4F8);

  // ── Borders & Dividers ───────────────────────────────────────────────
  static const Color border     = Color(0xFFE2E8E4);
  static const Color borderLight = Color(0xFFE8E8E8);

  // ── Navigation & Map Tokens ──────────────────────────────────────────
  static const Color navRouteBlue  = Color(0xFF1565C0); // Rute aktif biru Figma
  static const Color navRouteAlt   = Color(0xFF9E9E9E); // Rute alternatif abu-abu
  static const Color navPuckBorder = Color(0xFF1976D2); // Border indikator posisi user
}
