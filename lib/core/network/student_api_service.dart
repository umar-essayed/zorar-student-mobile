import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'api_client.dart';

class StudentApiService {
  static final StudentApiService _instance = StudentApiService._internal();
  factory StudentApiService() => _instance;
  StudentApiService._internal();

  Dio get _dio => ApiClient().dio;

  // ==========================================
  // 1. Authentication
  // ==========================================
  Future<Map<String, dynamic>> loginStudent({
    required String studentCode,
    required String phone,
    String? subdomain,
  }) async {
    try {
      final res = await _dio.post('/auth/student-login', data: {
        'studentCode': studentCode.trim(),
        'phone': phone.trim(),
        if (subdomain != null && subdomain.trim().isNotEmpty) 'subdomain': subdomain.trim(),
      });
      return Map<String, dynamic>.from(res.data);
    } catch (e) {
      debugPrint('Error loginStudent: $e');
      rethrow;
    }
  }

  // ==========================================
  // 2. Student Profile & ID Card
  // ==========================================
  Future<Map<String, dynamic>?> getStudentProfile(String studentId) async {
    try {
      final res = await _dio.get('/students/$studentId/profile');
      if (res.data is Map) {
        return Map<String, dynamic>.from(res.data);
      }
      return null;
    } catch (e) {
      debugPrint('Error getStudentProfile: $e');
      return null;
    }
  }

  Future<Map<String, dynamic>?> getStudentById(String studentId) async {
    try {
      final res = await _dio.get('/students/$studentId');
      if (res.data is Map) {
        return Map<String, dynamic>.from(res.data);
      }
      return null;
    } catch (e) {
      debugPrint('Error getStudentById: $e');
      return null;
    }
  }

  Future<Map<String, dynamic>?> getStudentCard(String studentId) async {
    try {
      final res = await _dio.get('/students/$studentId/card-qr');
      if (res.data is Map) {
        return Map<String, dynamic>.from(res.data);
      }
      return null;
    } catch (e) {
      debugPrint('Error getStudentCard: $e');
      return null;
    }
  }

  // ==========================================
  // 3. Online Exams & Submissions
  // ==========================================
  Future<List<Map<String, dynamic>>> getAvailableExams({String? groupId}) async {
    try {
      final queryParams = <String, dynamic>{};
      if (groupId != null && groupId.isNotEmpty) queryParams['groupId'] = groupId;

      final res = await _dio.get('/exams', queryParameters: queryParams);
      if (res.data is List) {
        return List<Map<String, dynamic>>.from(res.data);
      }
      return [];
    } catch (e) {
      debugPrint('Error getAvailableExams: $e');
      return [];
    }
  }

  Future<Map<String, dynamic>?> getExamForTaking(String examId) async {
    try {
      final res = await _dio.get('/exams/$examId/take');
      if (res.data is Map) {
        return Map<String, dynamic>.from(res.data);
      }
      return null;
    } catch (e) {
      debugPrint('Error getExamForTaking: $e');
      rethrow;
    }
  }

  Future<Map<String, dynamic>> submitExam(String examId, Map<String, String> answers) async {
    try {
      final res = await _dio.post('/exams/$examId/submit', data: {
        'answers': answers,
      });
      return Map<String, dynamic>.from(res.data);
    } catch (e) {
      debugPrint('Error submitExam: $e');
      rethrow;
    }
  }

  // ==========================================
  // 4. Online Courses & Lessons
  // ==========================================
  Future<List<Map<String, dynamic>>> getCourses() async {
    try {
      final res = await _dio.get('/courses');
      if (res.data is List) {
        return List<Map<String, dynamic>>.from(res.data);
      }
      return [];
    } catch (e) {
      debugPrint('Error getCourses: $e');
      return [];
    }
  }

  Future<Map<String, dynamic>?> getCourseDetails(String courseId) async {
    try {
      final res = await _dio.get('/courses/$courseId');
      if (res.data is Map) {
        return Map<String, dynamic>.from(res.data);
      }
      return null;
    } catch (e) {
      debugPrint('Error getCourseDetails: $e');
      return null;
    }
  }

  Future<Map<String, dynamic>?> getLessonPlayerToken(String lessonId) async {
    try {
      final res = await _dio.get('/courses/lessons/$lessonId/player-token');
      if (res.data is Map) {
        return Map<String, dynamic>.from(res.data);
      }
      return null;
    } catch (e) {
      debugPrint('Error getLessonPlayerToken: $e');
      return null;
    }
  }

  Future<bool> logWatchProgress({
    required String lessonId,
    required int watchedSeconds,
    bool isCompleted = false,
  }) async {
    try {
      await _dio.post('/courses/lessons/$lessonId/progress', data: {
        'watchedSeconds': watchedSeconds,
        'isCompleted': isCompleted,
      });
      return true;
    } catch (e) {
      debugPrint('Error logWatchProgress: $e');
      return false;
    }
  }

  // ==========================================
  // 5. Center Announcements & Broadcasts
  // ==========================================
  Future<List<Map<String, dynamic>>> getAnnouncements() async {
    try {
      final res = await _dio.get('/announcements');
      if (res.data is List) {
        return List<Map<String, dynamic>>.from(res.data);
      }
      return [];
    } catch (e) {
      debugPrint('Error getAnnouncements: $e');
      return [];
    }
  }
}

