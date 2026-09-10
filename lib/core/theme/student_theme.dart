import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'branding_provider.dart';

class StudentTheme {
  // Light Palette (Default - matching Admin/Staff app)
  static const Color scaffoldLight = Color(0xFFF8FAFC);
  static const Color cardLight = Colors.white;
  static const Color surfaceLight = Color(0xFFF1F5F9);
  static const Color borderLight = Color(0xFFE2E8F0);
  static const Color textPrimaryLight = Color(0xFF0F172A);
  static const Color textSecondaryLight = Color(0xFF64748B);
  static const Color textMutedLight = Color(0xFF94A3B8);

  // Dark Palette (Optional)
  static const Color scaffoldDark = Color(0xFF0B1120);
  static const Color cardDark = Color(0xFF1E293B);
  static const Color surfaceDark = Color(0xFF131C31);
  static const Color borderDark = Color(0xFF334155);
  static const Color textPrimaryDark = Color(0xFFF8FAFC);
  static const Color textSecondaryDark = Color(0xFF94A3B8);
  static const Color textMutedDark = Color(0xFF64748B);

  // Status & Brand Accent Colors
  static const Color successGreen = Color(0xFF10B981);
  static const Color warningOrange = Color(0xFFF59E0B);
  static const Color dangerRed = Color(0xFFEF4444);
  static const Color infoBlue = Color(0xFF3B82F6);

  // Dynamic getters according to context or static fallback
  static Color getScaffoldBg(bool isDark) => isDark ? scaffoldDark : scaffoldLight;
  static Color getCardBg(bool isDark) => isDark ? cardDark : cardLight;
  static Color getSurface(bool isDark) => isDark ? surfaceDark : surfaceLight;
  static Color getBorder(bool isDark) => isDark ? borderDark : borderLight;
  static Color getTextPrimary(bool isDark) => isDark ? textPrimaryDark : textPrimaryLight;
  static Color getTextSecondary(bool isDark) => isDark ? textSecondaryDark : textSecondaryLight;
  static Color getTextMuted(bool isDark) => isDark ? textMutedDark : textMutedLight;

  // Legacy helper aliases for backwards compatibility
  static const Color backgroundDark = scaffoldLight; // now default light
  static const Color surfaceCard = cardLight;
  static const Color textPrimary = textPrimaryLight;
  static const Color textSecondary = textSecondaryLight;
  static const Color textMuted = textMutedLight;

  static ThemeData buildTheme(StudentBrandingModel branding) {
    return getTheme(branding);
  }

  static ThemeData getTheme(StudentBrandingModel branding) {
    final isDark = branding.isDarkMode;
    final primary = branding.primaryColor;
    final accent = branding.secondaryColor;

    final base = isDark ? ThemeData.dark() : ThemeData.light();
    final cardColor = isDark ? cardDark : cardLight;
    final scaffoldBg = isDark ? scaffoldDark : scaffoldLight;
    final borderColor = isDark ? borderDark : borderLight;
    final inputBg = isDark ? surfaceDark : surfaceLight;

    return ThemeData(
      useMaterial3: true,
      brightness: isDark ? Brightness.dark : Brightness.light,
      colorScheme: ColorScheme.fromSeed(
        seedColor: primary,
        primary: primary,
        secondary: accent,
        brightness: isDark ? Brightness.dark : Brightness.light,
        surface: cardColor,
      ),
      scaffoldBackgroundColor: scaffoldBg,
      cardColor: cardColor,
      appBarTheme: AppBarTheme(
        backgroundColor: cardColor,
        foregroundColor: isDark ? textPrimaryDark : textPrimaryLight,
        elevation: 0,
        centerTitle: true,
        scrolledUnderElevation: 0,
        titleTextStyle: GoogleFonts.cairo(
          fontSize: 17,
          fontWeight: FontWeight.bold,
          color: isDark ? textPrimaryDark : textPrimaryLight,
        ),
      ),
      textTheme: GoogleFonts.cairoTextTheme(base.textTheme).apply(
        bodyColor: isDark ? textPrimaryDark : textPrimaryLight,
        displayColor: isDark ? textPrimaryDark : textPrimaryLight,
      ),
      cardTheme: CardThemeData(
        color: cardColor,
        elevation: 0,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(color: borderColor, width: 1),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: primary,
          foregroundColor: Colors.white,
          elevation: 0,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          textStyle: GoogleFonts.cairo(fontWeight: FontWeight.bold, fontSize: 14),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: primary,
          side: BorderSide(color: primary, width: 1.2),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          textStyle: GoogleFonts.cairo(fontWeight: FontWeight.bold, fontSize: 14),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: inputBg,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: borderColor),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: primary, width: 1.5),
        ),
        labelStyle: GoogleFonts.cairo(
          fontSize: 13,
          color: isDark ? textSecondaryDark : textSecondaryLight,
        ),
        hintStyle: GoogleFonts.cairo(
          fontSize: 13,
          color: isDark ? textMutedDark : textMutedLight,
        ),
      ),
      bottomNavigationBarTheme: BottomNavigationBarThemeData(
        backgroundColor: cardColor,
        selectedItemColor: primary,
        unselectedItemColor: isDark ? textMutedDark : textMutedLight,
        selectedLabelStyle: GoogleFonts.cairo(fontWeight: FontWeight.bold, fontSize: 11),
        unselectedLabelStyle: GoogleFonts.cairo(fontSize: 11),
        elevation: 8,
        type: BottomNavigationBarType.fixed,
      ),
    );
  }
}
