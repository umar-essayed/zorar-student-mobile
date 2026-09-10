class AppConstants {
  static const String appName = 'EduZorar Student';
  static const String appArabicName = 'زُرار كود - بوابة الطالب';

  // Production Backend URL (Same as Vercel backend)
  static const String defaultApiBaseUrl = 'https://zoraredu-backend.vercel.app/api/v1';

  // SharedPreferences Keys
  static const String keyAuthToken = 'student_jwt_token';
  static const String keyStudentData = 'student_cached_profile';
  static const String keyTenantData = 'student_cached_tenant';
  static const String keyApiUrl = 'student_api_base_url';
  static const String keyRememberMe = 'student_remember_me';
  static const String keySavedPhone = 'student_saved_phone';
  static const String keySavedCode = 'student_saved_code';
  static const String keySavedCenterSlug = 'student_saved_center_slug';
}
