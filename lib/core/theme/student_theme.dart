import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'branding_provider.dart';

class StudentTheme {
  // Dark Theme Palette
  static const Color backgroundDark = Color(0xFF0A0F1D);
  static const Color surfaceCard = Color(0xFF131C31);
  static const Color surfaceLight = Color(0xFF1E293B);
  static const Color borderDark = Color(0xFF26334D);

  // Typography Colors
  static const Color textPrimary = Color(0xFFF8FAFC);
  static const Color textSecondary = Color(0xFF94A3B8);
  static const Color textMuted = Color(0xFF64748B);

  // Brand Accent Defaults
  static const Color primaryBlue = Color(0xFF0143A3);
  static const Color secondaryTeal = Color(0xFF0D9488);
  static const Color successGreen = Color(0xFF10B981);
  static const Color warningOrange = Color(0xFFF59E0B);
  static const Color dangerRed = Color(0xFFEF4444);

  static ThemeData buildTheme(StudentBrandingModel branding) {
    return getTheme(branding);
  }

  static ThemeData getTheme(StudentBrandingModel branding) {
    final isDark = branding.isDarkMode;
    final primary = branding.primaryColor;
    final accent = branding.secondaryColor;

    final base = ThemeData.dark();
    final cardColor = isDark ? surfaceCard : const Color(0xFF131C31);
    final scaffoldBg = isDark ? backgroundDark : const Color(0xFF0A0F1D);

    return base.copyWith(
      colorScheme: ColorScheme.fromSeed(
        seedColor: primary,
        primary: primary,
        secondary: accent,
        brightness: Brightness.dark,
        surface: cardColor,
        background: scaffoldBg,
      ),
      scaffoldBackgroundColor: scaffoldBg,
      cardColor: cardColor,
      appBarTheme: AppBarTheme(
        backgroundColor: cardColor,
        foregroundColor: textPrimary,
        elevation: 0,
        centerTitle: true,
        titleTextStyle: GoogleFonts.cairo(
          fontSize: 18,
          fontWeight: FontWeight.bold,
          color: textPrimary,
        ),
      ),
      textTheme: GoogleFonts.cairoTextTheme(base.textTheme).apply(
        bodyColor: textPrimary,
        displayColor: textPrimary,
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: primary,
          foregroundColor: Colors.white,
          textStyle: GoogleFonts.cairo(fontWeight: FontWeight.bold),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          elevation: 1,
        ),
      ),
      cardTheme: CardThemeData(
        color: cardColor,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: const BorderSide(color: borderDark, width: 1),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: surfaceLight,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: borderDark),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: borderDark),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: accent, width: 1.5),
        ),
        labelStyle: GoogleFonts.cairo(fontSize: 13, color: textSecondary),
        hintStyle: GoogleFonts.cairo(fontSize: 13, color: textMuted),
      ),
    );
  }
}
