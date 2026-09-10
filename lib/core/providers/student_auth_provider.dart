import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../constants/app_constants.dart';
import '../network/student_api_service.dart';
import '../theme/branding_provider.dart';

class StudentAuthState {
  final bool isAuthenticated;
  final bool isLoading;
  final String? errorMessage;
  final Map<String, dynamic>? student;
  final Map<String, dynamic>? tenant;

  const StudentAuthState({
    this.isAuthenticated = false,
    this.isLoading = false,
    this.errorMessage,
    this.student,
    this.tenant,
  });

  StudentAuthState copyWith({
    bool? isAuthenticated,
    bool? isLoading,
    String? errorMessage,
    Map<String, dynamic>? student,
    Map<String, dynamic>? tenant,
  }) {
    return StudentAuthState(
      isAuthenticated: isAuthenticated ?? this.isAuthenticated,
      isLoading: isLoading ?? this.isLoading,
      errorMessage: errorMessage,
      student: student ?? this.student,
      tenant: tenant ?? this.tenant,
    );
  }

  String get studentName => student?['name']?.toString() ?? 'الطالب';
  String get studentCode => student?['studentCode']?.toString() ?? '';
  String get studentId => student?['id']?.toString() ?? '';
  String get academicYearName => student?['academicYear']?['name']?.toString() ?? 'المرحلة الدراسية';
  String get academicYear => academicYearName;
  List<dynamic> get enrolledGroups => (student?['groups'] is List) ? (student!['groups'] as List) : [];
}

class StudentAuthNotifier extends StateNotifier<StudentAuthState> {
  final Ref _ref;

  StudentAuthNotifier(this._ref) : super(const StudentAuthState(isLoading: true)) {
    _initSession();
  }

  Future<void> _initSession() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString(AppConstants.keyAuthToken);
      final rawStudent = prefs.getString(AppConstants.keyStudentData);
      final rawTenant = prefs.getString(AppConstants.keyTenantData);

      if (token != null && token.isNotEmpty && rawStudent != null) {
        final student = jsonDecode(rawStudent) as Map<String, dynamic>;
        final tenant = rawTenant != null ? (jsonDecode(rawTenant) as Map<String, dynamic>) : null;

        if (tenant != null) {
          _ref.read(studentBrandingProvider.notifier).updateFromTenant(tenant);
        }

        state = state.copyWith(
          isAuthenticated: true,
          isLoading: false,
          student: student,
          tenant: tenant,
        );

        // Fetch fresh profile in background
        refreshProfile();
      } else {
        state = state.copyWith(isAuthenticated: false, isLoading: false);
      }
    } catch (e) {
      debugPrint('Error restoring student session: $e');
      state = state.copyWith(isAuthenticated: false, isLoading: false);
    }
  }

  Future<bool> login({
    required String studentCode,
    required String phone,
    String? subdomain,
    bool rememberMe = true,
  }) async {
    state = state.copyWith(isLoading: true, errorMessage: null);

    try {
      final res = await StudentApiService().loginStudent(
        studentCode: studentCode,
        phone: phone,
        subdomain: subdomain,
      );

      final token = res['accessToken']?.toString();
      final student = res['student'] as Map<String, dynamic>?;
      final tenant = student?['tenant'] as Map<String, dynamic>?;

      if (token == null || student == null) {
        throw Exception('بيانات الدخول غير مكتملة');
      }

      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(AppConstants.keyAuthToken, token);
      await prefs.setString(AppConstants.keyStudentData, jsonEncode(student));
      if (tenant != null) {
        await prefs.setString(AppConstants.keyTenantData, jsonEncode(tenant));
        _ref.read(studentBrandingProvider.notifier).updateFromTenant(tenant);
      }

      // Remember Me credentials
      await prefs.setBool(AppConstants.keyRememberMe, rememberMe);
      if (rememberMe) {
        await prefs.setString(AppConstants.keySavedCode, studentCode);
        await prefs.setString(AppConstants.keySavedPhone, phone);
        if (subdomain != null && subdomain.isNotEmpty) {
          await prefs.setString(AppConstants.keySavedCenterSlug, subdomain);
        }
      } else {
        await prefs.remove(AppConstants.keySavedCode);
        await prefs.remove(AppConstants.keySavedPhone);
        await prefs.remove(AppConstants.keySavedCenterSlug);
      }

      state = state.copyWith(
        isAuthenticated: true,
        isLoading: false,
        student: student,
        tenant: tenant,
      );

      return true;
    } catch (e) {
      String msg = 'فشل تسجيل الدخول، يرجى التحقق من الكود ورقم الهاتف';
      if (e.toString().contains('401') || e.toString().contains('غير مسجل')) {
        msg = 'كود الطالب أو رقم الهاتف غير مسجل في هذا السنتر';
      }
      state = state.copyWith(isLoading: false, errorMessage: msg);
      return false;
    }
  }

  Future<void> refreshProfile() async {
    final sId = state.studentId;
    if (sId.isEmpty) return;

    try {
      final fresh = await StudentApiService().getStudentProfile(sId);
      if (fresh != null) {
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString(AppConstants.keyStudentData, jsonEncode(fresh));
        state = state.copyWith(student: fresh);
      }
    } catch (e) {
      debugPrint('Error refreshing student profile: $e');
    }
  }

  Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(AppConstants.keyAuthToken);
    await prefs.remove(AppConstants.keyStudentData);
    await prefs.remove(AppConstants.keyTenantData);

    state = const StudentAuthState(isAuthenticated: false, isLoading: false);
  }
}

final studentAuthProvider =
    StateNotifierProvider<StudentAuthNotifier, StudentAuthState>((ref) {
  return StudentAuthNotifier(ref);
});
