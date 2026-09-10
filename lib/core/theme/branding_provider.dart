import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../constants/app_constants.dart';

class StudentBrandingModel {
  final String centerName;
  final String? logoUrl;
  final String? bannerUrl;
  final Color primaryColor;
  final Color secondaryColor;
  final bool isDarkMode;
  final String? subdomain;
  final String? phone;
  final String? supportPhone;

  const StudentBrandingModel({
    this.centerName = 'السنتر التعليمي',
    this.logoUrl,
    this.bannerUrl,
    this.primaryColor = const Color(0xFF0143A3), // Classic EduZorar Royal Blue
    this.secondaryColor = const Color(0xFF0D9488), // Teal accent
    this.isDarkMode = false,
    this.subdomain,
    this.phone,
    this.supportPhone,
  });

  Color get accentColor => secondaryColor;

  StudentBrandingModel copyWith({
    String? centerName,
    String? logoUrl,
    String? bannerUrl,
    Color? primaryColor,
    Color? secondaryColor,
    bool? isDarkMode,
    String? subdomain,
    String? phone,
    String? supportPhone,
  }) {
    return StudentBrandingModel(
      centerName: centerName ?? this.centerName,
      logoUrl: logoUrl ?? this.logoUrl,
      bannerUrl: bannerUrl ?? this.bannerUrl,
      primaryColor: primaryColor ?? this.primaryColor,
      secondaryColor: secondaryColor ?? this.secondaryColor,
      isDarkMode: isDarkMode ?? this.isDarkMode,
      subdomain: subdomain ?? this.subdomain,
      phone: phone ?? this.phone,
      supportPhone: supportPhone ?? this.supportPhone,
    );
  }
}

typedef BrandingState = StudentBrandingModel;

class StudentBrandingNotifier extends StateNotifier<StudentBrandingModel> {
  StudentBrandingNotifier() : super(const StudentBrandingModel()) {
    _loadFromCache();
  }

  Future<void> _loadFromCache() async {
    final prefs = await SharedPreferences.getInstance();
    final rawTenant = prefs.getString(AppConstants.keyTenantData);
    final isDark = prefs.getBool('student_dark_mode') ?? false;

    if (rawTenant != null) {
      try {
        final tenant = jsonDecode(rawTenant) as Map<String, dynamic>;
        updateFromTenant(tenant, isDark: isDark);
        return;
      } catch (_) {}
    }

    state = state.copyWith(isDarkMode: isDark);
  }

  void updateFromTenant(Map<String, dynamic> tenant, {bool? isDark}) {
    final branding = (tenant['brandingConfig'] is Map)
        ? (tenant['brandingConfig'] as Map<String, dynamic>)
        : {};

    final centerName = tenant['name']?.toString() ?? state.centerName;
    final logoUrl = branding['logoUrl']?.toString();
    final bannerUrl = branding['heroBannerUrl']?.toString();
    final subdomain = tenant['subdomain']?.toString();
    final phone = tenant['phone']?.toString();
    final supportPhone = branding['supportPhone']?.toString() ??
        branding['phone']?.toString() ??
        phone;

    Color primary = state.primaryColor;
    if (branding['primaryColor'] != null) {
      primary = _parseColor(branding['primaryColor'].toString(), primary);
    }

    Color secondary = state.secondaryColor;
    if (branding['secondaryColor'] != null) {
      secondary = _parseColor(branding['secondaryColor'].toString(), secondary);
    }

    state = state.copyWith(
      centerName: centerName,
      logoUrl: logoUrl,
      bannerUrl: bannerUrl,
      primaryColor: primary,
      secondaryColor: secondary,
      isDarkMode: isDark ?? state.isDarkMode,
      subdomain: subdomain,
      phone: phone,
      supportPhone: supportPhone,
    );
  }

  void toggleDarkMode() async {
    final newMode = !state.isDarkMode;
    state = state.copyWith(isDarkMode: newMode);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('student_dark_mode', newMode);
  }

  Color _parseColor(String hex, Color fallback) {
    try {
      String clean = hex.replaceAll('#', '').trim();
      if (clean.length == 6) clean = 'FF$clean';
      return Color(int.parse(clean, radix: 16));
    } catch (_) {
      return fallback;
    }
  }
}

final studentBrandingProvider =
    StateNotifierProvider<StudentBrandingNotifier, StudentBrandingModel>((ref) {
  return StudentBrandingNotifier();
});

final brandingProvider = studentBrandingProvider;
